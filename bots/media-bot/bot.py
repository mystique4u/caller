#!/usr/bin/env python3
"""
media-bot — Matrix bot that downloads short-form media from links and re-posts them.

Supported platforms (URL allowlist):
  • YouTube Shorts         youtube.com/shorts/
  • Instagram Reels/Posts  instagram.com/reel/ or /p/
  • TikTok                 tiktok.com/ or vm.tiktok.com/
  • Telegram posts         t.me/<channel>/<id>
  • Twitter / X            twitter.com/.../status/ or x.com/.../status/

For each matching URL in a room message the bot will:
  1. Download the media via yt-dlp (max MAX_FILE_SIZE_MB, default 250 MB)
  2. Upload it to the Matrix media store
  3. Post a formatted message with caption + original link
  4. Redact / delete the original message

On failure the bot sends a ⚠️ notification and leaves the original message intact.
Seen URLs are persisted to /data/seen_urls.json so duplicates are skipped across restarts.

Required environment variables:
  BOT_USERNAME        Matrix username (e.g. media-bot)
  BOT_PASSWORD        Matrix password
  MATRIX_DOMAIN       Homeserver domain (e.g. example.com)

Optional environment variables:
  MATRIX_INTERNAL_URL   default: http://matrix-synapse:8008
  MATRIX_ROOM_ID        Restrict processing to one room ID
  MAX_FILE_SIZE_MB      Maximum download size in MB; default: 250
  TELEGRAM_API_ID       Telegram app api_id (for t.me link downloads)
  TELEGRAM_API_HASH     Telegram app api_hash (for t.me link downloads)
  PORT                  Health endpoint port; default: 3003
"""

import hashlib
import html
import json
import logging
import mimetypes
import os
import re
import shutil
import sys
import tempfile
import threading
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

import requests
import yt_dlp

# ── Configuration ──────────────────────────────────────────────────────────────

MATRIX_INTERNAL_URL = os.environ.get("MATRIX_INTERNAL_URL", "http://matrix-synapse:8008").rstrip("/")
BOT_USERNAME        = os.environ.get("BOT_USERNAME", "media-bot")
BOT_PASSWORD        = os.environ.get("BOT_PASSWORD", "")
MATRIX_DOMAIN       = os.environ.get("MATRIX_DOMAIN", "")
MATRIX_ROOM_ID      = os.environ.get("MATRIX_ROOM_ID", "")
MAX_FILE_SIZE_MB    = int(os.environ.get("MAX_FILE_SIZE_MB", "250"))
TELEGRAM_API_ID     = os.environ.get("TELEGRAM_API_ID", "")
TELEGRAM_API_HASH   = os.environ.get("TELEGRAM_API_HASH", "")
YOUTUBE_COOKIES_FILE = os.environ.get("YOUTUBE_COOKIES_FILE", "/data/youtube-cookies.txt")
PORT                = int(os.environ.get("PORT", "3003"))

if not BOT_PASSWORD:
    print("[config] BOT_PASSWORD is required", file=sys.stderr)
    sys.exit(1)
if not MATRIX_DOMAIN:
    print("[config] MATRIX_DOMAIN is required", file=sys.stderr)
    sys.exit(1)

# ── Paths ─────────────────────────────────────────────────────────────────────

_DATA_DIR    = Path("/data")
_TOKEN_FILE  = _DATA_DIR / "token.txt"
_BATCH_FILE  = _DATA_DIR / "next_batch.txt"
_SEEN_FILE   = _DATA_DIR / "seen_urls.json"
_MEDIA_DIR   = _DATA_DIR / "media"

# ── Logging ───────────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
)
log = logging.getLogger("media-bot")

# ── URL allowlist patterns ─────────────────────────────────────────────────────

_URL_PATTERNS = [
    re.compile(r'https?://(?:www\.)?youtube\.com/shorts/[\w-]+', re.I),
    re.compile(r'https?://(?:www\.)?instagram\.com/(?:reel|p)/[\w-]+/?', re.I),
    re.compile(r'https?://(?:www\.)?tiktok\.com/@?[\w.%-]+/video/\d+', re.I),
    re.compile(r'https?://(?:vm|vt)\.tiktok\.com/[\w-]+', re.I),
    re.compile(r'https?://t\.me/\w+/\d+', re.I),
    re.compile(r'https?://(?:www\.)?(?:twitter|x)\.com/\w+/status/\d+', re.I),
]

# MIME type map for common download extensions
_MIME = {
    ".mp4": "video/mp4", ".webm": "video/webm", ".mkv": "video/x-matroska",
    ".avi": "video/x-msvideo", ".mov": "video/quicktime",
    ".jpg": "image/jpeg", ".jpeg": "image/jpeg", ".png": "image/png",
    ".gif": "image/gif", ".webp": "image/webp",
    ".mp3": "audio/mpeg", ".m4a": "audio/mp4", ".ogg": "audio/ogg",
}

# ── State ─────────────────────────────────────────────────────────────────────

_access_token: str | None = None
_txn_counter = 0
_seen_urls: dict = {}   # url → ISO timestamp string
_seen_lock = threading.Lock()

# ── Matrix HTTP helpers ───────────────────────────────────────────────────────

def _api(method: str, path: str, body=None, token: str | None = None,
         raw_body=None, content_type: str | None = None) -> tuple[int, dict]:
    url = MATRIX_INTERNAL_URL + path
    headers: dict = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    try:
        if body is not None:
            resp = requests.request(method, url, headers=headers, json=body, timeout=30)
        elif raw_body is not None:
            headers["Content-Type"] = content_type or "application/octet-stream"
            resp = requests.request(method, url, headers=headers, data=raw_body, timeout=300)
        else:
            resp = requests.request(method, url, headers=headers, timeout=60)
        return resp.status_code, resp.json()
    except Exception as exc:
        raise RuntimeError(f"Matrix API error [{method} {path}]: {exc}") from exc


def _next_txn() -> str:
    global _txn_counter
    _txn_counter += 1
    return f"media-bot-{int(time.time())}-{_txn_counter}"


# ── Auth ──────────────────────────────────────────────────────────────────────

def _login():
    global _access_token
    _DATA_DIR.mkdir(parents=True, exist_ok=True)

    # Attempt to reuse a persisted token to avoid rate-limits on restart
    if _TOKEN_FILE.exists():
        saved = _TOKEN_FILE.read_text().strip()
        if saved:
            status, _ = _api("GET", "/_matrix/client/v3/account/whoami", token=saved)
            if status == 200:
                _access_token = saved
                log.info("Reusing persisted token for @%s:%s", BOT_USERNAME, MATRIX_DOMAIN)
                return
        _TOKEN_FILE.unlink(missing_ok=True)
        log.info("Persisted token invalid — re-authenticating")

    for attempt in range(1, 6):
        status, body = _api("POST", "/_matrix/client/v3/login", {
            "type":       "m.login.password",
            "identifier": {"type": "m.id.user", "user": BOT_USERNAME},
            "password":   BOT_PASSWORD,
        })
        if status == 200:
            _access_token = body["access_token"]
            _TOKEN_FILE.write_text(_access_token)
            log.info("Logged in as @%s:%s", BOT_USERNAME, MATRIX_DOMAIN)
            return
        if status == 429:
            wait = body.get("retry_after_ms", 60000) / 1000
            log.warning("Rate-limited on login — retrying in %.0fs", wait)
            time.sleep(wait)
            continue
        raise RuntimeError(f"Login failed ({status}): {body}")
    raise RuntimeError("Login failed after 5 attempts")


# ── Seen-URL persistence ───────────────────────────────────────────────────────

def _load_seen():
    global _seen_urls
    if _SEEN_FILE.exists():
        try:
            _seen_urls = json.loads(_SEEN_FILE.read_text())
        except Exception:
            _seen_urls = {}


def _mark_seen(url: str):
    with _seen_lock:
        _seen_urls[url] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
        try:
            _SEEN_FILE.write_text(json.dumps(_seen_urls, indent=2))
        except Exception as exc:
            log.warning("Could not persist seen_urls: %s", exc)


def _is_seen(url: str) -> bool:
    with _seen_lock:
        return url in _seen_urls


# ── Matrix messaging ──────────────────────────────────────────────────────────

def _send_message(room_id: str, content: dict) -> str | None:
    """Send a message to a room. Returns the event_id or None on failure."""
    txn = _next_txn()
    path = f"/_matrix/client/v3/rooms/{urllib.parse.quote(room_id)}/send/m.room.message/{txn}"
    status, body = _api("PUT", path, body=content, token=_access_token)
    if status == 200:
        return body.get("event_id")
    log.error("Failed to send message (%s): %s", status, body)
    return None


def _redact_message(room_id: str, event_id: str, reason: str = "") -> bool:
    txn = _next_txn()
    path = (f"/_matrix/client/v3/rooms/{urllib.parse.quote(room_id)}"
            f"/redact/{urllib.parse.quote(event_id)}/{txn}")
    status, body = _api("PUT", path, body={"reason": reason}, token=_access_token)
    if status == 200:
        return True
    log.warning("Failed to redact %s (%s): %s", event_id, status, body)
    return False


def _upload_file(filepath: str, filename: str, mimetype: str) -> str:
    """Upload a local file to the Matrix media store. Returns mxc:// URI."""
    url = (MATRIX_INTERNAL_URL
           + f"/_matrix/media/v3/upload?filename={urllib.parse.quote(filename)}")
    headers = {
        "Authorization": f"Bearer {_access_token}",
        "Content-Type": mimetype,
    }
    file_size = os.path.getsize(filepath)
    headers["Content-Length"] = str(file_size)
    with open(filepath, "rb") as fh:
        resp = requests.post(url, headers=headers, data=fh, timeout=600)
    if resp.status_code != 200:
        raise RuntimeError(f"Upload failed ({resp.status_code}): {resp.text[:200]}")
    return resp.json()["content_uri"]


def _notify_failure(room_id: str, url: str, reason: str):
    short_reason = reason[:300] if len(reason) > 300 else reason
    plain = f"⚠️ Could not download this link:\n{url}\n\nReason: {short_reason}"
    html_body = (f"⚠️ Could not download this link:<br>"
                 f"<a href='{html.escape(url)}'>{html.escape(url)}</a><br><br>"
                 f"Reason: {html.escape(short_reason)}")
    _send_message(room_id, {
        "msgtype": "m.text",
        "body": plain,
        "format": "org.matrix.custom.html",
        "formatted_body": html_body,
    })


# ── yt-dlp download ───────────────────────────────────────────────────────────

def _is_telegram_url(url: str) -> bool:
    return bool(re.match(r'https?://t\.me/', url, re.I))


def _download(url: str) -> tuple[str, dict]:
    """
    Download URL via yt-dlp.
    Returns (local_filepath, info_dict).
    Raises yt_dlp.utils.DownloadError or FileNotFoundError on failure.
    """
    _MEDIA_DIR.mkdir(parents=True, exist_ok=True)
    url_hash = hashlib.sha256(url.encode()).hexdigest()[:16]
    outtmpl = str(_MEDIA_DIR / f"{url_hash}.%(ext)s")

    ydl_opts: dict = {
        "outtmpl": outtmpl,
        "format": "bestvideo+bestaudio/best",
        "merge_output_format": "mp4",
        "max_filesize": MAX_FILE_SIZE_MB * 1024 * 1024,
        "quiet": True,
        "no_warnings": False,
        "noplaylist": True,
        "socket_timeout": 60,
        "js_runtimes": "node:/usr/bin/node",  # yt-dlp 2026+ requires a JS runtime for YouTube
        "remote_components": "ejs:github",    # solve YouTube n-challenge (throttling bypass)
    }

    # YouTube cookies — required to bypass bot-detection on Shorts/Reels.
    # We pass a TEMP COPY to yt-dlp so it cannot overwrite the original file
    # (yt-dlp rewrites the cookiefile on every run, stripping auth cookies).
    cookies_path = Path(YOUTUBE_COOKIES_FILE)
    _tmp_cookies = None
    if cookies_path.exists():
        _tmp_cookies = tempfile.NamedTemporaryFile(suffix=".txt", delete=False)
        shutil.copy2(str(cookies_path), _tmp_cookies.name)
        _tmp_cookies.close()
        ydl_opts["cookiefile"] = _tmp_cookies.name
        log.debug("Using cookies (temp copy) from %s", cookies_path)

    # Telegram credentials for t.me link downloads
    if _is_telegram_url(url):
        if not TELEGRAM_API_ID or not TELEGRAM_API_HASH:
            raise RuntimeError(
                "TELEGRAM_API_ID and TELEGRAM_API_HASH are required for t.me links"
            )
        ydl_opts["extractor_args"] = {
            "Telegram": {
                "api_id": [TELEGRAM_API_ID],
                "api_hash": [TELEGRAM_API_HASH],
            }
        }

    # Run yt-dlp from /data/ so Telethon session files are stored there
    original_cwd = os.getcwd()
    try:
        os.chdir(str(_DATA_DIR))
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(url, download=True)
    finally:
        os.chdir(original_cwd)
        if _tmp_cookies:
            try:
                os.unlink(_tmp_cookies.name)
            except Exception:
                pass

    if info is None:
        raise RuntimeError("yt-dlp returned no info")

    # Resolve the actual downloaded file path
    filepath = None
    for dl in info.get("requested_downloads", []):
        fp = dl.get("filepath", "")
        if fp and Path(fp).exists():
            filepath = fp
            break

    if not filepath:
        # Fallback: find newest file matching the hash prefix
        candidates = sorted(_MEDIA_DIR.glob(f"{url_hash}.*"),
                             key=lambda p: p.stat().st_mtime, reverse=True)
        if candidates:
            filepath = str(candidates[0])

    if not filepath or not Path(filepath).exists():
        raise FileNotFoundError(f"yt-dlp did not produce a file for: {url}")

    return filepath, info


# ── Core handler ──────────────────────────────────────────────────────────────

def _process_url(url: str, room_id: str, event_id: str):
    """Download URL and re-post as media in the room. Redacts original on success."""
    if _is_seen(url):
        log.info("Skipping already-seen URL: %s", url)
        return

    log.info("Processing URL: %s", url)
    filepath = None

    try:
        filepath, info = _download(url)

        ext = Path(filepath).suffix.lower()
        mimetype = _MIME.get(ext) or mimetypes.guess_type(filepath)[0] or "application/octet-stream"
        filename = Path(filepath).name
        file_size = os.path.getsize(filepath)

        log.info("Uploading %s (%d MB)…", filename, file_size // (1024 * 1024))
        mxc_uri = _upload_file(filepath, filename, mimetype)

        # Build caption
        title = (info.get("title") or info.get("description") or "").strip()
        caption_plain = (title[:900] + "\n\n" if title else "") + f"🔗 {url}"
        caption_html = (
            (html.escape(title[:900]) + "<br><br>" if title else "")
            + f"🔗 <a href='{html.escape(url)}'>{html.escape(url)}</a>"
        )

        # Determine message type
        media_info: dict = {"mimetype": mimetype, "size": file_size}
        if "width" in info:
            media_info["w"] = info["width"]
        if "height" in info:
            media_info["h"] = info["height"]

        if mimetype.startswith("video/"):
            msgtype = "m.video"
        elif mimetype.startswith("image/"):
            msgtype = "m.image"
        elif mimetype.startswith("audio/"):
            msgtype = "m.audio"
        else:
            msgtype = "m.file"

        content = {
            "msgtype": msgtype,
            "body": caption_plain,
            "format": "org.matrix.custom.html",
            "formatted_body": caption_html,
            "url": mxc_uri,
            "info": media_info,
        }

        sent_id = _send_message(room_id, content)
        if sent_id:
            _redact_message(room_id, event_id, reason="media reposted by media-bot")
            _mark_seen(url)
            log.info("✅ Posted %s and redacted original", url)
        else:
            _notify_failure(room_id, url, "Failed to post media message to room")

    except yt_dlp.utils.DownloadError as exc:
        reason = str(exc)
        log.warning("Download failed for %s: %s", url, reason)
        _notify_failure(room_id, url, reason)

    except Exception as exc:
        log.exception("Unexpected error processing %s", url)
        _notify_failure(room_id, url, str(exc))

    finally:
        # Always clean up the local file — media is now in Matrix store
        if filepath and Path(filepath).exists():
            try:
                os.unlink(filepath)
            except Exception:
                pass


# ── Matrix sync loop ──────────────────────────────────────────────────────────

def _extract_urls(text: str) -> list[str]:
    """Return a list of matching short-form media URLs found in text."""
    found = []
    for pattern in _URL_PATTERNS:
        match = pattern.search(text)
        if match:
            found.append(match.group(0).rstrip(",.;)\"'"))
    return found


def _process_sync_result(result: dict):
    bot_user_id = f"@{BOT_USERNAME}:{MATRIX_DOMAIN}"

    # Auto-accept room invitations
    invited_rooms = result.get("rooms", {}).get("invite", {})
    for room_id in invited_rooms:
        log.info("Received invite to %s — joining", room_id)
        status, body = _api(
            "POST",
            f"/_matrix/client/v3/join/{urllib.parse.quote(room_id)}",
            body={},
            token=_access_token,
        )
        if status == 200:
            log.info("Joined room %s", room_id)
        else:
            log.warning("Failed to join %s: %s %s", room_id, status, body)

    joined_rooms = result.get("rooms", {}).get("join", {})

    for room_id, room_data in joined_rooms.items():
        # Optionally restrict to a single configured room
        if MATRIX_ROOM_ID and room_id != MATRIX_ROOM_ID:
            continue

        events = room_data.get("timeline", {}).get("events", [])
        for event in events:
            if event.get("type") != "m.room.message":
                continue
            if event.get("sender") == bot_user_id:
                continue  # Don't react to own messages

            content  = event.get("content", {})
            msgtype  = content.get("msgtype", "")
            event_id = event.get("event_id", "")

            if msgtype not in ("m.text", "m.notice"):
                continue

            body = content.get("body", "") or ""
            urls = _extract_urls(body)

            for url in urls:
                _process_url(url, room_id, event_id)
                break  # Process at most one URL per message


def _sync_loop():
    since = _BATCH_FILE.read_text().strip() if _BATCH_FILE.exists() else ""

    # On first start (or reset), fetch current state including pending invites
    if not since:
        log.info("No sync token found — performing initial sync to establish position")
        status, body = _api(
            "GET",
            "/_matrix/client/v3/sync?timeout=0&filter="
            + urllib.parse.quote(json.dumps({"room": {"timeline": {"limit": 0}}})),
            token=_access_token,
        )
        if status != 200:
            raise RuntimeError(f"Initial sync failed ({status}): {body}")
        # Process initial sync result to handle any pending invites
        _process_sync_result(body)
        since = body.get("next_batch", "")
        _BATCH_FILE.write_text(since)
        log.info("Initial sync done. Starting live sync from %s", since[:20])

    log.info("Entering sync loop…")
    while True:
        try:
            params = urllib.parse.urlencode({"timeout": "30000", "since": since})
            status, body = _api(
                "GET",
                f"/_matrix/client/v3/sync?{params}",
                token=_access_token,
            )
            if status == 200:
                since = body.get("next_batch", since)
                _BATCH_FILE.write_text(since)
                _process_sync_result(body)
            elif status == 401:
                log.warning("Token expired — re-authenticating")
                _login()
            else:
                log.warning("Sync returned %s — retrying in 10s", status)
                time.sleep(10)
        except KeyboardInterrupt:
            raise
        except Exception as exc:
            log.error("Sync error: %s — retrying in 10s", exc)
            time.sleep(10)


# ── Health endpoint ───────────────────────────────────────────────────────────

class _HealthHandler(BaseHTTPRequestHandler):
    def do_GET(self):  # noqa: N802
        if self.path == "/health":
            body = json.dumps({"ok": True, "bot": BOT_USERNAME}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)
        else:
            self.send_response(404)
            self.end_headers()

    def log_message(self, *_):
        pass  # Suppress access log noise


def _start_health_server():
    server = HTTPServer(("0.0.0.0", PORT), _HealthHandler)
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    log.info("Health endpoint listening on port %d", PORT)


# ── Entrypoint ────────────────────────────────────────────────────────────────

def main():
    _DATA_DIR.mkdir(parents=True, exist_ok=True)
    _MEDIA_DIR.mkdir(parents=True, exist_ok=True)
    _load_seen()
    _start_health_server()

    log.info("Starting media-bot (@%s:%s)", BOT_USERNAME, MATRIX_DOMAIN)
    if TELEGRAM_API_ID:
        log.info("Telegram t.me downloads enabled (api_id=%s…)", TELEGRAM_API_ID[:4])
    else:
        log.info("Telegram t.me downloads disabled (no TELEGRAM_API_ID set)")

    # Retry login on startup (Synapse may not be ready yet)
    for attempt in range(1, 21):
        try:
            _login()
            break
        except Exception as exc:
            log.warning("Login attempt %d/20 failed: %s — retrying in 15s", attempt, exc)
            if attempt == 20:
                log.error("Could not log in after 20 attempts — exiting")
                sys.exit(1)
            time.sleep(15)

    _sync_loop()


if __name__ == "__main__":
    main()
