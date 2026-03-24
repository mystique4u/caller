"""
security-bot — Real-time security monitoring for the full services stack.

Monitors:
  • SSH        — successful logins only               (/var/log/auth.log)
  • WireGuard  — peer connect / disconnect           (Docker exec → wg show)
               — invalid handshake attempts          (/var/log/syslog)
  • Matrix     — login success & failure             (Synapse access logs)
  • Routemaker — login success & failure             (webhook POST from app)
  • Docker     — container crashes & OOM kills       (Docker events stream)

Every IP address is enriched with GeoIP data (city, region, country, ISP).
GeoIP uses the local GeoLite2-City.mmdb when available, falling back to the
ip-api.com free HTTP API (no key, 45 req/min — sufficient for monitoring).

Required environment variables:
  BOT_USERNAME        Matrix username for this bot (e.g. security-bot)
  BOT_PASSWORD        Matrix password
  MATRIX_DOMAIN       Homeserver domain (e.g. example.com)
  MATRIX_ROOM         Room ID (!abc:domain) or alias to post into

Optional environment variables:
  MATRIX_INTERNAL_URL   default: http://matrix-synapse:8008
  WEBHOOK_SECRET        shared secret for incoming webhook requests
  GEOIP_DB_PATH         path to GeoLite2-City.mmdb; default: /data/GeoLite2-City.mmdb
  DOCKER_SOCKET         default: /var/run/docker.sock
  PORT                  webhook listener port; default: 3002
  POLL_INTERVAL         seconds between WireGuard polls; default: 30
  SSH_LOG_PATH          default: /var/log/auth.log
  SYSLOG_PATH           default: /var/log/syslog
  SYNAPSE_LOG_PATH      default: /synapse-logs/homeserver.log
  ALERT_ON_SUCCESS      send alerts for successful logins too; default: true
  RATE_LIMIT_WINDOW     seconds to suppress repeated alerts per IP; default: 300
  ADMIN_USER            Matrix user ID to auto-invite when room is first created;
                        e.g. @yourusername:example.com
"""

import os
import re
import json
import time
import hmac
import hashlib
import logging
import threading
import urllib.request
import urllib.parse
import urllib.error
from collections import defaultdict
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(threadName)s] %(message)s",
)
log = logging.getLogger("security-bot")

# ── Configuration ──────────────────────────────────────────────────────────────

MATRIX_INTERNAL_URL = os.environ.get("MATRIX_INTERNAL_URL", "http://matrix-synapse:8008")
BOT_USERNAME        = os.environ.get("BOT_USERNAME", "security-bot")
BOT_PASSWORD        = os.environ.get("BOT_PASSWORD", "")
MATRIX_DOMAIN       = os.environ.get("MATRIX_DOMAIN", "")
MATRIX_ROOM         = os.environ.get("MATRIX_ROOM", "")
ADMIN_USER          = os.environ.get("ADMIN_USER", "")
WEBHOOK_SECRET      = os.environ.get("WEBHOOK_SECRET", "")
WGUI_CLIENTS_PATH   = os.environ.get("WGUI_CLIENTS_PATH", "/wgui-clients")
GEOIP_DB_PATH       = os.environ.get("GEOIP_DB_PATH", "/data/GeoLite2-City.mmdb")
DOCKER_SOCKET       = os.environ.get("DOCKER_SOCKET", "/var/run/docker.sock")
PORT                = int(os.environ.get("PORT", 3002))
POLL_INTERVAL       = int(os.environ.get("POLL_INTERVAL", 30))
SSH_LOG_PATH        = os.environ.get("SSH_LOG_PATH", "/var/log/auth.log")
SYSLOG_PATH         = os.environ.get("SYSLOG_PATH", "/var/log/syslog")
SYNAPSE_LOG_PATH    = os.environ.get("SYNAPSE_LOG_PATH", "/synapse-logs/homeserver.log")
ALERT_ON_SUCCESS    = os.environ.get("ALERT_ON_SUCCESS", "true").lower() == "true"
RATE_LIMIT_WINDOW   = int(os.environ.get("RATE_LIMIT_WINDOW", "300"))

# ── GeoIP ──────────────────────────────────────────────────────────────────────

_PRIVATE_PREFIXES = (
    "10.", "192.168.",
    "172.16.", "172.17.", "172.18.", "172.19.", "172.20.", "172.21.",
    "172.22.", "172.23.", "172.24.", "172.25.", "172.26.", "172.27.",
    "172.28.", "172.29.", "172.30.", "172.31.",
    "127.", "::1", "fc00:", "fd",
)

def _is_private(ip: str) -> bool:
    return not ip or any(ip.startswith(p) for p in _PRIVATE_PREFIXES)

_geoip_reader = None

def _init_geoip() -> None:
    global _geoip_reader
    db = Path(GEOIP_DB_PATH)
    if db.exists():
        try:
            import geoip2.database
            _geoip_reader = geoip2.database.Reader(str(db))
            log.info("GeoIP: loaded local GeoLite2 database (%s)", db)
        except Exception as exc:
            log.warning("GeoIP: failed to open local DB (%s) — falling back to ip-api.com", exc)
    else:
        log.info("GeoIP: no local DB at %s — will query ip-api.com (free fallback)", db)

def geoip(ip: str) -> str:
    """Return 'City, Region, Country (ISP)' or 'private network'."""
    if _is_private(ip):
        return "private network"
    if _geoip_reader:
        try:
            r = _geoip_reader.city(ip)
            parts = [r.city.name, r.subdivisions.most_specific.name, r.country.name]
            return ", ".join(p for p in parts if p) or "unknown"
        except Exception:
            pass
    # Fallback: ip-api.com (no API key, 45 req/min limit)
    try:
        url = f"http://ip-api.com/json/{ip}?fields=status,country,regionName,city,isp"
        with urllib.request.urlopen(url, timeout=5) as resp:
            data = json.loads(resp.read())
        if data.get("status") == "success":
            location = ", ".join(p for p in [data.get("city"), data.get("regionName"), data.get("country")] if p)
            isp = data.get("isp", "")
            return f"{location} ({isp})" if isp else location
    except Exception:
        pass
    return "unknown location"

# ── Rate limiter ───────────────────────────────────────────────────────────────
# Prevents alert floods when an attacker sends thousands of attempts.
# Same (event_type, ip) pair is collapsed within RATE_LIMIT_WINDOW seconds;
# every 10th suppressed event sends a summary so the flood is still visible.

_rate_buckets: dict[tuple, tuple[int, int]] = {}  # key → (count, window_start_ts)
_rate_lock = threading.Lock()

def should_alert(event_type: str, ip: str) -> tuple[bool, int]:
    """Return (send_now, suppressed_count)."""
    key = (event_type, ip)
    now = int(time.time())
    with _rate_lock:
        if key not in _rate_buckets:
            _rate_buckets[key] = (1, now)
            return True, 0
        count, first_ts = _rate_buckets[key]
        if now - first_ts > RATE_LIMIT_WINDOW:
            # New window — send immediately with previous suppressed count
            suppressed = count - 1
            _rate_buckets[key] = (1, now)
            return True, suppressed
        _rate_buckets[key] = (count + 1, first_ts)
        # Send on first occurrence, then every 10th to summarise the flood
        if count == 1 or count % 10 == 0:
            return True, count - 1
        return False, 0

# ── Matrix client ──────────────────────────────────────────────────────────────

_ROOM_ID_FILE = Path("/data/room_id.txt")

def _resolve_room(token: str) -> str:
    """Resolve MATRIX_ROOM env var to a room ID, or create a new room.

    Priority:
      1. Env var MATRIX_ROOM if it looks like a real room ID (starts with !)
      2. Persisted /data/room_id.txt
      3. Create a new room via the Matrix API and persist its ID
    """
    # 1. Env var is already a room ID
    env_room = MATRIX_ROOM.strip()
    if env_room.startswith("!"):
        log.info("Matrix: using room from env → %s", env_room)
        return env_room

    # 2. Persisted room ID from a previous run
    if _ROOM_ID_FILE.exists():
        rid = _ROOM_ID_FILE.read_text().strip()
        if rid.startswith("!"):
            log.info("Matrix: using persisted room → %s", rid)
            return rid

    # 3. Env var is a room alias — try directory lookup
    if env_room and env_room not in ("MATRIX_LOGIN_FAILED", ""):
        alias = env_room if env_room.startswith("#") else f"#{env_room}:{MATRIX_DOMAIN}"
        try:
            rid = _matrix_req("GET",
                f"/_matrix/client/v3/directory/room/{urllib.parse.quote(alias)}",
                token=token)["room_id"]
            _ROOM_ID_FILE.write_text(rid)
            log.info("Matrix: resolved alias %s → %s", alias, rid)
            return rid
        except Exception as exc:
            log.warning("Matrix: alias lookup failed (%s) — will create new room", exc)

    # 4. Create a new room
    log.info("Matrix: creating new security-alerts room …")
    resp = _matrix_req("POST", "/_matrix/client/v3/createRoom", {
        "name":   "Security Alerts",
        "topic":  "Real-time server security monitoring",
        "preset": "private_chat",
    }, token=token)
    rid = resp["room_id"]
    _ROOM_ID_FILE.write_text(rid)
    log.info("Matrix: created room %s — join it in Element to receive alerts", rid)
    # Auto-invite the configured admin user
    if ADMIN_USER:
        try:
            _matrix_req("POST", f"/_matrix/client/v3/rooms/{urllib.parse.quote(rid)}/invite",
                        {"user_id": ADMIN_USER}, token=token)
            log.info("Matrix: invited %s to security-alerts room", ADMIN_USER)
        except Exception as exc:
            log.warning("Matrix: could not invite %s: %s", ADMIN_USER, exc)
    return rid


def _init_matrix() -> None:
    global _access_token, _room_id
    if not BOT_PASSWORD:
        log.warning("BOT_PASSWORD not set — Matrix messages will not be sent")
        return
    for attempt in range(3):
        try:
            resp = _matrix_req("POST", "/_matrix/client/v3/login", {
                "type": "m.login.password",
                "user": BOT_USERNAME,
                "password": BOT_PASSWORD,
            })
            _access_token = resp["access_token"]
            log.info("Matrix: authenticated as @%s:%s", BOT_USERNAME, MATRIX_DOMAIN)
            _room_id = _resolve_room(_access_token)
            log.info("Matrix: posting alerts to %s", _room_id)
            return
        except Exception as exc:
            log.error("Matrix init attempt %d/3 failed: %s", attempt + 1, exc)
            time.sleep(5 * (attempt + 1))
    log.warning("Matrix init failed after 3 attempts — bot will run without Matrix notifications")


def _matrix_req(method: str, path: str, body=None, token: str = "") -> dict:
    url = f"{MATRIX_INTERNAL_URL}{path}"
    data = json.dumps(body).encode() if body is not None else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read())


def send(plain: str, html: str = "") -> None:
    if not _access_token or not _room_id:
        log.debug("(no Matrix session) %s", plain[:100])
        return
    body = {
        "msgtype": "m.text",
        "body": plain,
        "format": "org.matrix.custom.html",
        "formatted_body": html or plain,
    }
    try:
        txn_id = int(time.time() * 1000)
        _matrix_req(
            "PUT",
            f"/_matrix/client/v3/rooms/{urllib.parse.quote(_room_id)}/send/m.room.message/{txn_id}",
            body,
            token=_access_token,
        )
        log.info("Matrix: sent → %s", plain[:70].replace("\n", " "))
    except Exception as exc:
        log.error("Failed to send Matrix message: %s", exc)

# ── Event formatter ────────────────────────────────────────────────────────────

def fmt(icon: str, title: str, fields: dict, suppressed: int = 0, tag: str = "") -> tuple[str, str]:
    ts = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    tag_prefix = f"[{tag}] " if tag else ""
    note = f" <i>(+{suppressed} more in window)</i>" if suppressed else ""
    rows = "".join(f"<tr><td><b>{k}</b></td><td>{v}</td></tr>" for k, v in fields.items())
    html = f"<p>{icon} <b>{tag_prefix}{title}</b> — <i>{ts}{note}</i></p><table>{rows}</table>"
    suffix = f"\n  (+{suppressed} more in rate-limit window)" if suppressed else ""
    plain = f"{icon} {tag_prefix}{title} ({ts})\n" + "\n".join(f"  {k}: {v}" for k, v in fields.items()) + suffix
    return plain, html

# ── Log file monitor base ──────────────────────────────────────────────────────

class LogMonitor(threading.Thread):
    """Tails a log file from its current end, dispatching each new line to _handle()."""
    daemon = True

    def __init__(self, path: str, thread_name: str):
        super().__init__(name=thread_name)
        self._path = Path(path)

    def run(self) -> None:
        log.info("%s: watching %s", self.name, self._path)
        while not self._path.exists():
            log.debug("%s: waiting for %s …", self.name, self._path)
            time.sleep(15)
        with self._path.open(errors="replace") as fh:
            fh.seek(0, 2)  # Jump to end — don't replay history on startup
            while True:
                line = fh.readline()
                if not line:
                    time.sleep(0.3)
                    continue
                try:
                    self._handle(line)
                except Exception as exc:
                    log.debug("%s parse error: %s", self.name, exc)

    def _handle(self, line: str) -> None:
        raise NotImplementedError

# ── SSH monitor ────────────────────────────────────────────────────────────────

_RE_SSH_OK      = re.compile(r"sshd\[\d+\]: Accepted (\S+) for (\S+) from ([\d\.a-fA-F:]+) port (\d+)")
_RE_SSH_FAIL    = re.compile(r"sshd\[\d+\]: Failed (\S+) for (?:invalid user )?(\S+) from ([\d\.a-fA-F:]+) port (\d+)")
_RE_SSH_INVALID = re.compile(r"sshd\[\d+\]: Invalid user (\S+) from ([\d\.a-fA-F:]+) port (\d+)")

class SSHMonitor(LogMonitor):
    def __init__(self):
        super().__init__(SSH_LOG_PATH, "ssh-monitor")

    def _handle(self, line: str) -> None:
        m = _RE_SSH_OK.search(line)
        if m:
            method, user, ip, port = m.groups()
            if ALERT_ON_SUCCESS:
                ok, sup = should_alert("ssh_ok", ip)
                if ok:
                    p, h = fmt("🟢", "SSH Login", {
                        "User": user, "Auth method": method,
                        "Source IP": ip, "Port": port, "Location": geoip(ip),
                    }, sup, tag="SSH")
                    send(p, h)
            return

        m = _RE_SSH_FAIL.search(line)
        if m:
            return  # password auth disabled — failed attempts are noise

        m = _RE_SSH_INVALID.search(line)
        if m:
            return  # password auth disabled — invalid user attempts are noise

# ── Syslog / kernel monitor (WireGuard invalid handshakes) ────────────────────

_RE_WG_INVALID_HS = re.compile(r"wireguard.*?wg\d+.*?[Ii]nvalid handshake.*?from ([\d\.a-fA-F:]+):(\d+)")
_RE_WG_OVERLOAD   = re.compile(r"wireguard.*?wg\d+.*?[Oo]verload")

class SyslogMonitor(LogMonitor):
    """Watches syslog for WireGuard kernel-level events (invalid/unknown peers)."""
    def __init__(self):
        super().__init__(SYSLOG_PATH, "syslog-monitor")

    def _handle(self, line: str) -> None:
        m = _RE_WG_INVALID_HS.search(line)
        if m:
            ip, port = m.groups()
            ok, sup = should_alert("wg_invalid_hs", ip)
            if ok:
                p, h = fmt("🔴", "VPN: Unknown Peer Handshake Attempt", {
                    "Source IP": ip, "Port": port, "Location": geoip(ip),
                }, sup, tag="VPN")
                send(p, h)
            return

        if _RE_WG_OVERLOAD.search(line):
            p, h = fmt("⚠️", "WireGuard Interface Overload", {
                "Detail": line.strip()[-120:],
            }, tag="VPN")
            send(p, h)

# ── Synapse access log monitor ─────────────────────────────────────────────────
# Matches the standard Synapse HTTP access log format:
#   IP - entity [timestamp] "METHOD /path HTTP/x.y" STATUS bytes
# and also looser formats from older/custom Synapse configs.

_RE_SYN_LOGIN  = re.compile(
    r'([\d\.a-fA-F:]+)\s+-\s+\S+\s+\[.*?\]\s+"(?:POST|PUT)\s+/_matrix/client/[^"]+/login[^"]*"\s+(\d{3})\s')
_RE_SYN_LOGIN2 = re.compile(
    r'([\d\.a-fA-F:]+).*?(?:POST|PUT)\s+/_matrix/client/[^\s]+/login.*?\s(\d{3})\s')

class SynapseMonitor(LogMonitor):
    def __init__(self):
        super().__init__(SYNAPSE_LOG_PATH, "synapse-monitor")

    def _handle(self, line: str) -> None:
        m = _RE_SYN_LOGIN.search(line) or _RE_SYN_LOGIN2.search(line)
        if not m:
            return
        ip, status = m.group(1), m.group(2)
        if status == "200":
            if ALERT_ON_SUCCESS:
                ok, sup = should_alert("matrix_ok", ip)
                if ok:
                    p, h = fmt("🟢", "Matrix Login", {
                        "Source IP": ip, "Location": geoip(ip),
                    }, sup, tag="MATRIX")
                    send(p, h)
        elif status in ("400", "401", "403"):
            ok, sup = should_alert("matrix_fail", ip)
            if ok:
                p, h = fmt("🔴", "Matrix Login Failed", {
                    "Source IP": ip, "HTTP status": status, "Location": geoip(ip),
                }, sup, tag="MATRIX")
                send(p, h)

# ── WireGuard peer state monitor ──────────────────────────────────────────────

_WGUI_CLIENTS_DIR = Path("/wgui-clients")

def _load_peer_names() -> dict[str, str]:
    """Returns {pubkey: name} from the wireguard-ui client JSON files."""
    names: dict[str, str] = {}
    d = Path(WGUI_CLIENTS_PATH)
    if not d.is_dir():
        return names
    for f in d.glob("*.json"):
        try:
            data = json.loads(f.read_text())
            pub  = data.get("public_key", "")
            name = data.get("name", "")
            if pub and name:
                names[pub] = name
        except Exception:
            pass
    return names


class WireGuardMonitor(threading.Thread):
    """
    Polls `wg show all dump` inside the wireguard-ui container every POLL_INTERVAL
    seconds and sends an alert ONLY when a peer's connection state CHANGES
    (new connection or disconnection — not on every poll).

    Peer names are resolved from the wireguard-ui client JSON files.
    A peer is considered connected when its latest handshake is < 190 seconds old
    (WireGuard re-handshakes every ~120s when the tunnel is active).
    """
    daemon = True
    name = "wireguard-monitor"

    def __init__(self):
        super().__init__()
        # pubkey → {"endpoint": str, "ip": str, "location": str, "ts": int}
        self._connected: dict[str, dict] = {}
        self._first_poll = True  # Don't alert for peers already connected on startup
        # pubkey → last seen handshake timestamp — to detect reconnects
        self._last_handshake: dict[str, int] = {}

    def run(self) -> None:
        if not Path(DOCKER_SOCKET).exists():
            log.warning("WireGuard monitor: Docker socket not found at %s — skipping", DOCKER_SOCKET)
            return
        try:
            import docker as sdk
        except ImportError:
            log.warning("WireGuard monitor: 'docker' package not installed — skipping")
            return
        client = sdk.DockerClient(base_url=f"unix://{DOCKER_SOCKET}")
        log.info("WireGuard monitor: polling every %ds via Docker", POLL_INTERVAL)
        while True:
            try:
                self._poll(client)
            except Exception as exc:
                log.debug("WireGuard poll error: %s", exc)
            time.sleep(POLL_INTERVAL)

    def _peer_label(self, pubkey: str, peer_names: dict[str, str]) -> str:
        name = peer_names.get(pubkey, "")
        short = f"…{pubkey[-8:]}"
        return f"{name} ({short})" if name else short

    def _poll(self, client) -> None:
        container = None
        for name in ("wireguard-ui", "wireguard"):
            try:
                container = client.containers.get(name)
                break
            except Exception:
                pass
        if not container:
            return

        result = container.exec_run("wg show all dump", user="root")
        if result.exit_code != 0:
            return

        peer_names = _load_peer_names()
        now = int(time.time())
        current: dict[str, dict] = {}

        for line in result.output.decode(errors="replace").splitlines():
            parts = line.split("\t")
            # Peer lines have exactly 9 tab-separated fields;
            # the interface header line has 5 — skip it.
            if len(parts) != 9:
                continue
            _iface, pubkey, _psk, endpoint, _allowed, hs_str, _rx, _tx, _ka = parts
            try:
                ts = int(hs_str)
            except ValueError:
                continue
            if ts > 0 and (now - ts) < 190:
                ip = endpoint.rsplit(":", 1)[0].strip("[]")
                current[pubkey] = {"endpoint": endpoint, "ip": ip, "ts": ts}

        if self._first_poll:
            # Silently record who is already connected — no alerts on startup
            for pubkey, info in current.items():
                info["location"] = geoip(info["ip"])
            self._connected = current
            self._last_handshake = {pk: info["ts"] for pk, info in current.items()}
            self._first_poll = False
            log.info("WireGuard monitor: %d peer(s) already connected at startup", len(current))
            return

        ts_str = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")

        # New connections (state change: was not connected → now connected)
        for pubkey, info in current.items():
            if pubkey not in self._connected:
                loc = geoip(info["ip"])
                info["location"] = loc
                label = self._peer_label(pubkey, peer_names)
                p, h = fmt("🟢", "VPN Connected", {
                    "Peer": label,
                    "Time": ts_str,
                    "IP": info["ip"],
                    "Location": loc,
                }, tag="VPN")
                send(p, h)
            # (peers that remain within the 190s window are handled by
            # the disconnect block below once the handshake expires)

        # Disconnections (state change: was connected → no longer connected)
        for pubkey, info in self._connected.items():
            if pubkey not in current:
                label = self._peer_label(pubkey, peer_names)
                p, h = fmt("🔵", "VPN Disconnected", {
                    "Peer": label,
                    "IP": info["ip"],
                    "Location": info.get("location", ""),
                    "Last handshake": datetime.fromtimestamp(
                        info["ts"], tz=timezone.utc
                    ).strftime("%Y-%m-%d %H:%M UTC"),
                }, tag="VPN")
                send(p, h)

        self._connected = current
        self._last_handshake = {pk: info["ts"] for pk, info in current.items()}

_IGNORE_CONTAINERS = {"security-bot"}  # Don't alert on our own container

class DockerMonitor(threading.Thread):
    """Streams Docker events and alerts on container crashes and OOM kills."""
    daemon = True
    name = "docker-monitor"

    def run(self) -> None:
        if not Path(DOCKER_SOCKET).exists():
            log.warning("Docker monitor: socket not found — skipping")
            return
        try:
            import docker as sdk
        except ImportError:
            log.warning("Docker monitor: 'docker' package not installed — skipping")
            return
        client = sdk.DockerClient(base_url=f"unix://{DOCKER_SOCKET}")
        log.info("Docker monitor: streaming container events")
        while True:
            try:
                for event in client.events(decode=True, filters={"type": "container"}):
                    self._handle(event)
            except Exception as exc:
                log.debug("Docker event stream interrupted: %s — reconnecting in 5s", exc)
                time.sleep(5)

    def _handle(self, event: dict) -> None:
        status = event.get("status", "")
        attrs  = event.get("Actor", {}).get("Attributes", {})
        name   = attrs.get("name", event.get("id", "")[:12])
        if name in _IGNORE_CONTAINERS:
            return

        if status == "die":
            exit_code = attrs.get("exitCode", "?")
            if exit_code == "0":
                return  # Clean stop, not interesting
            oom = attrs.get("oomKilled", "false") == "true"
            icon  = "🚨" if oom else "⚠️"
            title = "Container OOM Killed" if oom else "Container Crashed"
            p, h = fmt(icon, title, {"Container": name, "Exit code": exit_code}, tag="DOCKER")
            send(p, h)

        elif status == "health_status: unhealthy":
            p, h = fmt("⚠️", "Container Unhealthy", {"Container": name}, tag="DOCKER")
            send(p, h)

# ── Webhook server (receives events pushed from Routemaker) ───────────────────

class WebhookHandler(BaseHTTPRequestHandler):
    def log_message(self, format, *args):  # noqa: A002
        log.debug(format, *args)

    def _verify(self, body: bytes) -> bool:
        if not WEBHOOK_SECRET:
            return True
        sig = self.headers.get("X-Webhook-Secret", "")
        expected = hmac.new(WEBHOOK_SECRET.encode(), body, hashlib.sha256).hexdigest()
        return hmac.compare_digest(sig, expected)

    def _json(self, code: int, data: dict) -> None:
        body = json.dumps(data).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", len(body))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self) -> None:
        if self.path == "/health":
            self._json(200, {"ok": True, "bot": BOT_USERNAME})
        else:
            self._json(404, {"error": "not found"})

    def do_POST(self) -> None:
        length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(length)

        if not self._verify(body):
            self._json(403, {"error": "forbidden"})
            return

        try:
            payload = json.loads(body)
        except json.JSONDecodeError:
            self._json(400, {"error": "invalid json"})
            return

        if self.path == "/webhook/routemaker":
            self._routemaker(payload)
            self._json(200, {"ok": True})
        else:
            self._json(404, {"error": "unknown endpoint"})

    def _routemaker(self, payload: dict) -> None:
        event    = payload.get("event", "")
        username = payload.get("username", "?")
        # Honour X-Forwarded-For chains — take the real client (first entry)
        raw_ip   = payload.get("ip", "")
        ip       = raw_ip.split(",")[0].strip() if raw_ip else ""

        if event == "login_success" and ALERT_ON_SUCCESS:
            ok, sup = should_alert("routemaker_ok", ip)
            if ok:
                p, h = fmt("🟢", "Routemaker Login", {
                    "User": username, "Source IP": ip, "Location": geoip(ip),
                }, sup, tag="ROUTEMAKER")
                send(p, h)

        elif event == "login_failed":
            ok, sup = should_alert("routemaker_fail", ip)
            if ok:
                p, h = fmt("🔴", "Routemaker Login Failed", {
                    "User": username, "Source IP": ip, "Location": geoip(ip),
                }, sup, tag="ROUTEMAKER")
                send(p, h)

# ── Entry point ────────────────────────────────────────────────────────────────

def main() -> None:
    _init_geoip()
    _init_matrix()

    for t in (SSHMonitor(), SyslogMonitor(), SynapseMonitor(), WireGuardMonitor(), DockerMonitor()):
        t.start()

    log.info("Webhook server listening on :%d", PORT)
    HTTPServer(("0.0.0.0", PORT), WebhookHandler).serve_forever()


if __name__ == "__main__":
    main()
