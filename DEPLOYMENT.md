# Deployment Guide

## 📋 Overview

This project uses a comprehensive CI/CD pipeline with multiple stages:
- **Automated checks** on every push to main
- **Manual deployment** via GitHub Actions
- **Health checks** after deployment

## 🚀 Initial Deployment

### 1. Set up GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:

**Required:**
- `TF_API_TOKEN` - Terraform Cloud API token
- `HCLOUD_TOKEN` - Hetzner Cloud API token
- `FIREWALL_NAME` - Name for your firewall (e.g., "vpn-firewall")
- `SSH_KEY_IDS` - Hetzner SSH key IDs (comma-separated, e.g., "108153935")
- `SSH_PRIVATE_KEY` - Your SSH private key for Ansible
- `DOMAIN_NAME` - Your domain (e.g., "itin.buzz")
- `EMAIL_ADDRESS` - Email for Let's Encrypt certificates

**Jitsi Meet Authentication:**
- `JITSI_ADMIN_USER` - Admin username (e.g., "admin")
- `JITSI_ADMIN_PASSWORD` - Secure password for admin user

**Matrix/Element Chat:**
- `MATRIX_ADMIN_USER` - Matrix admin username (e.g., "admin")
- `MATRIX_ADMIN_PASSWORD` - Secure password for Matrix admin
- `MATRIX_REGISTRATION_SECRET` - Random secret for registration (generate with: `openssl rand -hex 32`)
- `MATRIX_POSTGRES_PASSWORD` - Database password (generate with: `openssl rand -base64 32`)

**Optional:**
- `LETSENCRYPT_ENV` - Set to `staging` for test certificates (avoids rate limits)
  - Use `staging` for testing deployments
  - Use `production` (default) for real certificates
  - Staging certificates will show browser warnings but won't hit rate limits

### 2. Deploy Infrastructure

1. Go to **Actions** tab in GitHub
2. Select **"Deploy Infrastructure"** workflow
3. Click **"Run workflow"**
4. Select:
   - Branch: `main`
   - Action: `apply`
   - Skip validation: `false` (recommended)
5. Click **"Run workflow"** button
6. Wait for completion (~10-15 minutes)

**First deployment with domain:**
- SSL certificates will be automatically requested from Let's Encrypt
- Certificates are stored in `/opt/services/traefik/acme/acme.json`
- On redeployment, existing certificates are reused (no new requests)
- Certificates auto-renew 30 days before expiration

### 3. Verify Deployment

The workflow will automatically run health checks:
- ✅ Server connectivity
- ✅ HTTP/HTTPS services
- ✅ WireGuard VPN port
- ✅ All subdomains (if domain configured)

## 🔄 Redeploying Changes

### Scenario 1: Infrastructure Changes (Terraform)

**When to use:** Changing server size, firewall rules, DNS records, etc.

1. **Make changes** to `terraform/main.tf`
2. **Commit and push** to main:
   ```bash
   git add terraform/main.tf
   git commit -m "feat: Update server type to CX33"
   git push origin main
   ```
3. **GitHub Actions automatically:**
   - ✅ Runs all checks
   - ✅ Creates Terraform plan
   - ⏸️ Stops (no auto-deploy)
4. **Review the plan** in Actions → Latest workflow run → Plan Summary
5. **Deploy manually:**
   - Actions → Deploy Infrastructure → Run workflow
   - Action: `apply`
   - Run workflow

### Scenario 2: Configuration Changes (Ansible)

**When to use:** Updating Docker containers, services, or configurations

1. **Make changes** to `ansible/playbook.yml`
2. **Commit and push:**
   ```bash
   git add ansible/playbook.yml
   git commit -m "feat: Update WireGuard UI to v0.6.3"
   git push origin main
   ```
3. **Checks run automatically** (validates Ansible syntax)
4. **Deploy manually:**
   - Actions → Deploy Infrastructure → Run workflow
   - Action: `apply`
   - Run workflow

**Note:** Ansible changes only reconfigure the server, don't recreate it.

### Scenario 3: Quick Configuration Update (Without Terraform)

**When to use:** Only Ansible changes, Terraform unchanged

1. Push your Ansible changes
2. Deploy with workflow_dispatch
3. Terraform will show "no changes" (exit code 0)
4. Ansible will still run and update configurations

### Scenario 4: Emergency Changes

**When to use:** Critical fixes that need immediate deployment

1. Make your changes
2. Actions → Deploy Infrastructure → Run workflow
3. Action: `apply`
4. **Skip validation: `true`** (not recommended, but faster)
5. Run workflow

**⚠️ Warning:** Skipping validation bypasses security checks!

## 🗑️ Destroying Infrastructure

### Safety Features:
- Requires typing exact word "DESTROY"
- Requires providing a reason
- Shows destroy plan before execution
- Requires manual approval

### Steps:

1. Go to **Actions** → **"Destroy Infrastructure"**
2. Click **"Run workflow"**
3. Enter:
   - Confirm destroy: `DESTROY` (exact text)
   - Reason: "Reason for destroying infrastructure"
4. Click **"Run workflow"**
5. **Review** the destroy plan in artifacts
6. **Approve** the deployment in GitHub (if environment protection is set up)
7. Infrastructure is destroyed

## 📊 Workflow Stages

### On Push to Main:
```
┌─────────────────────────────────────────┐
│  Code Quality Checks                     │
│  - Secrets scan                          │
│  - File permissions                      │
│  - Ansible syntax                        │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Terraform Validation                    │
│  - Format check                          │
│  - Init & validate                       │
│  - Best practices                        │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Security Scanning                       │
│  - tfsec                                 │
│  - Exposed ports check                   │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Terraform Plan                          │
│  - Create plan                           │
│  - Upload artifact                       │
│  - Show summary                          │
└──────────────┬──────────────────────────┘
               ↓
         ⏸️  STOPS HERE
    (Review required for deployment)
```

### Manual Deploy (workflow_dispatch with 'apply'):
```
         Previous stages...
               ↓
┌─────────────────────────────────────────┐
│  Approval Gate                           │
│  - Manual confirmation required          │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Terraform Apply                         │
│  - Deploy infrastructure                 │
│  - Output server IP                      │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Ansible Configuration                   │
│  - Install services                      │
│  - Configure HTTPS                       │
│  - Deploy containers                     │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Health Checks                           │
│  - Server connectivity                   │
│  - HTTP/HTTPS endpoints                  │
│  - Service availability                  │
│  - Generate report                       │
└─────────────────────────────────────────┘
```

## 🔧 Troubleshooting Redeployments

### Server creation fails: "resource_unavailable"

**Error:** `error during placement (resource_unavailable...)`

**Cause:** The requested server type (CX23) is temporarily out of stock in the selected location.

**Current Hetzner Status (as of Feb 2026):**
- ⚠️ FSN1 (Falkenstein) - Limited availability
- ⚠️ NBG1 (Nuremberg) - May have capacity issues
- ✅ HEL1 (Helsinki) - Usually better availability
- ✅ ASH (Ashburn, USA) - Alternative option

**Solutions:**

1. **Try Helsinki location** (recommended for Europe):
   ```bash
   # Add GitHub Secret:
   # Name: TF_VAR_server_location
   # Value: hel1
   ```
   
   Then redeploy.

2. **Try Ashburn location** (if US location acceptable):
   ```bash
   # Add GitHub Secret:
   # Name: TF_VAR_server_location
   # Value: ash
   ```

3. **Wait and retry in NBG1** (15-60 minutes):
   - Server types frequently become available again
   - Check Hetzner status: https://status.hetzner.cloud/

4. **Use different server type** (edit `terraform/main.tf`):
   - `cx23` (2 vCPU, 8GB RAM) - recommended
   - `cx33` (4 vCPU, 16GB RAM) - larger (usually better availability)
   - `cx21` (2 vCPU, 4GB RAM) - smaller (might be tight)

### Let's Encrypt Rate Limits

**Error:** Too many certificate requests or validation failures

**Cause:** Let's Encrypt has rate limits to prevent abuse:
- 50 certificates per domain per week
- 5 failed validations per hour
- 300 new orders per account per 3 hours

**Solutions:**

1. **Use staging environment for testing** (recommended):
   ```bash
   # Add GitHub Secret:
   # Name: LETSENCRYPT_ENV
   # Value: staging
   ```
   - Staging certificates will show browser warnings
   - No rate limits for testing
   - Switch to `production` when ready

2. **Certificates are automatically preserved**:
   - Stored in `/opt/services/traefik/acme/acme.json`
   - Reused on redeployment (no new requests)
   - Auto-renewed 30 days before expiration
   - Only deleted if you destroy infrastructure

3. **Wait for rate limit reset**:
   - Failed validations: 1 hour
   - Certificate limit: 1 week
   - Check status: https://crt.sh/ (search your domain)

4. **Ensure DNS is correct before deploying**:
   - Verify nameservers are updated
   - Test with: `dig yourdomain.com`
   - Wait for DNS propagation (5-30 minutes)

### Plan shows no changes but you made updates:
- Check if file is committed: `git status`
- Check if pushed: `git log origin/main`
- Verify correct file path in commit

### Ansible fails on redeployment:
- Services might be running: Ansible handles this
- SSH connection issues: Check firewall rules
- DNS not updated: Health checks will warn

### Health checks fail:
- **SSL warnings:** Normal for first 5-10 minutes
- **Subdomain unreachable:** Check DNS propagation
- **All services fail:** Wait 2-3 minutes and recheck

### How to force redeploy without changes:
```bash
# Trigger workflow manually
# No code changes needed
# Just run: Actions → Deploy Infrastructure → apply
```

### How to update only one service:
1. Edit `ansible/playbook.yml`
2. Change the specific service version/config
3. Push and deploy
4. Only affected services are updated

## 📝 Best Practices

### Before Every Deployment:
1. ✅ Review the Terraform plan carefully
2. ✅ Check health check results from previous deployment
3. ✅ Ensure DNS is configured (if using domain)
4. ✅ Backup any important data

### After Every Deployment:
1. ✅ Wait for health checks to complete
2. ✅ Manually verify key services
3. ✅ Check Traefik dashboard
4. ✅ Test WireGuard VPN connection

### Regular Maintenance:
- Update Docker image versions monthly
- Review security scan results
- Monitor server resources
- Rotate SSH keys periodically

## 🆘 Emergency Procedures

### If deployment fails:
1. Check workflow logs for errors
2. Fix the issue in code
3. Push changes (triggers new checks)
4. Redeploy with fixes

### If services are down:
1. Check health check results
2. SSH into server: `ssh root@<server-ip>`
3. Check Docker: `docker ps -a`
4. Check logs: `docker logs <container-name>`
5. Restart if needed: `docker restart <container-name>`

### If you need to rollback:
1. Go to previous working commit: `git log`
2. Revert: `git revert <commit-hash>`
3. Push and redeploy

### Complete infrastructure reset:
1. Run destroy workflow
2. Wait for completion
3. Fix any issues
4. Run deploy workflow fresh

## 📹 Jitsi Meet Video Conferencing

### Authentication & User Management

Jitsi Meet is deployed with **fully private authentication**:
- ✅ **Only registered users** can create meetings
- ✅ **Only registered users** can join meetings
- ❌ **No guest access** - everyone must authenticate

### Admin Credentials

Admin credentials are configured via **GitHub Secrets**:

1. Set `JITSI_ADMIN_USER` in GitHub Secrets (e.g., "admin")
2. Set `JITSI_ADMIN_PASSWORD` in GitHub Secrets (use a strong password)
3. Deploy the infrastructure

**Login URL:** `https://meet.YOUR_DOMAIN`  
**Username:** `YOUR_ADMIN_USER@auth.meet.jitsi`  
**Password:** (as set in GitHub Secrets)

⚠️ **If secrets are not set, no admin user will be created automatically**

### Managing Users

#### Create a new user:
```bash
ssh root@YOUR_SERVER_IP
docker exec jitsi-prosody prosodyctl --config /config/prosody.cfg.lua register USERNAME auth.meet.jitsi PASSWORD
```

Example:
```bash
docker exec jitsi-prosody prosodyctl --config /config/prosody.cfg.lua register john auth.meet.jitsi SecurePass123
```

#### Change user password:
```bash
docker exec jitsi-prosody prosodyctl --config /config/prosody.cfg.lua passwd USERNAME@auth.meet.jitsi
```

#### Delete a user:
```bash
docker exec jitsi-prosody prosodyctl --config /config/prosody.cfg.lua deluser USERNAME@auth.meet.jitsi
```

#### List all users:
```bash
docker exec jitsi-prosody ls -la /config/data/auth%2emeet%2ejitsi/accounts/
```

### How to Use Jitsi Meet

1. **Go to:** `https://meet.YOUR_DOMAIN`
2. **Login** with your credentials (you will be prompted immediately)
3. **Enter a room name** (e.g., "TeamMeeting")
4. **Click "Start meeting"**
5. **Share the meeting URL** with other registered users (they must login to join)

⚠️ **Important:** All participants must have registered accounts. Create accounts for each team member using the commands above.

## 💬 Matrix/Element Secure Messaging

### What is Matrix?

Matrix is a decentralized, secure messaging platform with:
- 🔒 **End-to-end encryption** by default
- 📹 **Voice and video calls** (including group calls with Jitsi integration)
- 💬 **Rich messaging** with file sharing, reactions, threads
- 🌐 **Federation** - connect to other Matrix servers

### Access Points

**Element Web Client:** `https://chat.YOUR_DOMAIN`  
**Matrix Homeserver:** `https://matrix.YOUR_DOMAIN`

### Admin Credentials

Admin credentials are configured via **GitHub Secrets**:

**Username:** `@YOUR_ADMIN_USER:YOUR_DOMAIN` (e.g., `@admin:itin.buzz`)  
**Password:** (as set in GitHub Secrets)

### Managing Users

#### Register a new user (via command line):
```bash
ssh root@YOUR_SERVER_IP
docker exec matrix-synapse register_new_matrix_user -u USERNAME -p PASSWORD -a -c /data/homeserver.yaml http://localhost:8008
```

- `-u USERNAME` - Username (without @ or :domain)
- `-p PASSWORD` - User's password
- `-a` - Make user an admin (optional, remove for regular users)

Example:
```bash
docker exec matrix-synapse register_new_matrix_user -u john -p SecurePass123 -c /data/homeserver.yaml http://localhost:8008
```

This creates user: `@john:YOUR_DOMAIN`

#### Enable open registration (optional):

By default, registration is **disabled** for security. To enable:

```bash
ssh root@YOUR_SERVER_IP
docker exec matrix-synapse sed -i 's/enable_registration: false/enable_registration: true/' /data/homeserver.yaml
docker restart matrix-synapse
```

⚠️ **Not recommended** - anyone can create accounts!

### How to Use Matrix/Element

1. **Go to:** `https://chat.YOUR_DOMAIN`
2. **Click "Sign In"**
3. **Enter credentials:**
   - Username: `@admin:YOUR_DOMAIN`
   - Password: (your password)
4. **Start chatting!**

### Features

✅ **Direct Messages** - 1:1 encrypted chats  
✅ **Rooms** - Group chats with multiple users  
✅ **Voice/Video Calls** - Built-in WebRTC calls  
✅ **Group Video Calls** - Integrated with your Jitsi server  
✅ **File Sharing** - Send documents, images, videos  
✅ **End-to-End Encryption** - All messages encrypted by default  

### 📱 Getting Started with Matrix

#### Option 1: Web Browser (Ubuntu, Mac, Windows)

1. **Open your browser** (Firefox, Chrome, Safari, etc.)
2. **Navigate to:** `https://chat.itin.buzz` (replace with your domain)
3. **First time setup:**
   - Click **"Sign In"**
   - Enter your username: `@admin:itin.buzz` (or your username)
   - Enter your password
   - Click **"Sign in"**
4. **Start using:**
   - Create rooms (group chats)
   - Send direct messages
   - Make voice/video calls
   - Share files and images

#### Option 2: Element Desktop App (Ubuntu/Linux)

**Install via Snap:**
```bash
sudo snap install element-desktop
```

**Or download .deb package:**
```bash
# Download latest release
wget https://packages.riot.im/debian/pool/main/e/element-desktop/element-desktop_1.11.58_amd64.deb

# Install
sudo dpkg -i element-desktop_*.deb
sudo apt-get install -f  # Fix dependencies if needed
```

**Launch and configure:**
1. Open Element Desktop
2. Click **"Edit"** next to "Sign in to matrix.org"
3. Enter homeserver: `https://matrix.itin.buzz` (your domain)
4. Click **"Continue"**
5. Enter username: `@admin:itin.buzz`
6. Enter password
7. Click **"Sign in"**

#### Option 3: Element Mobile (iOS)

**Install from App Store:**
1. Open **App Store** on your iPhone/iPad
2. Search for **"Element - Secure Messenger"**
3. Install the app (by Element)
4. Open Element

**Configure custom homeserver:**
1. On the welcome screen, tap **"Sign in"**
2. Tap **"Edit"** next to "matrix.org"
3. Enter homeserver: `https://matrix.itin.buzz` (your domain)
4. Tap **"Continue"**
5. Enter credentials:
   - **Username:** `@admin:itin.buzz`
   - **Password:** (your password)
6. Tap **"Sign in"**

**Quick Link:** [Element iOS App Store](https://apps.apple.com/app/vector/id1083446067)

**iOS Features:**
- ✅ End-to-end encrypted messaging
- ✅ Push notifications
- ✅ Voice and video calls
- ✅ File sharing and camera integration
- ✅ Background sync
- ✅ Face ID / Touch ID support

#### Option 4: Element Mobile (Android)

**Install from Google Play:**
1. Open **Google Play Store** on your Android device
2. Search for **"Element - Secure Messenger"**
3. Install the app (by Element)
4. Open Element

**Configure custom homeserver:**
1. On the welcome screen, tap **"Sign in"**
2. Tap **"Edit"** next to "matrix.org"
3. Enter homeserver: `https://matrix.itin.buzz` (your domain)
4. Tap **"Continue"**
5. Enter credentials:
   - **Username:** `@admin:itin.buzz`
   - **Password:** (your password)
6. Tap **"Sign in"**

**Alternative: Install via F-Droid (Open Source):**
```bash
# Install F-Droid first, then search for "Element" in F-Droid
# Or download APK from: https://github.com/vector-im/element-android/releases
```

**Quick Link:** [Element Android Play Store](https://play.google.com/store/apps/details?id=im.vector.app)

**Android Features:**
- ✅ End-to-end encrypted messaging
- ✅ Push notifications (FCM)
- ✅ Voice and video calls
- ✅ File sharing and camera integration
- ✅ Background sync
- ✅ Fingerprint / PIN lock

### 🎯 Quick Start Guide

**1. First Login:**
   - Web: `https://chat.itin.buzz`
   - Homeserver: `https://matrix.itin.buzz`
   - Username: `@admin:itin.buzz` (or your username)

**2. Create Your First Room:**
   - Click **"+"** → **"Create room"**
   - Name it (e.g., "Team Chat")
   - Choose encryption: **Enabled** (recommended)
   - Click **"Create room"**

**3. Invite Users:**
   - Inside the room, click **"Invite"**
   - Enter username: `@username:itin.buzz`
   - Click **"Invite"**

**4. Make a Video Call:**
   - Inside any room or direct message
   - Click the **video camera icon**
   - For group video calls (3+ people):
     - Uses your Jitsi server automatically
     - Opens in new tab/window
     - Share the meeting link with participants

**5. Enable Notifications (Mobile):**
   - Open Element Settings → Notifications
   - Grant notification permissions
   - Configure notification preferences

### 🔐 Security & Encryption

**Verify Devices:**
1. When you see "Unverified session" warnings
2. Click **"Verify"**
3. Compare emoji/numbers between devices
4. Click **"They match"**

**Backup Keys:**
1. Go to Settings → Security & Privacy
2. Click **"Backup encryption keys"**
3. Save your security key somewhere safe
4. This allows message recovery on new devices

**Cross-Signing:**
- Automatically set up on first login
- Verifies your devices trust each other
- Enables seamless encryption across devices

### 🛠️ Troubleshooting

**Cannot connect to homeserver:**
```bash
# Check if Matrix is running
ssh root@YOUR_SERVER_IP
docker ps | grep matrix

# Check Matrix logs
docker logs matrix-synapse --tail 50

# Verify DNS
dig matrix.itin.buzz
```

**Forgot password:**
```bash
# Reset password via command line
ssh root@YOUR_SERVER_IP
docker exec matrix-synapse register_new_matrix_user -u USERNAME -p NEW_PASSWORD -c /data/homeserver.yaml http://localhost:8008
```

**Push notifications not working (Mobile):**
- Check app permissions in device settings
- Ensure app is not battery-optimized (Android)
- Verify notification settings in Element app

**Video calls not working:**
- Check microphone/camera permissions
- Verify Jitsi Meet is accessible: `https://meet.itin.buzz`
- Try refreshing the page/app

### Security Best Practices

- ✅ Use **strong passwords** (minimum 16 characters, mix of letters, numbers, symbols)
- ✅ Store credentials **only in GitHub Secrets**, never in code or documentation
- ✅ Create separate user accounts for each team member
- ✅ Rotate passwords periodically
- ✅ Enable **device verification** for all sessions
- ✅ **Backup encryption keys** to avoid losing message history
- ✅ Use **encrypted rooms** for sensitive conversations

### 🧪 Testing Your Matrix Setup

**1. Verify Matrix is running:**
```bash
ssh root@YOUR_SERVER_IP
docker ps | grep matrix
# Should show: matrix-postgres, matrix-synapse, element-web (all running)
```

**2. Test Matrix API:**
```bash
curl https://matrix.itin.buzz/_matrix/client/versions
# Should return: {"versions":["r0.0.1","r0.1.0",...]}
```

**3. Test Element Web:**
```bash
curl -I https://chat.itin.buzz
# Should return: HTTP/2 200
```

**4. Create a test user (Ubuntu):**
```bash
ssh root@YOUR_SERVER_IP
docker exec matrix-synapse register_new_matrix_user \
  -u testuser \
  -p TestPassword123 \
  -c /data/homeserver.yaml \
  http://localhost:8008
```

**5. Login and test messaging:**
- Open `https://chat.itin.buzz` in browser
- Login with: `@testuser:itin.buzz` / `TestPassword123`
- Send a message to your admin account
- Test encryption, file upload, and video call

**6. Test mobile apps:**
- Install Element on iOS/Android
- Configure homeserver: `https://matrix.itin.buzz`
- Login with test user
- Verify push notifications work
- Test voice/video calls

### 📊 Monitoring Matrix

**Check Synapse logs:**
```bash
docker logs matrix-synapse --tail 100 -f
```

**Check database:**
```bash
docker exec matrix-postgres psql -U synapse -d synapse -c "SELECT count(*) FROM users;"
```

**Check disk usage:**
```bash
du -sh /opt/services/matrix/*
```

**Backup Matrix data:**
```bash
# Backup database
docker exec matrix-postgres pg_dump -U synapse synapse > matrix_backup.sql

# Backup Synapse data
tar -czf matrix_data_backup.tar.gz /opt/services/matrix/synapse/
```

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Hetzner Cloud API](https://docs.hetzner.cloud/)
- [Ansible Documentation](https://docs.ansible.com/)
- [WireGuard Documentation](https://www.wireguard.com/quickstart/)
- [Jitsi Meet Documentation](https://jitsi.github.io/handbook/)

## 🔗 Quick Links

- **Hetzner Console:** https://console.hetzner.cloud/
- **Terraform Cloud:** https://app.terraform.io/
- **GitHub Actions:** https://github.com/YOUR_USERNAME/caller/actions
- **Domain DNS:** https://dns.hetzner.com/
- **Jitsi Meet:** https://meet.YOUR_DOMAIN
