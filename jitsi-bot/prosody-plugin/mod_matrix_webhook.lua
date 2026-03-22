-- mod_matrix_webhook.lua
-- Fires HTTP webhooks on Jitsi MUC room events so jitsi-matrix-bot can post
-- notifications to a Matrix room.
--
-- Enable via the jitsi-prosody env var:
--   XMPP_MUC_MODULES=matrix_webhook
--
-- The module reads two optional env vars from the container environment:
--   MATRIX_WEBHOOK_URL     (default: http://jitsi-bot:3001/webhook)
--   MATRIX_WEBHOOK_SECRET  (default: empty → no auth header sent)

local http   = require "net.http"
local json   = require "util.json"

local webhook_url    = os.getenv("MATRIX_WEBHOOK_URL")    or "http://jitsi-bot:3001/webhook"
local webhook_secret = os.getenv("MATRIX_WEBHOOK_SECRET") or ""

-- Extract the local part (room name) from a JID like "roomname@muc.meet.jitsi"
local function room_name(jid)
  return jid:match("^([^@]+)") or jid
end

local function post_event(payload)
  local body    = json.encode(payload)
  local headers = { ["Content-Type"] = "application/json" }
  if webhook_secret ~= "" then
    headers["X-Webhook-Secret"] = webhook_secret
  end
  http.request(webhook_url, {
    method  = "POST",
    headers = headers,
    body    = body,
  }, function(response_body, code)
    if code ~= 200 then
      module:log("warn", "Matrix webhook returned HTTP %s for event %s",
        tostring(code), tostring(payload.event))
    end
  end)
end

-- Room lifecycle events
module:hook("muc-room-created", function(event)
  post_event({
    event     = "room_created",
    room      = room_name(event.room.jid),
    timestamp = os.time(),
  })
end)

module:hook("muc-room-destroyed", function(event)
  post_event({
    event     = "room_destroyed",
    room      = room_name(event.room.jid),
    timestamp = os.time(),
  })
end)

-- Participant events — include IP when available (may be internal Docker IP
-- if the user connected via BOSH; still useful for server-side correlation)
module:hook("muc-occupant-joined", function(event)
  local origin = event.origin
  post_event({
    event       = "participant_joined",
    room        = room_name(event.room.jid),
    participant = event.occupant.nick or "unknown",
    ip          = origin and origin.ip or nil,
    timestamp   = os.time(),
  })
end)

module:hook("muc-occupant-left", function(event)
  post_event({
    event       = "participant_left",
    room        = room_name(event.room.jid),
    participant = event.occupant.nick or "unknown",
    timestamp   = os.time(),
  })
end)
