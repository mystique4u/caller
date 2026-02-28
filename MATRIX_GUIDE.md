# Matrix/Element Setup & Administration Guide

Complete guide for setting up Matrix clients and managing users on your self-hosted Matrix server.

---

## 📋 Table of Contents

1. [Admin Guide: User Management](#admin-guide-user-management)
2. [Client Setup: Web Browser](#client-setup-web-browser)
3. [Client Setup: Ubuntu/Linux Desktop](#client-setup-ubuntulinux-desktop)
4. [Client Setup: iOS (iPhone/iPad)](#client-setup-ios-iphoneipad)
5. [Client Setup: Android](#client-setup-android)
6. [Client Setup: macOS](#client-setup-macos)
7. [Client Setup: Windows](#client-setup-windows)
8. [First Login & Configuration](#first-login--configuration)
9. [Security & Encryption](#security--encryption)
10. [Troubleshooting](#troubleshooting)

---

## 🔐 Admin Guide: User Management

### Prerequisites

- SSH access to your server
- Matrix homeserver running (check with: `docker ps | grep matrix-synapse`)
- Your domain name (e.g., `itin.buzz`)

### Creating New Users

#### Method 1: Command Line (Recommended)

SSH into your server and use the registration tool:

```bash
# SSH to your server
ssh root@YOUR_SERVER_IP

# Create a regular user
docker exec matrix-synapse register_new_matrix_user \
  -u USERNAME \
  -p PASSWORD \
  --no-admin \
  -c /data/homeserver.yaml \
  http://localhost:8008

# Create an admin user
docker exec matrix-synapse register_new_matrix_user \
  -u USERNAME \
  -p PASSWORD \
  --admin \
  -c /data/homeserver.yaml \
  http://localhost:8008
```

**Parameters:**
- `-u USERNAME` - The username (without @ or :domain)
- `-p PASSWORD` - User's password (must be strong!)
- `--admin` - Makes the user an admin (use for admin users)
- `--no-admin` - Makes a regular user (use for regular users)
- `-c /data/homeserver.yaml` - Config file path
- `http://localhost:8008` - Synapse API endpoint

**Examples:**

```bash
# Create regular user "alice"
docker exec matrix-synapse register_new_matrix_user \
  -u alice \
  -p SecurePass123! \
  --no-admin \
  -c /data/homeserver.yaml \
  http://localhost:8008
# Creates: @alice:itin.buzz

# Create admin user "bob"
docker exec matrix-synapse register_new_matrix_user \
  -u bob \
  -p AdminPass456! \
  --admin \
  -c /data/homeserver.yaml \
  http://localhost:8008
# Creates: @bob:itin.buzz (with admin privileges)

# Create user for your team member
docker exec matrix-synapse register_new_matrix_user \
  -u john.doe \
  -p TeamMember789! \
  --no-admin \
  -c /data/homeserver.yaml \
  http://localhost:8008
# Creates: @john.doe:itin.buzz
```

#### Method 2: Interactive Mode

If you don't want to specify the password in the command:

```bash
docker exec -it matrix-synapse register_new_matrix_user \
  -c /data/homeserver.yaml \
  http://localhost:8008
```

You'll be prompted for:
- Username
- Password (hidden input)
- Confirm password
- Make admin? (yes/no)

### Managing Existing Users

#### Reset User Password

```bash
# Reset password for existing user
docker exec matrix-synapse register_new_matrix_user \
  -u USERNAME \
  -p NEW_PASSWORD \
  -c /data/homeserver.yaml \
  http://localhost:8008
```

Note: This will overwrite the existing user with the new password.

#### Deactivate User Account

```bash
# Connect to Synapse database
docker exec -it matrix-postgres psql -U synapse -d synapse

# Deactivate user (in psql prompt)
UPDATE users SET deactivated = 1 WHERE name = '@username:itin.buzz';
\q
```

#### List All Users

```bash
# View all registered users
docker exec matrix-postgres psql -U synapse -d synapse -c \
  "SELECT name, admin, deactivated, creation_ts FROM users ORDER BY creation_ts DESC;"
```

#### Make User Admin

```bash
# Promote user to admin
docker exec matrix-postgres psql -U synapse -d synapse -c \
  "UPDATE users SET admin = 1 WHERE name = '@username:itin.buzz';"
```

#### Remove Admin Rights

```bash
# Demote admin to regular user
docker exec matrix-postgres psql -U synapse -d synapse -c \
  "UPDATE users SET admin = 0 WHERE name = '@username:itin.buzz';"
```

### Batch User Creation

Create multiple users at once:

```bash
#!/bin/bash
# save as create_users.sh

USERS=(
  "alice:Password123!"
  "bob:Password456!"
  "charlie:Password789!"
)

for user_pass in "${USERS[@]}"; do
  username=$(echo $user_pass | cut -d':' -f1)
  password=$(echo $user_pass | cut -d':' -f2)
  
  echo "Creating user: $username"
  docker exec matrix-synapse register_new_matrix_user \
    -u "$username" \
    -p "$password" \
    --no-admin \
    -c /data/homeserver.yaml \
    http://localhost:8008
done
```

### User Account Format

All users on your homeserver follow this format:
```
@username:your-domain.com
```

**Example:** If your domain is `itin.buzz`:
- Username `admin` becomes `@admin:itin.buzz`
- Username `alice` becomes `@alice:itin.buzz`
- Username `john.doe` becomes `@john.doe:itin.buzz`

---

## 🌐 Client Setup: Web Browser

**Platform:** Any (Windows, macOS, Linux, ChromeOS)  
**Requirements:** Modern web browser (Firefox, Chrome, Safari, Edge)

### Access

Simply navigate to:
```
https://chat.YOUR_DOMAIN
```

**Example:** `https://chat.itin.buzz`

### First Time Setup

1. **Open your browser** and go to `https://chat.itin.buzz`
2. You'll see the Element welcome screen
3. Click **"Sign In"**
4. The homeserver should already be set to `https://matrix.itin.buzz`
5. Enter your credentials:
   - **Username:** `@username:itin.buzz` or just `username`
   - **Password:** (your password)
6. Click **"Sign in"**
7. Complete device verification (see Security section below)

### Features

✅ Full messaging functionality  
✅ Voice and video calls  
✅ File sharing  
✅ End-to-end encryption  
✅ Room management  
✅ Works on any device with a browser  

### Tips

- **Bookmark the page** for quick access
- **Enable notifications** in browser settings
- **Add to home screen** on mobile browsers for app-like experience

---

## 🖥️ Client Setup: Ubuntu/Linux Desktop

### Option 1: Snap (Recommended)

```bash
# Install Element Desktop via Snap
sudo snap install element-desktop

# Launch Element
element-desktop
```

### Option 2: Debian/Ubuntu Package (.deb)

```bash
# Add Element repository
sudo wget -O /usr/share/keyrings/element-io-archive-keyring.gpg \
  https://packages.element.io/debian/element-io-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] \
  https://packages.element.io/debian/ default main" | \
  sudo tee /etc/apt/sources.list.d/element-io.list

# Update and install
sudo apt update
sudo apt install element-desktop
```

### Option 3: Flatpak

```bash
# Install via Flatpak
flatpak install flathub im.riot.Riot

# Launch
flatpak run im.riot.Riot
```

### Option 4: AppImage (Portable)

```bash
# Download latest AppImage
wget https://packages.riot.im/desktop/install/linux/Element.AppImage

# Make executable
chmod +x Element.AppImage

# Run
./Element.AppImage
```

### Configure Homeserver

1. Launch Element Desktop
2. On the welcome screen, click **"Sign in"**
3. Click **"Edit"** next to the default homeserver
4. Enter your homeserver URL: `https://matrix.itin.buzz`
5. Click **"Continue"**
6. Enter your credentials:
   - **Username:** `@username:itin.buzz`
   - **Password:** (your password)
7. Click **"Sign in"**

### Linux-Specific Features

✅ Native desktop notifications  
✅ System tray integration  
✅ Keyboard shortcuts  
✅ Multiple account support  
✅ Works offline (cached messages)  

---

## 📱 Client Setup: iOS (iPhone/iPad)

### Installation

1. Open **App Store** on your iPhone or iPad
2. Search for **"Element - Secure Messenger"**
3. Look for the app by **"Element"** (formerly Riot)
4. Tap **"Get"** to download and install
5. Tap **"Open"** when installation completes

**Direct Link:** [Element on App Store](https://apps.apple.com/app/vector/id1083446067)

### First Time Configuration

1. **Launch Element** app
2. On the welcome screen, tap **"Sign in"**
3. Tap **"Edit"** next to "matrix.org"
4. Enter your homeserver: `https://matrix.itin.buzz`
5. Tap **"Continue"**
6. Enter your credentials:
   - **Username:** `@username:itin.buzz`
   - **Password:** (your password)
7. Tap **"Sign in"**
8. **Grant permissions:**
   - Notifications: Tap **"Allow"** (to receive message alerts)
   - Microphone: Tap **"Allow"** (for voice calls)
   - Camera: Tap **"Allow"** (for video calls)
9. **Set up encryption:**
   - Create a recovery key when prompted
   - Store it securely (iCloud Keychain or password manager)

### iOS Features

✅ Push notifications (even when app is closed)  
✅ Voice and video calls (including FaceTime-like calls)  
✅ Face ID / Touch ID authentication  
✅ Share extension (share from other apps)  
✅ Widget support (iOS 14+)  
✅ CallKit integration  
✅ Background sync  
✅ Photo and file sharing  
✅ Siri shortcuts (iOS 12+)  

### iOS Settings

#### Enable Notifications

1. Go to iPhone **Settings** → **Element**
2. Tap **Notifications**
3. Enable **"Allow Notifications"**
4. Choose your alert style: Banners or Alerts
5. Enable **Sound** and **Badge App Icon**

#### Enable Face ID / Touch ID

1. Open Element app
2. Tap profile icon (top left)
3. Tap **"Settings"** → **"Security & Privacy"**
4. Enable **"Face ID"** or **"Touch ID"**

#### Improve Battery Life

1. Element **Settings** → **Notifications**
2. Reduce notification frequency if needed
3. Disable notifications for less important rooms

---

## 🤖 Client Setup: Android

### Installation

#### Option 1: Google Play Store (Recommended)

1. Open **Google Play Store**
2. Search for **"Element - Secure Messenger"**
3. Look for app by **"Element"**
4. Tap **"Install"**
5. Tap **"Open"** when installation completes

**Direct Link:** [Element on Google Play](https://play.google.com/store/apps/details?id=im.vector.app)

#### Option 2: F-Droid (Open Source)

1. Install **F-Droid** app store: https://f-droid.org
2. Open F-Droid
3. Search for **"Element"**
4. Tap **"Install"**

#### Option 3: Direct APK Download

```bash
# Download from GitHub releases
# Visit: https://github.com/element-hq/element-android/releases
# Download the latest .apk file
# Enable "Install from unknown sources" in Android settings
# Install the APK
```

### First Time Configuration

1. **Launch Element** app
2. On the welcome screen, tap **"Sign in"**
3. Tap **"Edit"** next to "matrix.org"
4. Enter your homeserver: `https://matrix.itin.buzz`
5. Tap **"Continue"**
6. Enter your credentials:
   - **Username:** `@username:itin.buzz`
   - **Password:** (your password)
7. Tap **"Sign in"**
8. **Grant permissions:**
   - Notifications: Tap **"Allow"**
   - Microphone: Tap **"Allow"** (for voice calls)
   - Camera: Tap **"Allow"** (for video calls)
   - Storage: Tap **"Allow"** (for file sharing)
9. **Set up encryption:**
   - Create a recovery key when prompted
   - Back it up securely

### Android Features

✅ Push notifications (FCM)  
✅ Voice and video calls  
✅ Fingerprint / PIN lock  
✅ Share from other apps  
✅ Picture-in-picture for video calls  
✅ Background sync  
✅ Custom notification sounds  
✅ Quick reply from notifications  
✅ Android Auto support  

### Android Settings

#### Disable Battery Optimization

To ensure you receive messages promptly:

1. Go to Android **Settings** → **Apps** → **Element**
2. Tap **Battery** → **Battery optimization**
3. Find Element and select **"Don't optimize"**

#### Enable Persistent Notification

1. Open Element app
2. Tap profile icon (top left)
3. Tap **"Settings"** → **"Notifications"**
4. Enable **"Show persistent notification"**
5. This keeps Element running in background

#### Customize Notifications

1. Element **Settings** → **Notifications**
2. Configure per-room notification settings
3. Set custom sounds for different rooms
4. Enable/disable vibration

---

## 🍎 Client Setup: macOS

### Installation

#### Option 1: Download from Element.io

1. Visit: https://element.io/download
2. Click **"Download for macOS"**
3. Open the downloaded `.dmg` file
4. Drag **Element** to **Applications** folder
5. Open Element from Applications

#### Option 2: Homebrew

```bash
# Install using Homebrew
brew install --cask element

# Launch
open -a Element
```

### Configuration

1. Launch Element
2. Click **"Sign in"**
3. Click **"Edit"** next to default homeserver
4. Enter: `https://matrix.itin.buzz`
5. Click **"Continue"**
6. Enter credentials and sign in

### macOS Features

✅ Native notifications  
✅ Menu bar integration  
✅ Keyboard shortcuts  
✅ Touch Bar support  
✅ Handoff support  

---

## 🪟 Client Setup: Windows

### Installation

#### Option 1: Official Installer

1. Visit: https://element.io/download
2. Click **"Download for Windows"**
3. Run the downloaded installer
4. Follow installation wizard
5. Launch Element from Start Menu

#### Option 2: Microsoft Store

1. Open **Microsoft Store**
2. Search for **"Element"**
3. Click **"Get"** or **"Install"**
4. Launch from Start Menu

#### Option 3: Portable Version

1. Download portable zip from Element.io
2. Extract to desired location
3. Run `Element.exe`

### Configuration

Same as macOS - configure homeserver on first launch.

### Windows Features

✅ Desktop notifications (Action Center)  
✅ System tray integration  
✅ Start with Windows  
✅ Multiple accounts  

---

## 🚀 First Login & Configuration

### Initial Login Steps

1. **Open Element** (web or app)
2. **Sign in** with your credentials
3. **Verify your session:**
   - You'll see "Verify this session" prompt
   - This is for end-to-end encryption
4. **Set up recovery:**
   - Create and save your recovery key
   - Store it in password manager or secure location
5. **Review settings:**
   - Notifications
   - Theme (light/dark)
   - Language

### Creating Your First Room

1. Click the **"+"** button (or "Create room")
2. Enter room name (e.g., "Team Chat")
3. Choose room settings:
   - **Public** (anyone can join) or **Private** (invite only)
   - **Enable encryption** (recommended) ✅
4. Click **"Create room"**
5. **Invite users:**
   - Click "Invite" button
   - Enter username: `@alice:itin.buzz`
   - Click "Invite"

### Sending Your First Message

1. Select a room or start direct message
2. Type your message in the text box
3. Press **Enter** to send
4. Try these features:
   - **Emoji:** Click smiley face icon
   - **File sharing:** Click paperclip icon
   - **Voice message:** Hold microphone icon
   - **Formatting:** Use markdown (bold: `**text**`)

### Starting a Call

#### 1-on-1 Voice/Video Call

1. Open direct message with user
2. Click **phone icon** (voice) or **camera icon** (video)
3. Wait for other user to answer

#### Group Video Call (3+ people)

1. Open room with multiple members
2. Click **video camera icon**
3. This opens Jitsi Meet in new window
4. Share the meeting link with participants

---

## 🔐 Security & Encryption

### Understanding Encryption

Element uses **end-to-end encryption** (E2EE) by default:
- 🔒 Messages encrypted on your device
- 🔑 Only you and recipients can read them
- 🛡️ Server cannot decrypt messages
- ✅ Verified with device verification

### Device Verification

**Why verify devices?**
- Confirms you're talking to the right person
- Prevents man-in-the-middle attacks
- Required to read encrypted message history

**How to verify:**

1. **When you see "Unverified session" warning:**
   - Click **"Verify"**
   - Choose verification method:
     - **Compare emoji** (easiest)
     - **Compare numbers**

2. **Emoji verification:**
   - You and the other person see the same 7 emoji
   - Check they match on both devices
   - If they match, click **"They match"**
   - If they don't, click **"They don't match"** and report

3. **Cross-signing setup:**
   - Automatically set up on first login
   - Allows verifying new devices easily
   - Enter your security key or passphrase

### Backup Encryption Keys

**Critical:** Backup your encryption keys!

1. Go to **Settings** → **Security & Privacy**
2. Click **"Backup"** in Key Backup section
3. Choose backup method:
   - **Security phrase** (easier to remember)
   - **Security key** (more secure, 58-character key)
4. **Store securely:**
   - Password manager (recommended)
   - Physical safe
   - Encrypted USB drive
   - **Never** store in plain text or email

### Security Best Practices

✅ **Use strong passwords** (16+ characters, mixed types)  
✅ **Enable two-factor auth** (if available)  
✅ **Verify all devices** (yours and contacts)  
✅ **Backup encryption keys** (critical!)  
✅ **Review active sessions** regularly  
✅ **Use encrypted rooms** for sensitive conversations  
✅ **Sign out from unused devices**  
✅ **Keep apps updated**  

### Managing Sessions

**View active sessions:**
1. Settings → Security & Privacy → Sessions
2. See all devices logged into your account

**Sign out from old devices:**
1. Find the old session
2. Click **"Sign out"**
3. Confirm

**Sign out from all devices:**
1. Settings → Security & Privacy
2. Click **"Sign out all devices"**
3. Requires password confirmation

---

## 🛠️ Troubleshooting

### Can't Connect to Homeserver

**Symptoms:** "Failed to connect" or timeout errors

**Solutions:**

1. **Check homeserver URL:**
   ```
   Should be: https://matrix.itin.buzz
   NOT: http://matrix.itin.buzz
   NOT: matrix.itin.buzz (missing https://)
   ```

2. **Test homeserver is running:**
   ```bash
   curl https://matrix.itin.buzz/_matrix/client/versions
   # Should return: {"versions":["r0.0.1","r0.1.0",...]}
   ```

3. **Check DNS:**
   ```bash
   dig matrix.itin.buzz
   # Should return your server IP
   ```

4. **Check firewall:**
   ```bash
   # From your client machine
   telnet YOUR_SERVER_IP 443
   # Should connect
   ```

### Login Failed / Invalid Credentials

**Solutions:**

1. **Verify username format:**
   - Correct: `@username:itin.buzz`
   - Also works: `username` (domain auto-added)
   - Wrong: `username@itin.buzz` (email format)

2. **Reset password:**
   ```bash
   ssh root@YOUR_SERVER_IP
   docker exec matrix-synapse register_new_matrix_user \
     -u username \
     -p NewPassword123! \
     -c /data/homeserver.yaml \
     http://localhost:8008
   ```

### Messages Not Sending

**Solutions:**

1. **Check encryption:**
   - Red warning? Verify the device
   - "Waiting for device" - other user needs to login

2. **Check network:**
   - Are you online?
   - Try sending in unencrypted room

3. **Clear cache:**
   - Settings → Help & About → Clear cache and reload

### Push Notifications Not Working

#### iOS:

1. **Check permissions:**
   - iPhone Settings → Element → Notifications → Allow

2. **Re-enable notifications:**
   - Element Settings → Notifications
   - Toggle off and on

3. **Check notification rules:**
   - Element Settings → Notifications
   - Ensure rules are not muting notifications

#### Android:

1. **Disable battery optimization:**
   - Settings → Apps → Element → Battery
   - Select "Don't optimize"

2. **Check notification channels:**
   - Settings → Apps → Element → Notifications
   - Ensure all channels enabled

3. **Check Do Not Disturb:**
   - Ensure DND is not blocking notifications

### Unable to Decrypt Messages

**Symptoms:** "Unable to decrypt" / "The sender hasn't sent the keys"

**Solutions:**

1. **Verify your devices:**
   - Settings → Security & Privacy
   - Verify all your sessions

2. **Request keys from sender:**
   - Usually happens automatically
   - Wait a few minutes and reload

3. **Restore from backup:**
   - Settings → Security & Privacy → Key Backup
   - Enter recovery key/passphrase

4. **Last resort - reset encryption:**
   - ⚠️ This will lose encrypted message history
   - Settings → Security & Privacy
   - "Reset keys"

### Video/Voice Calls Not Working

**Solutions:**

1. **Check permissions:**
   - Browser: Allow microphone/camera access
   - Mobile: Check app permissions in settings

2. **Test call:**
   - Call the "Element Bot" or test user
   - Verify microphone/camera work

3. **Check network:**
   - Voice/video calls need good connection
   - Try switching Wi-Fi/cellular

4. **For group calls (Jitsi):**
   - Verify Jitsi is accessible: `https://meet.itin.buzz`
   - Check firewall allows UDP port 10000

### App Crashes or Freezes

**Solutions:**

1. **Update app:**
   - Check for updates in App Store/Play Store/F-Droid

2. **Clear cache:**
   - Settings → Help & About → Clear cache

3. **Reinstall app:**
   - Backup encryption keys first!
   - Uninstall and reinstall
   - Sign in again

### Sync Issues

**Symptoms:** Old messages, missing messages, out of sync

**Solutions:**

1. **Force sync:**
   - Pull down to refresh (mobile)
   - Reload page (web)

2. **Check connection:**
   - Ensure internet is stable
   - Try switching networks

3. **Clear cache and sync:**
   - Settings → Help & About
   - Clear cache
   - Sign out and sign in again

---

## 📞 Getting Help

### Admin Commands

```bash
# Check Matrix logs
docker logs matrix-synapse --tail 100 -f

# Check Matrix status
docker ps | grep matrix

# Restart Matrix services
cd /opt/services
docker compose restart matrix-synapse

# Check database
docker exec matrix-postgres psql -U synapse -d synapse -c "SELECT COUNT(*) FROM users;"

# View disk usage
du -sh /opt/services/matrix/*
```

### Useful Resources

- **Element Help:** https://element.io/help
- **Matrix Spec:** https://matrix.org/docs/spec/
- **Element GitHub:** https://github.com/element-hq/element-web/issues
- **Matrix Community:** https://matrix.to/#/#matrix:matrix.org

### Admin Support Matrix Room

Create a support room for your team:

1. Create room: "Tech Support"
2. Make it encrypted
3. Invite all team members
4. Pin important info

---

## 📊 Quick Reference

### Common Commands

```bash
# Create user
docker exec matrix-synapse register_new_matrix_user -u USER -p PASS --no-admin -c /data/homeserver.yaml http://localhost:8008

# Create admin
docker exec matrix-synapse register_new_matrix_user -u USER -p PASS --admin -c /data/homeserver.yaml http://localhost:8008

# List users
docker exec matrix-postgres psql -U synapse -d synapse -c "SELECT name FROM users;"

# Check Matrix status
docker logs matrix-synapse --tail 50

# Restart Matrix
docker restart matrix-synapse
```

### Username Format

```
Full ID: @username:itin.buzz
Login: username (or full ID)
Display name: Can be anything (e.g., "John Doe")
```

### URLs

```
Homeserver: https://matrix.itin.buzz
Element Web: https://chat.itin.buzz
Jitsi Meet: https://meet.itin.buzz
```

---

**Need help?** Contact your system administrator or check the logs with the commands above.
