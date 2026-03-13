# Element Call / Matrix RTC Setup Guide

## What Was Fixed

Your Element Call setup had several issues that were causing the "FOCUS" alert. The following changes fix the RTC calling functionality:

### 1. Updated Well-Known Configuration to Stable Spec
- **Old**: `org.matrix.msc4143.rtc_foci` (experimental MSC)
- **New**: `m.rtc_foci` (stable specification)
- **Impact**: Clients now properly discover the LiveKit service

### 2. Added Element Call Configuration
Added to Element Web config.json:
```json
"element_call": {
  "url": "https://call.element.io",
  "use_exclusively": false,
  "participant_limit": 8,
  "brand": "Element Call"
}
```

### 3. Enabled Group Call Features
- `feature_element_call_video_rooms`: true
- `feature_group_calls`: true

### 4. Enabled Synapse Experimental Features
Added to homeserver.yaml:
```yaml
experimental_features:
  msc3026_enabled: true  # Busy presence
  msc3266_enabled: true  # Room summary API
  msc3401_enabled: true  # Account data in events
  msc3886_enabled: true  # Simple rendezvous for group calls
```

## Architecture

```
┌─────────────────┐
│  Element Client │
└────────┬────────┘
         │
         ├─── Matrix Client-Server API ──→ Matrix Synapse (port 8008)
         │                                       │
         └─── LiveKit JWT Request ──────────────┼──→ Matrix RTC Service
                                                 │    (rtc.domain.com/livekit/jwt)
                                                 │
                                                 └──→ LiveKit SFU
                                                      (livekit.domain.com)
                                                      - WebRTC (UDP 7882)
                                                      - HTTP (TCP 7880)
                                                      - TCP (TCP 7881)
```

## Deployment Steps

After making these changes, redeploy your services:

```bash
# From your local machine, run the Ansible playbook
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml

# Or SSH to the server and manually restart
ssh root@YOUR_SERVER_IP
cd /opt/services
docker-compose down
docker-compose up -d

# Verify services are running
docker ps | grep -E "livekit|matrix-rtc|matrix-synapse|element"
```

## Testing Element Call

### 1. Verify Well-Known Configuration

```bash
# Test the well-known client configuration
curl https://yourdomain.com/.well-known/matrix/client | jq

# Should show:
# {
#   "m.homeserver": {
#     "base_url": "https://matrix.yourdomain.com"
#   },
#   "m.rtc_foci": [
#     {
#       "type": "livekit",
#       "livekit_service_url": "https://rtc.yourdomain.com/livekit/jwt"
#     }
#   ]
# }
```

### 2. Verify LiveKit is Running

```bash
# Check LiveKit status
docker ps | grep livekit

# Check LiveKit logs
docker logs livekit -f

# Test LiveKit API (from external machine or browser)
curl https://livekit.yourdomain.com
# Should return: "404 page not found" (normal - means it's running)
```

### 3. Verify Matrix RTC Service

```bash
# Check matrix-rtc service
docker ps | grep matrix-rtc

# Check logs
docker logs matrix-rtc -f

# Test the JWT endpoint (should return 401 without proper auth)
curl https://rtc.yourdomain.com/livekit/jwt
# Expected: 401 Unauthorized (normal - requires Matrix authentication)
```

### 4. Test in Element Client

1. **Open Element Web**: `https://chat.yourdomain.com`

2. **Login** with your Matrix account

3. **Create or join a room** (private or public)

4. **Start a call**:
   - Click the video call icon in the top right of the room
   - OR: Click the "+" menu and select "Start a call"

5. **Verify call starts**:
   - Should see video preview
   - Should NOT see "FOCUS" alert
   - Camera/microphone permissions should be requested

6. **Test with another user**:
   - Join the call from another device/browser
   - Verify both participants can see/hear each other

### 5. Expected Behavior

**Working Setup:**
- ✅ Video call button is visible in rooms
- ✅ Call starts without errors
- ✅ Camera/microphone work
- ✅ Can see other participants
- ✅ Audio/video quality is good

**Previous Issues (FOCUS alert):**
- ❌ "FOCUS" error when starting call
- ❌ Call doesn't connect
- ❌ Error: "Unable to start conference"

## Troubleshooting

### Issue: Still seeing "FOCUS" alert

**Possible Causes:**
1. Element client cache not cleared
2. Well-known configuration not updated
3. Matrix RTC service not running
4. LiveKit not accessible

**Solutions:**
```bash
# 1. Clear Element client cache
- In Element: Settings → Help & About → Clear Cache and Reload

# 2. Verify well-known is updated
curl https://yourdomain.com/.well-known/matrix/client | grep rtc_foci

# 3. Check Matrix RTC service
docker logs matrix-rtc --tail 100

# 4. Check LiveKit
docker logs livekit --tail 100

# 5. Verify environment variables
docker inspect matrix-rtc | grep -A 20 Env
# Should show LIVEKIT_URL, LIVEKIT_KEY, LIVEKIT_SECRET
```

### Issue: Call connects but no audio/video

**Possible Causes:**
1. Firewall blocking UDP port 7882
2. TURN server not configured
3. Browser permissions denied

**Solutions:**
```bash
# 1. Verify firewall ports are open (already configured in Terraform)
# Ports needed: 7880, 7881, 7882/udp

# 2. Check TURN server (coturn)
docker logs coturn --tail 50

# 3. Test UDP connectivity
# From external machine:
nc -u -v YOUR_SERVER_IP 7882

# 4. Check browser console for WebRTC errors
# In browser: F12 → Console tab
```

### Issue: "Unable to get JWT token"

**Cause:** Matrix RTC service cannot authenticate with LiveKit

**Solution:**
```bash
# Verify LIVEKIT_KEY and LIVEKIT_SECRET are set correctly
docker inspect matrix-rtc | grep -E "LIVEKIT_KEY|LIVEKIT_SECRET"

# Check matrix-rtc logs for auth errors
docker logs matrix-rtc 2>&1 | grep -i error

# Restart matrix-rtc service
docker restart matrix-rtc
```

### Issue: Calls work but quality is poor

**Possible Causes:**
1. Insufficient bandwidth
2. CPU/memory limits
3. Network congestion
4. Too many participants

**Solutions:**
```bash
# 1. Check server resources
docker stats

# 2. Check LiveKit metrics
docker logs livekit | grep -E "cpu|memory|bandwidth"

# 3. Reduce participant limit in Element config
# Edit participant_limit in element/config.json to lower value (e.g., 4)

# 4. Monitor network usage
iftop  # or
vnstat
```

### Issue: Can't start calls in encrypted rooms

**Cause:** Element Call requires additional setup for encrypted rooms

**Note:** Element Call in encrypted rooms is experimental. Consider:
- Using regular 1:1 calls for encrypted rooms
- Using unencrypted rooms for group calls
- Staying updated with Matrix/Element releases for encryption improvements

## Checking Logs

### View all RTC-related logs:

```bash
# Matrix Synapse
docker logs matrix-synapse 2>&1 | grep -i "call\|rtc\|livekit"

# LiveKit
docker logs livekit --tail 100 -f

# Matrix RTC service
docker logs matrix-rtc --tail 100 -f

# TURN server
docker logs coturn --tail 50

# Element (browser console)
# Open Element in browser → F12 → Console tab
# Filter by: "call" or "rtc" or "livekit"
```

## Environment Variables Reference

### LiveKit Service
Required environment variables (set in playbook):
```bash
LIVEKIT_API_KEY=<your-key>
LIVEKIT_API_SECRET=<your-secret>
```

### Matrix RTC Service
Required environment variables (automatically configured):
```bash
LIVEKIT_URL=wss://livekit.yourdomain.com
LIVEKIT_KEY=<matches-livekit-api-key>
LIVEKIT_SECRET=<matches-livekit-api-secret>
LIVEKIT_FULL_ACCESS_HOMESERVERS=yourdomain.com
```

## Required Ports

Ensure these ports are open in your firewall:

| Port | Protocol | Service | Purpose |
|------|----------|---------|---------|
| 443  | TCP      | HTTPS   | Client connections |
| 7880 | TCP      | LiveKit | HTTP/WebSocket |
| 7881 | TCP      | LiveKit | TCP transport |
| 7882 | UDP      | LiveKit | WebRTC media |
| 3478 | TCP/UDP  | TURN    | NAT traversal |
| 49152-49200 | UDP | TURN | Media relay |

All these ports are already configured in your Terraform firewall rules.

## Advanced Configuration

### Increase Participant Limit

Edit Element config to allow more participants:

```json
"element_call": {
  "participant_limit": 16  // Increase from 8 to 16
}
```

**Note:** More participants = more bandwidth/CPU required

### Use Exclusively Element Call

To disable Jitsi and use only Element Call:

```json
"element_call": {
  "use_exclusively": true
}
```

### Configure LiveKit Regions

For better performance with global users, configure LiveKit with multiple regions (advanced - requires multiple servers).

## Testing Checklist

- [ ] Well-known file shows `m.rtc_foci` configuration
- [ ] LiveKit container is running
- [ ] Matrix-rtc container is running
- [ ] Matrix Synapse shows experimental features enabled
- [ ] Element config shows element_call configuration
- [ ] Can start a call without FOCUS error
- [ ] Camera/microphone work
- [ ] Can invite another user to call
- [ ] Both users can see/hear each other
- [ ] Call quality is acceptable

## Common Error Messages

| Error | Cause | Solution |
|-------|-------|----------|
| "FOCUS" alert | RTC service not discoverable | Update well-known, clear cache |
| "Unable to start conference" | LiveKit not running | Check LiveKit container |
| "No JWT token" | Matrix RTC auth issue | Check environment variables |
| "Connection failed" | Firewall/network issue | Check ports 7880-7882 |
| "ICE connection failed" | TURN not working | Check coturn container |

## Additional Resources

- [Element Call Documentation](https://github.com/vector-im/element-call)
- [LiveKit Documentation](https://docs.livekit.io/)
- [Matrix RTC Widget](https://github.com/matrix-org/matrix-widget-api)
- [Element Call MSC](https://github.com/matrix-org/matrix-spec-proposals/pull/3401)

## Next Steps

After calls are working:

1. **Test with multiple participants** to verify group calls work
2. **Monitor resource usage** during calls (CPU, bandwidth, memory)
3. **Set participant limits** based on server capacity
4. **Configure quality settings** in LiveKit if needed
5. **Consider scaling** LiveKit if you need to support many concurrent calls
