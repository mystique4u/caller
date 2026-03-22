# Jitsi Matrix Bot — Setup & Usage Guide

A Python bot that listens for Jitsi conference events (room created, participant joined/left, room destroyed) and posts notifications to a Matrix room with the conference URL, participant name, and real client IP.

---

## Architecture Overview

```
Browser ──► Traefik ──► jitsi-web (nginx) ──► jitsi-prosody (XMPP)
                                                      │
                                          mod_matrix_webhook (Lua)
                                                      │
                                              jitsi-bot (Python)
                                                      │
                                          matrix-synapse (Matrix)
                                                      │
                                            Matrix room / Element
```

**Components:**
- `jitsi-bot/bot.py` — Python stdlib HTTP server, authenticates to Matrix, posts messages
- `jitsi-bot/prosody-plugin/mod_matrix_webhook.lua` — Prosody Lua module, hooks into XMPP MUC events and calls the bot
- Traefik → nginx `X-Forwarded-For` chain — passes real client IPs through to Prosody

---

## Initial Setup

### 1. GitHub Secrets Required

Add these secrets in **Settings → Secrets and variables → Actions**:

| Secret | Description | Example |
|---|---|---|
| `MATRIX_BOT_USER` | Matrix username (no `@` or domain) | `jitsi-bot` |
| `MATRIX_BOT_PASSWORD` | Matrix password for the bot | `someStrongPassword` |
| `MATRIX_WEBHOOK_SECRET` | Shared HMAC secret between Prosody and bot | `random32charstring` |
| `MATRIX_BOT_ROOM` | Full Matrix room ID to post into | `!AbCdEf:yourdomain.com` |
| `DOMAIN_NAME` | Your base domain | `yourdomain.com` |

Generate random secrets:
```bash
openssl rand -base64 32
```

### 2. Matrix Room Setup

1. **Create or pick a room** in Element where bot notifications should appear.
2. **Get the room ID**: open room → ⋮ menu → *Settings* → *Advanced* → copy the Internal Room ID (`!xxxxx:yourdomain.com`).
3. **Set `MATRIX_BOT_ROOM`** to this ID.
4. The bot user is registered automatically by the pipeline on first deploy.
5. **Invite the bot** to the room from your Matrix client: type `/invite @jitsi-bot:yourdomain.com`.

### 3. Deploy

Push to `feature/jitsi-matrix-bot` or `main` with changes under `jitsi-bot/**`:

```bash
git push origin feature/jitsi-matrix-bot
```

The `Deploy Jitsi Matrix Bot` GitHub Actions workflow will:
1. Look up the server IP via Terraform
2. Sync `jitsi-bot/` to `/opt/services/jitsi-bot/` on the server
3. Copy the Lua plugin to Prosody's custom plugin directory
4. Write the docker-compose override for the bot container
5. Register the Matrix bot user (idempotent — safe to re-run)
6. Build and start the `jitsi-bot` container
7. Ensure Prosody has `XMPP_MUC_MODULES=matrix_webhook` set (idempotent)
8. Patch jitsi-web nginx to forward real client IPs (idempotent)
9. Recreate Prosody to apply plugin and env changes
10. Health-check the bot

---

## Manual Setup (without CI/CD)

### On the server

```bash
# 1. Copy bot files
mkdir -p /opt/services/jitsi-bot
rsync -avz jitsi-bot/ root@YOUR_SERVER:/opt/services/jitsi-bot/

# 2. Copy the Lua plugin
cp jitsi-bot/prosody-plugin/mod_matrix_webhook.lua \
   /opt/services/jitsi/prosody/prosody-plugins-custom/

# 3. Register the Matrix bot user
docker exec matrix-synapse register_new_matrix_user \
  -u jitsi-bot -p 'YOUR_PASSWORD' \
  --no-admin -c /data/homeserver.yaml http://localhost:8008

# 4. Create docker-compose override at /opt/services/docker-compose.jitsi-bot.yml:
```

```yaml
services:
  jitsi-bot:
    build:
      context: /opt/services/jitsi-bot
      dockerfile: Dockerfile
    image: jitsi-bot:latest
    container_name: jitsi-bot
    restart: unless-stopped
    environment:
      - BOT_USERNAME=jitsi-bot
      - BOT_PASSWORD=YOUR_MATRIX_PASSWORD
      - MATRIX_DOMAIN=yourdomain.com
      - MATRIX_INTERNAL_URL=http://matrix-synapse:8008
      - JITSI_PUBLIC_URL=https://meet.yourdomain.com
      - WEBHOOK_SECRET=YOUR_WEBHOOK_SECRET
      - MATRIX_ROOM=!yourRoomId:yourdomain.com
    networks:
      - services_network

networks:
  services_network:
    external: true
```

```bash
# 5. Add webhook env vars to Prosody in /opt/services/docker-compose.yml
#    (under the jitsi-prosody service environment section):
#    - XMPP_MUC_MODULES=matrix_webhook
#    - MATRIX_WEBHOOK_URL=http://jitsi-bot:3001/webhook
#    - MATRIX_WEBHOOK_SECRET=YOUR_WEBHOOK_SECRET

# 6. Patch jitsi-web nginx to forward real client IPs
docker exec jitsi-web sed -i \
  's/proxy_set_header X-Forwarded-For \$remote_addr/proxy_set_header X-Forwarded-For \$http_x_forwarded_for/g' \
  /config/nginx/meet.conf
docker exec jitsi-web nginx -s reload

# 7. Build and start the bot
cd /opt/services
docker build -t jitsi-bot:latest /opt/services/jitsi-bot/
docker compose -f docker-compose.jitsi-bot.yml up -d jitsi-bot

# 8. Recreate Prosody to load the module
docker compose up -d --force-recreate jitsi-prosody
```

---

## Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `BOT_USERNAME` | yes | — | Matrix username (local part only, no `@`) |
| `BOT_PASSWORD` | yes | — | Matrix password |
| `MATRIX_DOMAIN` | yes | — | Matrix homeserver domain (e.g. `yourdomain.com`) |
| `MATRIX_INTERNAL_URL` | yes | — | Internal URL to reach Synapse (e.g. `http://matrix-synapse:8008`) |
| `JITSI_PUBLIC_URL` | yes | — | Public Jitsi base URL (e.g. `https://meet.yourdomain.com`) |
| `WEBHOOK_SECRET` | yes | — | HMAC-SHA256 secret shared with Prosody plugin |
| `MATRIX_ROOM` | yes | — | Full Matrix room ID to post messages into |
| `PORT` | no | `3001` | Port the bot listens on |

---

## Message Format

**Room created:**
```
🎥 Jitsi room created: testroom
👉 https://meet.yourdomain.com/testroom
```

**Participant joined:**
```
✅ alice joined testroom (IP: 85.10.123.45)
```

**Participant left:**
```
❌ alice left testroom
```

**Room destroyed:**
```
🔴 Jitsi room destroyed: testroom
```

---

## Verifying the Setup

### Check bot is running and connected
```bash
docker exec jitsi-prosody curl -s http://jitsi-bot:3001/health
# Expected: {"ok": true, "room": "!yourRoomId:yourdomain.com"}
```

### Send a test webhook manually
```bash
# From inside the Prosody container:
docker exec jitsi-prosody lua -e "
local json = require 'util.json'
local http = require 'net.http'
local payload = json.encode({event='room_created', room='testroom'})
local secret = 'YOUR_WEBHOOK_SECRET'
-- compute HMAC ... (see plugin source for signature format)
"
```

Or use `curl` with the correct HMAC-SHA256 signature:
```bash
PAYLOAD='{"event":"room_created","room":"testroom","url":"https://meet.yourdomain.com/testroom"}'
SECRET="YOUR_WEBHOOK_SECRET"
SIG=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" | awk '{print $2}')
curl -X POST http://localhost:3001/webhook \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Signature: $SIG" \
  -d "$PAYLOAD"
```

### Check bot logs
```bash
docker logs jitsi-bot -f
```

### Check Prosody logs for webhook events
```bash
docker logs jitsi-prosody 2>&1 | grep -i "matrix\|webhook"
```

---

## Traefik Configuration

For real client IPs to flow through to Prosody, Traefik must be configured to trust `X-Forwarded-For` headers from Docker networks. In `ansible/templates/traefik.toml.j2`:

```toml
[entryPoints.websecure]
  address = ":443"
  [entryPoints.websecure.forwardedHeaders]
    trustedIPs = ["127.0.0.1/32", "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
```

The `address` line **must** appear before the `[entryPoints.websecure.forwardedHeaders]` table — TOML requires all key-value fields of a table to be declared before any subtables.

---

## Troubleshooting

### Bot shows Docker-internal IPs (172.x.x.x)
The nginx `X-Forwarded-For` patch may not have been applied (e.g. after a jitsi-web container restart). Re-apply:
```bash
docker exec jitsi-web sed -i \
  's/proxy_set_header X-Forwarded-For \$remote_addr/proxy_set_header X-Forwarded-For \$http_x_forwarded_for/g' \
  /config/nginx/meet.conf
docker exec jitsi-web nginx -s reload
```
The deploy pipeline re-applies this idempotently on every run.

### Participants show as hex IDs (e.g. `fe0b4f6e`)
Jitsi auth is likely not enabled or the user joined as a guest. The bot uses `bare_jid` (authenticated username) when available. Enable `AUTH_TYPE=internal` in the Jitsi docker-compose config and ensure users are authenticated before joining.

### No messages posted after a room event
1. Check the bot is running: `docker ps | grep jitsi-bot`
2. Check bot logs: `docker logs jitsi-bot --tail 50`
3. Verify Prosody has the module: `docker exec jitsi-prosody grep XMPP_MUC_MODULES /proc/1/environ | tr '\0' '\n'`
4. Verify webhook env on Prosody: `docker exec jitsi-prosody env | grep MATRIX_WEBHOOK`
5. Test the webhook manually (see above)

### Traefik crash-loops with `field not found, node: address`
The TOML structure is malformed. Check `/opt/services/traefik/traefik.toml` — the `address = ":443"` field must be inside `[entryPoints.websecure]`, **not** inside `[entryPoints.websecure.forwardedHeaders]`. Write the correct config and restart Traefik.

### Bot gets rate-limited by Synapse (HTTP 429)
The bot handles this automatically — it reads `retry_after_ms` from the response and waits exactly that long before retrying. If the rate limit doesn't clear, restart `matrix-synapse` to reset in-memory limits:
```bash
docker restart matrix-synapse
```

### Bot created a new Matrix room instead of joining the existing one
The `MATRIX_ROOM` environment variable is likely not set or incorrect. The bot only creates a room if `MATRIX_ROOM` is empty. Verify the env var on the running container:
```bash
docker inspect jitsi-bot | grep MATRIX_ROOM
```
Also ensure the bot user has been invited to the target room in Element.
