-- mod_security_webhook.lua
-- Prosody MUC plugin — forwards room events to the security-bot webhook.
--
-- Install: copy to /prosody-plugins-custom/ and add "security_webhook" to
-- XMPP_MUC_MODULES in jitsi-prosody environment.
--
-- Environment variables (set on the Prosody container):
--   SECURITY_WEBHOOK_URL     e.g. http://security-bot:3002/webhook
--   SECURITY_WEBHOOK_SECRET  shared secret (optional)

local http = require "net.http"
local json = require "util.json"
local os_time = os.time

local WEBHOOK_URL    = os.getenv("SECURITY_WEBHOOK_URL")    or "http://security-bot:3002/webhook"
local WEBHOOK_SECRET = os.getenv("SECURITY_WEBHOOK_SECRET") or ""

local function post_event(payload)
    local body = json.encode(payload)
    local headers = { ["Content-Type"] = "application/json" }
    if WEBHOOK_SECRET ~= "" then
        headers["X-Webhook-Secret"] = WEBHOOK_SECRET
    end
    http.request(WEBHOOK_URL, { method = "POST", body = body, headers = headers }, function(response_body, code)
        if code ~= 200 then
            module:log("warn", "security-webhook: unexpected response %d: %s", code, tostring(response_body))
        end
    end)
end

module:hook("muc-room-created", function(event)
    post_event({ event = "room_created", room = tostring(event.room.jid), timestamp = os_time() })
end)

module:hook("muc-room-destroyed", function(event)
    post_event({ event = "room_destroyed", room = tostring(event.room.jid), timestamp = os_time() })
end)

module:hook("muc-occupant-joined", function(event)
    local ip = event.stanza and event.stanza:get_child_text("x", "http://jabber.org/protocol/muc") or ""
    post_event({
        event       = "participant_joined",
        room        = tostring(event.room.jid),
        participant = tostring(event.occupant.nick),
        ip          = ip,
        timestamp   = os_time(),
    })
end)

module:hook("muc-occupant-left", function(event)
    post_event({
        event       = "participant_left",
        room        = tostring(event.room.jid),
        participant = tostring(event.occupant.nick),
        timestamp   = os_time(),
    })
end)
