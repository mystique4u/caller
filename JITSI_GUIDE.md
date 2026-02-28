# Jitsi Meet Setup & Administration Guide

Complete guide for using Jitsi Meet video conferencing and managing your self-hosted instance.

---

## 📋 Table of Contents

1. [Admin Guide: Managing Jitsi Server](#admin-guide-managing-jitsi-server)
2. [Creating & Managing Users](#creating--managing-users)
3. [Using Jitsi Meet: Web Browser](#using-jitsi-meet-web-browser)
4. [Mobile Apps: iOS](#mobile-apps-ios)
5. [Mobile Apps: Android](#mobile-apps-android)
6. [Desktop Apps](#desktop-apps)
7. [Meeting Features](#meeting-features)
8. [Recording Meetings](#recording-meetings)
9. [Integration Guide](#integration-guide)
10. [Troubleshooting](#troubleshooting)

---

## 🔐 Admin Guide: Managing Jitsi Server

### Accessing Your Jitsi Instance

Your Jitsi Meet server is accessible at:
```
URL: https://meet.YOUR_DOMAIN
Example: https://meet.itin.buzz
```

### Server Configuration

**Authentication Mode:** Fully Private (Authentication Required)
- ✅ Authentication required to **create** meetings
- ✅ Authentication required to **join** meetings  
- ❌ No guest access (ENABLE_GUESTS=0)
- 🔒 Maximum security and privacy

**Admin Credentials:**
- Configured via GitHub Secrets:
  - `JITSI_ADMIN_USER` 
  - `JITSI_ADMIN_PASSWORD`
- Format: `username` (not email, not @domain)
- Example: `admin` becomes `admin@auth.meet.jitsi`

### Server Management Commands

```bash
# SSH to server
ssh root@YOUR_SERVER_IP

# Check Jitsi containers
docker ps | grep jitsi

# View Jitsi logs
docker logs jitsi-web --tail 100 -f
docker logs jitsi-prosody --tail 100 -f
docker logs jitsi-jicofo --tail 100 -f
docker logs jitsi-jvb --tail 100 -f

# Restart all Jitsi services
cd /opt/services
docker compose restart jitsi-web jitsi-prosody jitsi-jicofo jitsi-jvb

# Restart specific service
docker restart jitsi-web
docker restart jitsi-prosody

# Check Jitsi-web container
docker exec jitsi-web cat /config/config.js | grep -i auth

# View server metrics
docker stats jitsi-jvb
```

### Architecture Overview

Your Jitsi deployment consists of 4 containers:

1. **jitsi-web** - Web interface (Nginx + React)
2. **jitsi-prosody** - XMPP server (authentication & signaling)
3. **jitsi-jicofo** - Conference focus (manages meetings)
4. **jitsi-jvb** - Video bridge (routes video/audio)

---

## 👥 Creating & Managing Users

### User Account Format

Jitsi users are stored in Prosody XMPP server:
```
Format: username@auth.meet.jitsi
Example: john@auth.meet.jitsi
Login: username (just the username part)
```

### Creating New Users

#### Method 1: Command Line (Primary Method)

```bash
# SSH to server
ssh root@YOUR_SERVER_IP

# Create regular user
docker exec jitsi-prosody prosodyctl \
  --config /config/prosody.cfg.lua \
  register USERNAME auth.meet.jitsi PASSWORD

# Example - Create user "alice"
docker exec jitsi-prosody prosodyctl \
  --config /config/prosody.cfg.lua \
  register alice auth.meet.jitsi SecurePass123!
# Creates: alice@auth.meet.jitsi
```

**Parameters:**
- `USERNAME` - Username (letters, numbers, dots, hyphens)
- `auth.meet.jitsi` - Authentication domain (fixed)
- `PASSWORD` - Strong password (8+ characters recommended)

**Examples:**

```bash
# Create user for John Doe
docker exec jitsi-prosody prosodyctl \
  --config /config/prosody.cfg.lua \
  register john.doe auth.meet.jitsi JohnPass456!

# Create user for team member
docker exec jitsi-prosody prosodyctl \
  --config /config/prosody.cfg.lua \
  register alice auth.meet.jitsi AliceSecret789!

# Create admin user
docker exec jitsi-prosody prosodyctl \
  --config /config/prosody.cfg.lua \
  register admin auth.meet.jitsi AdminPassword123!
```

### Managing Existing Users

#### Change User Password

```bash
# Reset password for existing user
docker exec jitsi-prosody prosodyctl \
  --config /config/prosody.cfg.lua \
  passwd USERNAME@auth.meet.jitsi

# Or specify password directly
docker exec jitsi-prosody prosodyctl \
  --config /config/prosody.cfg.lua \
  register USERNAME auth.meet.jitsi NEW_PASSWORD
```

#### Delete User

```bash
# Remove user account
docker exec jitsi-prosody prosodyctl \
  --config /config/prosody.cfg.lua \
  deluser USERNAME@auth.meet.jitsi

# Example
docker exec jitsi-prosody prosodyctl \
  --config /config/prosody.cfg.lua \
  deluser alice@auth.meet.jitsi
```

#### List All Users

```bash
# View all registered users
docker exec jitsi-prosody \
  ls -la /config/data/auth%2emeet%2ejitsi/accounts/

# Count users
docker exec jitsi-prosody \
  ls /config/data/auth%2emeet%2ejitsi/accounts/ | wc -l
```

#### Check if User Exists

```bash
# Check for specific user
docker exec jitsi-prosody \
  ls /config/data/auth%2emeet%2ejitsi/accounts/ | grep USERNAME

# View user details
docker exec jitsi-prosody \
  cat /config/data/auth%2emeet%2ejitsi/accounts/USERNAME.dat
```

### Batch User Creation

Create multiple users at once:

```bash
#!/bin/bash
# save as create_jitsi_users.sh

USERS=(
  "alice:AlicePass123!"
  "bob:BobPass456!"
  "charlie:CharliePass789!"
  "diana:DianaPass012!"
)

for user_pass in "${USERS[@]}"; do
  username=$(echo $user_pass | cut -d':' -f1)
  password=$(echo $user_pass | cut -d':' -f2)
  
  echo "Creating Jitsi user: $username"
  docker exec jitsi-prosody prosodyctl \
    --config /config/prosody.cfg.lua \
    register "$username" auth.meet.jitsi "$password"
  
  if [ $? -eq 0 ]; then
    echo "✅ Created: $username@auth.meet.jitsi"
  else
    echo "❌ Failed to create: $username"
  fi
done

echo ""
echo "User creation complete!"
```

### User Best Practices

✅ **Unique usernames** - Use email prefix or full names  
✅ **Strong passwords** - 12+ characters, mixed case, numbers, symbols  
✅ **Document users** - Keep a list of who has access  
✅ **Regular audits** - Review user accounts quarterly  
✅ **Remove inactive** - Delete accounts for departed team members  

---

## 🌐 Using Jitsi Meet: Web Browser

### Accessing Jitsi Meet

1. **Open your browser** (Chrome, Firefox, Safari, Edge)
2. **Navigate to:** `https://meet.itin.buzz`
3. You'll see the Jitsi Meet home page

### Creating a Meeting

#### Step 1: Authentication

1. Click on your **profile icon** (top right)
2. Click **"Log in"**
3. Enter credentials:
   - **Username:** `username` (e.g., `alice`)
   - **Password:** your password
4. Click **"Login"**

#### Step 2: Start Meeting

1. Enter a **meeting name** in the text box
   - Example: "team-standup"
   - Example: "project-review-2026"
   - Can use letters, numbers, hyphens

2. Click **"Start meeting"** or press **Enter**

3. **Grant permissions:**
   - **Camera:** Click "Allow" (required for video)
   - **Microphone:** Click "Allow" (required for audio)

4. **You're in!** The meeting starts immediately

### Joining a Meeting

#### If You Have the Link

1. **Click the meeting link** (e.g., `https://meet.itin.buzz/team-standup`)
2. **Authenticate** (if not already logged in)
3. **Grant permissions** (camera/mic)
4. Click **"Join meeting"**

#### If You Know the Meeting Name

1. Go to `https://meet.itin.buzz`
2. **Log in** (if required)
3. Enter the **meeting name** in the text box
4. Click **"Join"**

### Meeting Interface Overview

**Top Bar:**
- 🎥 Camera toggle
- 🎤 Microphone toggle
- 🖥️ Share screen
- ✋ Raise hand
- 💬 Chat
- 👥 Participants
- ⚙️ Settings
- ⋮ More options

**Main Area:**
- Video tiles (participants)
- Your video (small thumbnail)
- Screen sharing content

**Bottom Bar:**
- Meeting name/link
- Meeting duration
- Participant count

---

## 📱 Mobile Apps: iOS

### Installation

1. Open **App Store**
2. Search for **"Jitsi Meet"**
3. Install the official Jitsi Meet app
4. Tap **"Open"**

**Direct Link:** https://apps.apple.com/app/jitsi-meet/id1165103905

### Configuration

1. **Open Jitsi Meet app**
2. Tap **⚙️ Settings** (gear icon)
3. Tap **"Server URL"**
4. Enter your server: `https://meet.itin.buzz`
5. Tap **"OK"**

### Creating/Joining Meetings

#### Start New Meeting

1. Open Jitsi Meet app
2. **Authenticate:**
   - Tap meeting name field
   - Tap **"Sign in"** (if needed)
   - Enter username and password
3. Enter **meeting name**
4. Tap **"Start meeting"**
5. Grant camera/mic permissions
6. Meeting starts!

#### Join Existing Meeting

**Method 1: Link**
- Tap the meeting link in Messages/Email
- Opens in Jitsi app automatically

**Method 2: Meeting Name**
- Open app
- Enter meeting name
- Tap "Join"

### iOS Features

✅ **Picture-in-picture** - Continue meeting while using other apps  
✅ **Background audio** - Stay in call with screen off  
✅ **CallKit integration** - Shows as phone call  
✅ **Screen sharing** - Share your screen  
✅ **Reactions** - Send emoji reactions  
✅ **Virtual backgrounds** - Blur or replace background  
✅ **Low battery mode** - Reduce video quality to save power  

### iOS Tips

**Enable Picture-in-Picture:**
1. During meeting, swipe up (or home button)
2. Video minimizes to corner
3. Tap to expand back to full screen

**Improve Battery Life:**
- Turn off video when not needed
- Use Wi-Fi instead of cellular
- Enable "Low power mode" in iOS settings

---

## 🤖 Mobile Apps: Android

### Installation

1. Open **Google Play Store**
2. Search for **"Jitsi Meet"**
3. Install the official Jitsi Meet app
4. Tap **"Open"**

**Direct Link:** https://play.google.com/store/apps/details?id=org.jitsi.meet

Or **F-Droid:** https://f-droid.org/packages/org.jitsi.meet/

### Configuration

1. **Open Jitsi Meet app**
2. Tap **⋮** (three dots) → **"Settings"**
3. Tap **"Server URL"**
4. Enter: `https://meet.itin.buzz`
5. Tap **"OK"**

### Creating/Joining Meetings

Same process as iOS (see above)

### Android Features

✅ **Picture-in-picture** - Multitask during meetings  
✅ **Screen sharing** - Share your screen  
✅ **Reactions** - Emoji reactions  
✅ **Virtual backgrounds** - Background blur/replacement  
✅ **Tile view** - See all participants  
✅ **Low bandwidth mode** - Auto-adjust quality  

### Android Tips

**Disable Battery Optimization:**
1. Settings → Apps → Jitsi Meet
2. Battery → Battery optimization
3. Select "Don't optimize"

**Enable Picture-in-Picture:**
1. Settings → Apps → Jitsi Meet
2. Advanced → Picture-in-picture
3. Enable "Allow picture-in-picture"

---

## 🖥️ Desktop Apps

### Electron Desktop App

#### Download

**Official releases:**
- Windows: https://github.com/jitsi/jitsi-meet-electron/releases
- macOS: https://github.com/jitsi/jitsi-meet-electron/releases
- Linux: https://github.com/jitsi/jitsi-meet-electron/releases

#### Features

✅ Native desktop application  
✅ Better performance than browser  
✅ System tray integration  
✅ Always-on-top mode  
✅ Better screen sharing  
✅ Background blur  

### Browser Recommendations

**Best Experience:**
1. **Google Chrome** / **Chromium** (recommended)
2. **Microsoft Edge** (Chromium-based)
3. **Firefox** (good support)
4. **Safari** (macOS/iOS - decent support)

**Features by Browser:**
- **Chrome/Edge:** All features supported
- **Firefox:** All features, minor differences
- **Safari:** Limited screen sharing options

---

## 🎯 Meeting Features

### Video & Audio Controls

**Camera Toggle (🎥)**
- Click to turn camera on/off
- Keyboard: `V`
- Right-click for camera settings

**Microphone Toggle (🎤)**
- Click to mute/unmute
- Keyboard: `M`
- Hold `Space` for push-to-talk

**Audio Settings:**
- Click ⚙️ Settings → Audio
- Select input device (microphone)
- Select output device (speakers)
- Test audio levels

**Video Settings:**
- Click ⚙️ Settings → Video
- Select camera
- Adjust resolution/quality
- Enable/disable background blur

### Screen Sharing

1. Click **🖥️ Share screen** button
2. Choose what to share:
   - **Entire screen** - Share everything
   - **Application window** - Share specific app
   - **Chrome tab** - Share browser tab only (Chrome/Edge)
3. Click **"Share"**
4. Click **"Stop sharing"** when done

**Tips:**
- Close sensitive tabs/apps before sharing
- Use "Application window" for focused sharing
- Mute notifications during screen share

### Chat

1. Click **💬 Chat** icon
2. Type message in text box
3. Press **Enter** to send
4. Messages visible to all participants

**Chat Features:**
- Private messages (click username → "Send private message")
- File sharing (drag & drop into chat)
- Link sharing (auto-clickable)
- Emoji support 😊

### Reactions

1. Click **"Reactions"** (smiley face) or press keyboard shortcut
2. Select emoji:
   - 👍 Thumbs up
   - 🎉 Party popper
   - 👏 Clapping hands
   - ❤️ Heart
   - 😂 Laugh
   - 😮 Surprised
   - 👎 Thumbs down

**Keyboard Shortcuts:**
- `:raise-hand:` - ✋ Raise hand
- `:thumbsup:` - 👍
- `:clap:` - 👏

### Raise Hand

1. Click **✋ Raise Hand** button
2. Your hand appears next to your name
3. Moderator can see who has hand raised
4. Click again to lower hand

**Use Cases:**
- Ask a question
- Request to speak
- Vote on something
- Get attention

### Participants Panel

1. Click **👥 Participants** icon
2. View list of all participants
3. See who's speaking (green border)
4. See who's muted/unmuted

**Moderator Controls:**
- Mute individual participants
- Mute all participants
- Kick participants
- Grant moderator rights

### Settings

Click **⚙️ Settings** to access:

**Audio:**
- Microphone selection
- Speaker selection  
- Noise suppression
- Echo cancellation

**Video:**
- Camera selection
- Resolution/quality
- Background blur
- Virtual backgrounds

**More:**
- Display name
- Email (for Gravatar)
- Bandwidth settings
- Language

---

## 📹 Recording Meetings

### Local Recording (Browser)

**Chrome/Edge (Best Option):**
1. Start meeting
2. Click **⋮** (More) → **"Start recording"**
3. Recording starts (indicator appears)
4. Click **"Stop recording"** when done
5. Video saves to Downloads folder

**Note:** This records locally on your computer, not on server.

### Screen Recording (Alternative)

Use OS built-in screen recording:

**macOS:**
- Press `Cmd + Shift + 5`
- Select area and click "Record"

**Windows:**
- Press `Win + G` (Game Bar)
- Click record button

**Linux:**
- Use `kazam`, `SimpleScreenRecorder`, or `OBS Studio`

### Professional Recording (OBS Studio)

For high-quality recordings:

1. **Install OBS Studio:**
   - Download from: https://obsproject.com/
   - Free and open source

2. **Configure OBS:**
   - Add "Display Capture" or "Window Capture" source
   - Add "Audio Input Capture" for microphone
   - Add "Audio Output Capture" for system audio

3. **Record:**
   - Click "Start Recording"
   - Join Jitsi meeting
   - Click "Stop Recording" when done

4. **Output:**
   - Videos saved in: Videos/OBS folder
   - Format: MP4 or MKV

---

## 🔗 Integration Guide

### Embedding Jitsi in Website

```html
<!-- Add Jitsi Meet API -->
<script src='https://meet.itin.buzz/external_api.js'></script>

<!-- Container for Jitsi -->
<div id="meet"></div>

<!-- Initialize Jitsi -->
<script>
  const domain = 'meet.itin.buzz';
  const options = {
    roomName: 'your-room-name',
    width: '100%',
    height: 700,
    parentNode: document.querySelector('#meet'),
    userInfo: {
      email: 'user@example.com',
      displayName: 'John Doe'
    }
  };
  const api = new JitsiMeetExternalAPI(domain, options);
</script>
```

### Slack Integration

**Create Slash Command:**
1. Go to Slack API: https://api.slack.com/apps
2. Create new app
3. Add slash command: `/meet`
4. Set Request URL: `https://your-server/slack-command`
5. Users type: `/meet project-review` to create meeting link

### Calendar Integration

**Google Calendar:**
1. Create event
2. Add location: `https://meet.itin.buzz/meeting-name`
3. Guests click link to join

**Outlook:**
1. Create meeting
2. Add meeting link in body or location
3. Users click to join

### Matrix Integration

Your Jitsi is already integrated with Matrix!

**Start Group Video Call in Element:**
1. In any Matrix room
2. Click **🎥 Video call** icon
3. For 3+ people, uses Jitsi automatically
4. Opens your Jitsi server

---

## 🛠️ Troubleshooting

### Cannot Access Jitsi Web Interface

**Check server is running:**
```bash
ssh root@YOUR_SERVER_IP
docker ps | grep jitsi-web
```

**Check DNS:**
```bash
dig meet.itin.buzz
# Should return your server IP
```

**Test HTTPS:**
```bash
curl -I https://meet.itin.buzz
# Should return: HTTP/2 200
```

### Authentication Not Working

**Verify credentials:**
```bash
# List users
docker exec jitsi-prosody \
  ls /config/data/auth%2emeet%2ejitsi/accounts/

# Check authdomain is correct
docker exec jitsi-web cat /config/config.js | grep authdomain
# Should show: config.hosts.authdomain = 'auth.meet.jitsi';
```

**Reset password:**
```bash
docker exec jitsi-prosody prosodyctl \
  --config /config/prosody.cfg.lua \
  register username auth.meet.jitsi NewPassword123!
```

### Can't Join Meeting / Stuck on Loading

**Clear browser cache:**
- Chrome: `Ctrl+Shift+Delete` → Clear browsing data
- Firefox: `Ctrl+Shift+Delete` → Clear recent history

**Try incognito/private mode:**
- Chrome: `Ctrl+Shift+N`
- Firefox: `Ctrl+Shift+P`

**Check browser console:**
- Press `F12` → Console tab
- Look for errors (red text)

### No Video/Audio

**Grant permissions:**
- Browser asks for camera/microphone access
- Click "Allow"
- If denied, click 🔒 in address bar → Permissions

**Check device selection:**
- Click ⚙️ Settings
- Audio → Select correct microphone
- Video → Select correct camera

**Test devices:**
```bash
# On Linux, test camera
ls /dev/video*

# Test with ffplay
ffplay /dev/video0
```

**Browser issues:**
- Chrome works best
- Firefox: Enable WebRTC
- Safari: Check camera permissions in macOS Settings

### Poor Video/Audio Quality

**Check bandwidth:**
```bash
# Speed test
speedtest-cli
# Need: 1+ Mbps upload, 2+ Mbps download per participant
```

**Reduce quality:**
1. Click ⚙️ Settings
2. Video → Lower resolution
3. Bandwidth → Set to "Low bandwidth mode"

**Network improvements:**
- Use wired connection (Ethernet)
- Close bandwidth-heavy apps
- Limit number of participants

### Screen Sharing Not Working

**Grant permission:**
- Browser will ask for screen recording permission
- macOS: System Preferences → Security → Screen Recording
- Windows: Should work automatically

**Try different sharing mode:**
- Instead of "Entire screen" → Try "Application window"
- Or share specific Chrome tab

**Browser compatibility:**
- Best in Chrome/Edge
- Firefox: May need additional permissions
- Safari: Limited support

### Mobile App Issues

**Can't Connect:**
- Verify server URL: `https://meet.itin.buzz` (must have https://)
- Check internet connection
- Try cellular if WiFi fails (or vice versa)

**App Crashes:**
- Update to latest version
- Clear app cache (Settings → Apps → Jitsi → Clear cache)
- Reinstall app

**Battery Drain:**
- Turn off video when not needed
- Use WiFi instead of cellular
- Enable Low Power Mode (iOS)

### Firewall Issues

**Server-side:**
```bash
# Jitsi needs these ports open:
# TCP: 80, 443 (HTTPS/HTTP)
# UDP: 10000 (video/audio)

# Check firewall
sudo ufw status
sudo iptables -L -n | grep -E "80|443|10000"
```

**Client-side:**
- Corporate firewall may block UDP 10000
- Try different network
- Contact IT department

---

## 📊 Quick Reference

### Admin Commands

```bash
# List Jitsi users
docker exec jitsi-prosody ls /config/data/auth%2emeet%2ejitsi/accounts/

# Create user
docker exec jitsi-prosody prosodyctl --config /config/prosody.cfg.lua register USERNAME auth.meet.jitsi PASSWORD

# Delete user
docker exec jitsi-prosody prosodyctl --config /config/prosody.cfg.lua deluser USERNAME@auth.meet.jitsi

# Check Jitsi logs
docker logs jitsi-web --tail 50
docker logs jitsi-prosody --tail 50

# Restart Jitsi
docker restart jitsi-web jitsi-prosody jitsi-jicofo jitsi-jvb

# Check authentication domain
docker exec jitsi-web cat /config/config.js | grep authdomain
```

### Meeting URL Format

```
https://meet.itin.buzz/MEETING-NAME

Examples:
https://meet.itin.buzz/team-standup
https://meet.itin.buzz/project-review
https://meet.itin.buzz/1-on-1-alice-bob
```

### Keyboard Shortcuts

```
M - Mute/unmute microphone
V - Toggle camera
D - Toggle desktop sharing
C - Open/close chat
R - Raise hand
F - Toggle fullscreen
T - Toggle tile view
Space - Push to talk (hold)
```

### URLs & Ports

```
Jitsi Web: https://meet.itin.buzz
Server IP: YOUR_SERVER_IP
HTTPS Port: 443 (TCP)
JVB Port: 10000 (UDP)
Authentication: Required (fully private mode)
```

---

## 📚 Additional Resources

- **Jitsi Handbook:** https://jitsi.github.io/handbook/
- **Jitsi Community:** https://community.jitsi.org/
- **GitHub Issues:** https://github.com/jitsi/jitsi-meet/issues
- **API Documentation:** https://jitsi.github.io/handbook/docs/dev-guide/dev-guide-iframe

---

**Need help?** Contact your system administrator or check server logs with the commands above.
