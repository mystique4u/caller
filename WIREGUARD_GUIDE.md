# WireGuard VPN Setup & Administration Guide

Complete guide for setting up WireGuard VPN clients and managing your self-hosted VPN server.

---

## 📋 Table of Contents

1. [Admin Guide: Managing VPN Server](#admin-guide-managing-vpn-server)
2. [Creating VPN Clients](#creating-vpn-clients)
3. [Client Setup: Windows](#client-setup-windows)
4. [Client Setup: macOS](#client-setup-macos)
5. [Client Setup: Linux](#client-setup-linux)
6. [Client Setup: iOS (iPhone/iPad)](#client-setup-ios-iphoneipad)
7. [Client Setup: Android](#client-setup-android)
8. [Client Setup: Router](#client-setup-router)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

---

## 🔐 Admin Guide: Managing VPN Server

### Accessing WireGuard UI

Your WireGuard server includes a web-based management interface:

```
URL: https://vpn.YOUR_DOMAIN
Example: https://vpn.itin.buzz
```

**Default Credentials:**
- Username: `admin`
- Password: Set via `WGUI_PASSWORD` GitHub Secret

### WireGuard UI Features

✅ **Web-based management** - No SSH needed  
✅ **Client management** - Add/remove/edit clients  
✅ **QR codes** - Easy mobile setup  
✅ **Download configs** - For desktop clients  
✅ **Traffic statistics** - Monitor usage  
✅ **Online status** - See connected clients  

### Server Information

**Network Configuration:**
- **VPN Network:** `10.0.0.0/24`
- **Server IP:** `10.0.0.1`
- **Client IPs:** `10.0.0.2` - `10.0.0.254`
- **UDP Port:** `51820`
- **DNS:** `1.1.1.1` (Cloudflare)

**Access Details:**
```bash
# SSH to server
ssh root@YOUR_SERVER_IP

# Check WireGuard status
docker exec wireguard-ui wg show

# View WireGuard logs
docker logs wireguard-ui --tail 100 -f

# Restart WireGuard
docker restart wireguard-ui
```

---

## 👥 Creating VPN Clients

### Method 1: Using WireGuard UI (Recommended)

1. **Login to WireGuard UI:**
   - Go to `https://vpn.itin.buzz`
   - Enter admin credentials

2. **Create New Client:**
   - Click **"Add Client"** or **"New Client"** button
   - Enter client details:
     - **Name:** Device identifier (e.g., "john-laptop", "alice-phone")
     - **Email:** Optional (for reference)
     - **Allocated IPs:** Auto-assigned (e.g., `10.0.0.2/32`)
     - **Allowed IPs:** `0.0.0.0/0` (route all traffic through VPN)
     - **Enable:** Check this box
   - Click **"Submit"** or **"Save"**

3. **Download Configuration:**
   - **For Desktop:** Click **"Download"** button to get `.conf` file
   - **For Mobile:** Click **"QR Code"** icon to display QR code

### Method 2: Via Command Line

```bash
# SSH to server
ssh root@YOUR_SERVER_IP

# Add new peer
docker exec wireguard-ui wg set wg0 peer PUBLIC_KEY \
  allowed-ips 10.0.0.X/32

# Generate keypair for new client
wg genkey | tee client_private.key | wg pubkey > client_public.key

# View keys
cat client_private.key
cat client_public.key
```

### Client Naming Convention

Use descriptive names for easy identification:

```
✅ Good names:
- john-laptop
- alice-iphone
- bob-windows-desktop
- mary-android-tablet
- office-router

❌ Bad names:
- client1
- peer2
- test
```

---

## 🪟 Client Setup: Windows

### Installation

1. **Download WireGuard:**
   - Visit: https://www.wireguard.com/install/
   - Download **"Windows 7, 8, 10, 11 Installer"**
   - Or direct download: https://download.wireguard.com/windows-client/wireguard-installer.exe

2. **Install:**
   - Run the installer
   - Follow installation wizard
   - Click **"Finish"**

### Configuration

#### Method 1: Import Configuration File

1. **Download config from WireGuard UI:**
   - Login to `https://vpn.itin.buzz`
   - Find your client
   - Click **"Download"** → Save `.conf` file

2. **Import to WireGuard app:**
   - Open **WireGuard** app
   - Click **"Import tunnel(s) from file"**
   - Select your `.conf` file
   - Click **"Open"**

#### Method 2: Manual Configuration

1. Open **WireGuard** app
2. Click **"Add empty tunnel"**
3. Enter configuration:

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_FROM_WGUI
Address = 10.0.0.X/32
DNS = 1.1.1.1

[Peer]
PublicKey = SERVER_PUBLIC_KEY_FROM_WGUI
Endpoint = YOUR_SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

4. Click **"Save"**

### Connecting

1. Open **WireGuard** app
2. Select your tunnel from the list
3. Click **"Activate"**
4. Status will change to **"Active"**
5. You're now connected! 🎉

### Testing Connection

```powershell
# Check your IP (should show VPN server IP)
curl ifconfig.me

# Ping VPN gateway
ping 10.0.0.1

# Test DNS
nslookup google.com
```

### Windows Features

✅ System tray integration  
✅ Auto-start with Windows  
✅ Start tunnel automatically  
✅ View real-time traffic stats  
✅ Edit tunnels on-the-fly  
✅ Multiple tunnel profiles  

---

## 🍎 Client Setup: macOS

### Installation

#### Option 1: App Store (Recommended)

1. Open **App Store**
2. Search for **"WireGuard"**
3. Install the official WireGuard app
4. Launch from Applications

**Direct Link:** https://apps.apple.com/app/wireguard/id1451685025

#### Option 2: Homebrew

```bash
brew install wireguard-tools
brew install --cask wireguard
```

### Configuration

#### Method 1: Import Configuration File

1. **Download config from WireGuard UI**
2. **Import to app:**
   - Open **WireGuard** app
   - Click **"Import tunnel(s) from file"** (or drag & drop)
   - Select your `.conf` file

#### Method 2: QR Code (if using iOS app on macOS)

1. Open WireGuard app
2. Click **"Add Configuration"** → **"Create from QR code"**
3. Allow camera access
4. Scan QR code from WireGuard UI

#### Method 3: Manual Configuration

1. Open **WireGuard** app
2. Click **"+"** → **"Add Empty Tunnel"**
3. Paste configuration (same format as Windows)
4. Click **"Save"**

### Connecting

1. Open **WireGuard** app
2. Toggle the switch next to your tunnel
3. macOS will ask for permission (first time only)
4. Enter your password
5. Status shows **"Active"** when connected

### Testing Connection

```bash
# Check your IP
curl ifconfig.me

# Ping VPN gateway
ping 10.0.0.1

# Check routing
netstat -rn | grep 10.0.0
```

### macOS Features

✅ Menu bar integration  
✅ Native macOS UI  
✅ Automatic reconnection  
✅ On-demand activation  
✅ Network extension API  
✅ Touch ID support (for activation)  

---

## 🐧 Client Setup: Linux

### Installation

#### Ubuntu/Debian

```bash
# Update package list
sudo apt update

# Install WireGuard
sudo apt install wireguard wireguard-tools resolvconf

# Verify installation
wg --version
```

#### Fedora/RHEL/CentOS

```bash
# Install WireGuard
sudo dnf install wireguard-tools

# Or for older RHEL/CentOS
sudo yum install epel-release
sudo yum install wireguard-tools
```

#### Arch Linux

```bash
sudo pacman -S wireguard-tools
```

### Configuration

1. **Download config from WireGuard UI**

2. **Copy to WireGuard directory:**
   ```bash
   sudo mkdir -p /etc/wireguard
   sudo cp ~/Downloads/client.conf /etc/wireguard/wg0.conf
   sudo chmod 600 /etc/wireguard/wg0.conf
   ```

3. **Or create manually:**
   ```bash
   sudo nano /etc/wireguard/wg0.conf
   ```
   
   Paste configuration:
   ```ini
   [Interface]
   PrivateKey = YOUR_PRIVATE_KEY
   Address = 10.0.0.X/32
   DNS = 1.1.1.1

   [Peer]
   PublicKey = SERVER_PUBLIC_KEY
   Endpoint = YOUR_SERVER_IP:51820
   AllowedIPs = 0.0.0.0/0
   PersistentKeepalive = 25
   ```

### Connecting

#### Manual Connection

```bash
# Start VPN
sudo wg-quick up wg0

# Stop VPN
sudo wg-quick down wg0

# Check status
sudo wg show
```

#### Auto-start on Boot

```bash
# Enable service
sudo systemctl enable wg-quick@wg0

# Start service
sudo systemctl start wg-quick@wg0

# Check status
sudo systemctl status wg-quick@wg0

# View logs
sudo journalctl -u wg-quick@wg0 -f
```

#### Stop Auto-start

```bash
sudo systemctl disable wg-quick@wg0
sudo systemctl stop wg-quick@wg0
```

### Testing Connection

```bash
# Check your IP
curl ifconfig.me

# Ping VPN gateway
ping 10.0.0.1

# Check interface
ip addr show wg0

# Check routing
ip route | grep wg0

# Test DNS
dig google.com
```

### Network Manager GUI (Ubuntu Desktop)

```bash
# Install Network Manager plugin
sudo apt install network-manager-wireguard

# Then use GUI:
# Settings → Network → VPN → + → Import from file
# Select your .conf file
```

---

## 📱 Client Setup: iOS (iPhone/iPad)

### Installation

1. Open **App Store**
2. Search for **"WireGuard"**
3. Install the official WireGuard app
4. Tap **"Open"**

**Direct Link:** https://apps.apple.com/app/wireguard/id1441195209

### Configuration

#### Method 1: QR Code (Easiest)

1. **Open WireGuard app** on iPhone/iPad
2. Tap **"+"** (top right)
3. Tap **"Create from QR code"**
4. Grant camera permission
5. **On your computer:**
   - Login to `https://vpn.itin.buzz`
   - Find your iOS client
   - Click **"QR Code"** icon
6. **Scan the QR code** with your iPhone/iPad
7. Enter a name (e.g., "My iPhone")
8. Tap **"Save"**

#### Method 2: File Import

1. **Download config** on your iPhone/iPad:
   - Open Safari, go to `https://vpn.itin.buzz`
   - Download `.conf` file
2. **Open in WireGuard:**
   - Tap the downloaded file
   - Choose **"Open in WireGuard"**
   - Tap **"Add"**

#### Method 3: Manual Entry

1. Open WireGuard app
2. Tap **"+"** → **"Create from scratch"**
3. Enter name
4. Fill in configuration details
5. Tap **"Save"**

### Connecting

1. **Open WireGuard app**
2. Find your tunnel
3. **Toggle the switch** to ON
4. First time: Tap **"Allow"** for VPN configuration
5. Status shows **"Active"**
6. Connected! 🎉

### iOS Features

✅ **On-Demand VPN** - Auto-connect when needed  
✅ **Kill Switch** - Block traffic if VPN drops  
✅ **Widget Support** - Quick toggle from home screen  
✅ **Siri Shortcuts** - Voice control  
✅ **Background connectivity** - Always on  
✅ **Low battery impact**  

### iOS Settings

#### Enable On-Demand

1. Open WireGuard app
2. Tap **(i)** next to your tunnel
3. Tap **"Edit"**
4. Enable **"On Demand"**
5. Configure rules:
   - **Wi-Fi SSIDs** (connect on specific networks)
   - **Cellular** (connect on mobile data)
   - **Ethernet** (connect when wired)
6. Tap **"Save"**

#### Add to Control Center

1. Go to **Settings** → **Control Center**
2. Under **More Controls**, find **VPN**
3. Tap **"+"** to add
4. Now toggle from Control Center

---

## 🤖 Client Setup: Android

### Installation

1. Open **Google Play Store**
2. Search for **"WireGuard"**
3. Install the official WireGuard app
4. Tap **"Open"**

**Direct Link:** https://play.google.com/store/apps/details?id=com.wireguard.android

Or **F-Droid:** https://f-droid.org/packages/com.wireguard.android/

### Configuration

#### Method 1: QR Code (Easiest)

1. **Open WireGuard app** on Android
2. Tap **"+"** (bottom right)
3. Tap **"Scan from QR code"**
4. Grant camera permission
5. **On your computer:**
   - Login to `https://vpn.itin.buzz`
   - Find your Android client
   - Click **"QR Code"** icon
6. **Scan the QR code**
7. Enter a name (e.g., "My Phone")
8. Tap **"Create Tunnel"**

#### Method 2: File Import

1. **Download config:**
   - Open Chrome, go to `https://vpn.itin.buzz`
   - Download `.conf` file
2. **Import to WireGuard:**
   - Open WireGuard app
   - Tap **"+"** → **"Import from file or archive"**
   - Select your `.conf` file
   - Tap **"Create Tunnel"**

#### Method 3: Manual Entry

1. Tap **"+"** → **"Create from scratch"**
2. Enter name
3. Tap **"Interface"** → Fill in details
4. Tap **"Peer"** → Fill in details
5. Tap **"Save"** (checkmark icon)

### Connecting

1. **Open WireGuard app**
2. Find your tunnel
3. **Toggle the switch** to ON
4. First time: Tap **"OK"** for VPN request
5. Status shows **"Active"**
6. Notification appears in status bar

### Android Features

✅ **Always-On VPN** - Auto-reconnect  
✅ **Quick Settings Tile** - Toggle from notification shade  
✅ **Per-App VPN** - Route specific apps through VPN  
✅ **Battery efficient**  
✅ **Automatic updates**  

### Android Settings

#### Enable Always-On VPN

1. Go to **Settings** → **Network & Internet** → **VPN**
2. Tap ⚙️ next to **WireGuard**
3. Enable **"Always-on VPN"**
4. Enable **"Block connections without VPN"** (recommended)

#### Disable Battery Optimization

1. **Settings** → **Apps** → **WireGuard**
2. **Battery** → **Battery optimization**
3. Select **"Don't optimize"**
4. This prevents Android from killing VPN

#### Add Quick Settings Tile

1. Swipe down notification shade (twice)
2. Tap **"Edit"** (pencil icon)
3. Find **"WireGuard"** tile
4. Drag to active area
5. Tap **"Done"**

---

## 🌐 Client Setup: Router

### Supported Routers

- **DD-WRT** (with WireGuard support)
- **OpenWrt** (recommended)
- **pfSense**
- **OPNsense**
- **Ubiquiti EdgeRouter**
- **MikroTik RouterOS**

### Example: OpenWrt

#### Installation

```bash
# SSH to router
ssh root@192.168.1.1

# Update package lists
opkg update

# Install WireGuard
opkg install wireguard-tools kmod-wireguard

# Install LuCI (web UI) package
opkg install luci-proto-wireguard luci-app-wireguard
```

#### Configuration

1. **Create WireGuard interface:**
   ```bash
   # Create config
   cat > /etc/config/network << 'EOF'
   config interface 'wg0'
       option proto 'wireguard'
       option private_key 'YOUR_PRIVATE_KEY'
       list addresses '10.0.0.X/32'
   
   config wireguard_wg0
       option public_key 'SERVER_PUBLIC_KEY'
       option endpoint_host 'YOUR_SERVER_IP'
       option endpoint_port '51820'
       option persistent_keepalive '25'
       list allowed_ips '0.0.0.0/0'
   EOF
   ```

2. **Configure firewall:**
   ```bash
   uci add firewall zone
   uci set firewall.@zone[-1].name='wg'
   uci set firewall.@zone[-1].input='REJECT'
   uci set firewall.@zone[-1].output='ACCEPT'
   uci set firewall.@zone[-1].forward='REJECT'
   uci set firewall.@zone[-1].masq='1'
   uci add_list firewall.@zone[-1].network='wg0'
   
   uci add firewall forwarding
   uci set firewall.@forwarding[-1].src='lan'
   uci set firewall.@forwarding[-1].dest='wg'
   
   uci commit firewall
   ```

3. **Start VPN:**
   ```bash
   ifup wg0
   ```

### Benefits of Router VPN

✅ **All devices protected** - No client software needed  
✅ **IoT devices** - Protect smart home devices  
✅ **Guest network** - Separate VPN/non-VPN traffic  
✅ **Set and forget** - Always on  

---

## 🛠️ Troubleshooting

### Cannot Connect to VPN

**Check server is reachable:**
```bash
# Test UDP port
nc -u -v -w 3 YOUR_SERVER_IP 51820

# Check from server
ssh root@YOUR_SERVER_IP
docker logs wireguard-ui --tail 50
```

**Firewall issues:**
```bash
# Server firewall must allow UDP 51820
# Check with:
sudo ufw status | grep 51820
# or
sudo iptables -L -n | grep 51820
```

### VPN Connects But No Internet

**Check routing (Linux):**
```bash
# View routes
ip route

# Should see:
# default dev wg0 scope link
# or similar route through wg0

# Test connectivity
ping 10.0.0.1  # VPN gateway
ping 1.1.1.1   # External DNS
```

**Check DNS:**
```bash
# Test DNS resolution
nslookup google.com

# Check /etc/resolv.conf
cat /etc/resolv.conf
# Should show VPN DNS (1.1.1.1)
```

**Server-side check:**
```bash
ssh root@YOUR_SERVER_IP

# Check IP forwarding enabled
cat /proc/sys/net/ipv4/ip_forward
# Should output: 1

# Check iptables NAT
sudo iptables -t nat -L POSTROUTING -v
# Should see MASQUERADE rule
```

### Slow VPN Connection

**Test bandwidth:**
```bash
# Download test
curl -o /dev/null https://proof.ovh.net/files/100Mb.dat

# Upload test (requires upload endpoint)
# Use speedtest-cli:
sudo apt install speedtest-cli
speedtest-cli
```

**Optimize MTU:**
```ini
# In client config, add to [Interface]:
MTU = 1420

# Or try:
MTU = 1380
```

**Check server load:**
```bash
ssh root@YOUR_SERVER_IP
top
docker stats wireguard-ui
```

### Frequent Disconnections

**Enable persistent keepalive:**
```ini
# In client config [Peer] section:
PersistentKeepalive = 25
```

**Check logs:**
```bash
# Linux
sudo journalctl -u wg-quick@wg0 -f

# Server
docker logs wireguard-ui --tail 100 -f
```

### Mobile Battery Drain

**iOS:**
- Disable unnecessary On-Demand rules
- Use WiFi where possible
- Check for apps using excessive data

**Android:**
- Ensure battery optimization is disabled for WireGuard
- Check "Battery usage" in settings
- Reduce PersistentKeepalive value (or disable)

### Cannot Access Local Network While on VPN

**Split tunneling configuration:**

```ini
# Instead of routing all traffic (0.0.0.0/0)
# Route only specific networks through VPN
AllowedIPs = 10.0.0.0/24, 192.168.1.0/24, YOUR_SERVER_IP/32

# This allows local network access while on VPN
```

---

## ✅ Best Practices

### Security

✅ **Unique configs per device** - Never share configurations  
✅ **Strong naming** - Use descriptive, identifiable names  
✅ **Revoke old clients** - Remove unused configurations  
✅ **Regular audits** - Review connected clients monthly  
✅ **Monitor access** - Check WireGuard UI for unusual activity  

### Performance

✅ **MTU optimization** - Start with 1420, adjust if needed  
✅ **Persistent keepalive** - Use 25 seconds for mobile  
✅ **DNS configuration** - Use fast DNS (1.1.1.1 or 8.8.8.8)  
✅ **Server location** - Choose geographically close server  

### Reliability

✅ **Auto-start** - Enable on-boot for critical devices  
✅ **Always-on VPN** - Use for mobile devices  
✅ **Backup configs** - Save configuration files securely  
✅ **Test regularly** - Verify VPN is working correctly  

### Privacy

✅ **Route all traffic** - Use `AllowedIPs = 0.0.0.0/0`  
✅ **Kill switch** - Enable on mobile devices  
✅ **No logs** - WireGuard doesn't log traffic by default  
✅ **Encrypted DNS** - Configure DNS over HTTPS/TLS  

---

## 📊 Quick Reference

### Admin Commands

```bash
# Check WireGuard status
docker exec wireguard-ui wg show

# View connected peers
docker exec wireguard-ui wg show wg0 peers

# Restart WireGuard
docker restart wireguard-ui

# View logs
docker logs wireguard-ui --tail 100 -f

# Check server IP forwarding
cat /proc/sys/net/ipv4/ip_forward

# View iptables rules
sudo iptables -t nat -L -n -v
```

### Client Commands

```bash
# Linux - Start VPN
sudo wg-quick up wg0

# Linux - Stop VPN
sudo wg-quick down wg0

# Linux - Check status
sudo wg show

# Check your public IP
curl ifconfig.me

# Test VPN gateway
ping 10.0.0.1
```

### Configuration Template

```ini
[Interface]
PrivateKey = YOUR_PRIVATE_KEY_HERE
Address = 10.0.0.X/32
DNS = 1.1.1.1
MTU = 1420

[Peer]
PublicKey = SERVER_PUBLIC_KEY_HERE
Endpoint = YOUR_SERVER_IP:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

### URLs

```
WireGuard UI: https://vpn.itin.buzz
Server IP: YOUR_SERVER_IP
VPN Port: 51820 (UDP)
VPN Network: 10.0.0.0/24
VPN Gateway: 10.0.0.1
```

---

## 📚 Additional Resources

- **WireGuard Official:** https://www.wireguard.com/
- **WireGuard Quick Start:** https://www.wireguard.com/quickstart/
- **WireGuard UI Project:** https://github.com/ngoduykhanh/wireguard-ui
- **Community Help:** https://www.wireguard.com/community/

---

**Need help?** Contact your system administrator or check server logs with the commands above.
