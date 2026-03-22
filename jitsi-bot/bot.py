#!/usr/bin/env python3
"""
Jitsi Matrix Bot — pure stdlib, zero pip dependencies.

Receives HTTP webhooks from the Prosody mod_matrix_webhook.lua plugin
and posts room/join/leave events into a Matrix room.
"""

import hashlib
import http.client
import json
import os
import sys
import time
import urllib.parse
from http.server import BaseHTTPRequestHandler, HTTPServer

# ── Config ──────────────────────────────────────────────────────────────────
MATRIX_INTERNAL_URL = os.environ.get("MATRIX_INTERNAL_URL", "http://matrix-synapse:8008").rstrip("/")
BOT_USERNAME        = os.environ.get("BOT_USERNAME", "jitsi-bot")
BOT_PASSWORD        = os.environ.get("BOT_PASSWORD", "")
MATRIX_DOMAIN       = os.environ.get("MATRIX_DOMAIN", "")
MATRIX_ROOM         = os.environ.get("MATRIX_ROOM", "").strip()
JITSI_PUBLIC_URL    = os.environ.get("JITSI_PUBLIC_URL", "https://meet.example.com").rstrip("/")
WEBHOOK_SECRET      = os.environ.get("WEBHOOK_SECRET", "")
PORT                = int(os.environ.get("PORT", "3001"))

if not BOT_PASSWORD:
    print("[config] BOT_PASSWORD is required", file=sys.stderr)
    sys.exit(1)
if not MATRIX_DOMAIN:
    print("[config] MATRIX_DOMAIN is required", file=sys.stderr)
    sys.exit(1)

INTERNAL_NICKS = {"focus", "jvb", "jibri"}

# ── State ────────────────────────────────────────────────────────────────────
_access_token    = None
_resolved_room   = None
_active_rooms    = {}       # room_name -> set of participant nicks
_txn_counter     = 0

# ── Low-level Matrix helper (plain HTTP, no TLS needed inside Docker network) ─
def _matrix_request(method, path, body=None, token=None):
    parsed = urllib.parse.urlparse(MATRIX_INTERNAL_URL + path)
    host   = parsed.hostname
    port   = parsed.port or 8008
    conn   = http.client.HTTPConnection(host, port, timeout=10)
    data   = json.dumps(body).encode() if body is not None else None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if data:
        headers["Content-Length"] = str(len(data))
    conn.request(method, parsed.path + (f"?{parsed.query}" if parsed.query else ""), data, headers)
    resp      = conn.getresponse()
    resp_body = json.loads(resp.read().decode())
    conn.close()
    return resp.status, resp_body


def _login():
    global _access_token
    status, body = _matrix_request("POST", "/_matrix/client/v3/login", {
        "type":       "m.login.password",
        "identifier": {"type": "m.id.user", "user": BOT_USERNAME},
        "password":   BOT_PASSWORD,
    })
    if status != 200:
        raise RuntimeError(f"Login failed ({status}): {body}")
    _access_token = body["access_token"]
    print(f"[matrix] Logged in as @{BOT_USERNAME}:{MATRIX_DOMAIN}")


def _ensure_room():
    global _resolved_room
    alias = f"#jitsi-notifications:{MATRIX_DOMAIN}"

    if MATRIX_ROOM:
        target = MATRIX_ROOM
    else:
        # Try to create; fall back to joining if it already exists
        status, body = _matrix_request("POST", "/_matrix/client/v3/createRoom", {
            "room_alias_name": "jitsi-notifications",
            "name":            "Jitsi Notifications",
            "topic":           "Automatic Jitsi meeting events",
            "preset":          "public_chat",
        }, _access_token)
        if status == 200:
            _resolved_room = body["room_id"]
            print(f"[matrix] Created room {_resolved_room}  alias: {alias}")
            print(f"[matrix] TIP: set MATRIX_ROOM={_resolved_room} to pin this room.")
            return
        # Room already exists — resolve alias
        status, body = _matrix_request(
            "GET",
            f"/_matrix/client/v3/directory/room/{urllib.parse.quote(alias)}",
            token=_access_token,
        )
        if status != 200:
            raise RuntimeError(f"Cannot create or find {alias}: {body}")
        target = body["room_id"]

    # Join (idempotent)
    status, body = _matrix_request(
        "POST",
        f"/_matrix/client/v3/join/{urllib.parse.quote(target)}",
        {},
        _access_token,
    )
    _resolved_room = body.get("room_id", target)
    print(f"[matrix] Using room {_resolved_room}")


def _send(plain, html):
    global _txn_counter
    if not _resolved_room or not _access_token:
        print("[matrix] Not ready — dropping message")
        return
    _txn_counter += 1
    txn = f"bot{int(time.time())}{_txn_counter}"
    path = (f"/_matrix/client/v3/rooms/{urllib.parse.quote(_resolved_room)}"
            f"/send/m.room.message/{txn}")
    status, body = _matrix_request("PUT", path, {
        "msgtype":        "m.text",
        "body":           plain,
        "format":         "org.matrix.custom.html",
        "formatted_body": html,
    }, _access_token)
    if status != 200:
        print(f"[matrix] Send failed: {body}")


# ── Formatting ────────────────────────────────────────────────────────────────
def _room_url(room):
    return f"{JITSI_PUBLIC_URL}/{urllib.parse.quote(room, safe='')}"


def _is_internal(nick):
    n = (nick or "").lower()
    return n in INTERNAL_NICKS or n.startswith("focus") or n.startswith("jvb")


def _handle_event(event, room, participant=None, ip=None):
    url = _room_url(room)

    if event == "room_created":
        _active_rooms.setdefault(room, set())
        _send(
            f"🎥 Jitsi room started: {url}",
            f'🎥 Jitsi room started: <a href="{url}">{url}</a>',
        )

    elif event == "participant_joined":
        if _is_internal(participant):
            return
        if room not in _active_rooms:
            _active_rooms[room] = set()
            _send(f"🎥 Jitsi room started: {url}",
                  f'🎥 Jitsi room started: <a href="{url}">{url}</a>')
        _active_rooms[room].add(participant)
        ip_part_plain = f" · IP: {ip}" if ip else ""
        ip_part_html  = f" · IP: <code>{ip}</code>" if ip else ""
        _send(
            f"➜ {participant} joined {room} ({url}){ip_part_plain}",
            f'➜ <strong>{participant}</strong> joined <a href="{url}">{room}</a>{ip_part_html}',
        )

    elif event == "participant_left":
        if _is_internal(participant):
            return
        _active_rooms.get(room, set()).discard(participant)
        _send(
            f"← {participant} left {room}",
            f'← <strong>{participant}</strong> left <a href="{url}">{room}</a>',
        )

    elif event == "room_destroyed":
        _active_rooms.pop(room, None)
        _send(
            f"🔴 Jitsi room ended: {room}",
            f"🔴 Jitsi room ended: <strong>{room}</strong>",
        )


# ── HTTP webhook handler ───────────────────────────────────────────────────────
class WebhookHandler(BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        pass   # silence default access log

    def do_GET(self):
        if self.path == "/health":
            self._respond(200, {"ok": True, "room": _resolved_room})
        else:
            self._respond(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/webhook":
            self._respond(404, {"error": "not found"})
            return

        # Secret check
        if WEBHOOK_SECRET and self.headers.get("X-Webhook-Secret") != WEBHOOK_SECRET:
            self._respond(401, {"error": "unauthorized"})
            return

        length = int(self.headers.get("Content-Length", 0))
        try:
            payload = json.loads(self.rfile.read(length))
        except Exception:
            self._respond(400, {"error": "invalid json"})
            return

        event = payload.get("event")
        room  = payload.get("room")
        if not event or not room:
            self._respond(400, {"error": "missing event or room"})
            return

        self._respond(200, {"ok": True})

        try:
            _handle_event(
                event,
                room,
                participant=payload.get("participant"),
                ip=payload.get("ip"),
            )
        except Exception as exc:
            print(f"[webhook] Error handling {event}: {exc}")

    def _respond(self, code, body):
        data = json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)


# ── Startup ───────────────────────────────────────────────────────────────────
def start():
    for attempt in range(1, 13):
        try:
            _login()
            _ensure_room()
            break
        except Exception as exc:
            remaining = 12 - attempt
            print(f"[startup] {exc}. Retry in 15s ({remaining} left)")
            if remaining == 0:
                print("[startup] Max retries reached. Exiting.")
                sys.exit(1)
            time.sleep(15)

    server = HTTPServer(("0.0.0.0", PORT), WebhookHandler)
    print(f"[server] jitsi-matrix-bot listening on port {PORT}")
    server.serve_forever()


if __name__ == "__main__":
    start()
