# Secure Communication Platform

Fully automated deployment of **WireGuard VPN**, **Jitsi Meet video conferencing**, **Matrix messaging server**, and **Traefik reverse proxy** on Hetzner Cloud with **custom domain and HTTPS/SSL certificates**.

## 🚀 Features

- ✅ **Fully Automated** - Zero manual configuration via CI/CD
- ✅ **WireGuard VPN** with Web UI for client management
- ✅ **Jitsi Meet** - Secure video conferencing with authentication
- ✅ **Matrix Synapse** - Private messaging with E2E encryption
- ✅ **Element Web** - Modern Matrix web client
- ✅ **Traefik** - Automatic HTTPS with Let's Encrypt
- ✅ **Docker-based** - All services containerized
- ✅ **Firewall Automated** - Created and managed by Terraform
- ✅ **Custom Domain Support** - Automatic DNS and SSL certificates
- ✅ **Secrets Management** - All credentials in GitHub Secrets

## 📋 Access Your Services

All services accessible via HTTPS with your custom domain:

| Service               | URL                                      | Credentials                              |
| --------------------- | ---------------------------------------- | ---------------------------------------- |
| **Traefik Dashboard** | `https://yourdomain.com:8080/dashboard/` | No auth                                  |
| **WireGuard UI**      | `https://vpn.yourdomain.com`             | Admin via WireGuard UI                   |
| **Jitsi Meet**        | `https://meet.yourdomain.com`            | Admin credentials from GitHub Secrets    |
| **Matrix Synapse**    | `https://matrix.yourdomain.com`          | Homeserver URL for clients               |
| **Element Web**       | `https://chat.yourdomain.com`            | Matrix credentials from GitHub Secrets   |

## ⚡ Quick Start

1. **Configure Required GitHub Secrets** (see below)
2. **Push to main** or trigger "Deploy Infrastructure" workflow
3. **Wait ~10 minutes** for deployment
4. **Update nameservers** at your domain registrar to Hetzner
5. **Access services** via HTTPS with your domain

## 🔐 Required GitHub Secrets

Go to: `Settings` → `Secrets and variables` → `Actions` → `New repository secret`

### Infrastructure Secrets

| Secret Name       | Description                  | Required | Example Value           |
| ----------------- | ---------------------------- | -------- | ----------------------- |
| `TF_API_TOKEN`    | Terraform Cloud API token    | ✅       | `***`                   |
| `HCLOUD_TOKEN`    | Hetzner Cloud API token      | ✅       | `***`                   |
| `FIREWALL_NAME`   | Firewall name (auto-created) | ✅       | `vpn-services-firewall` |
| `SSH_KEY_IDS`     | SSH key IDs as JSON array    | ✅       | `[108153935]`           |
| `SSH_PRIVATE_KEY` | Private SSH key for Ansible  | ✅       | Full key content        |
| `DOMAIN_NAME`     | Your custom domain           | ✅       | `example.com`           |
| `EMAIL_ADDRESS`   | Email for SSL notifications  | ✅       | `admin@example.com`     |

### Service Credentials

| Secret Name                  | Description                 | Required | Example Value    |
| ---------------------------- | --------------------------- | -------- | ---------------- |
| `JITSI_ADMIN_USER`           | Jitsi admin username        | ✅       | `admin`          |
| `JITSI_ADMIN_PASSWORD`       | Jitsi admin password        | ✅       | `SecurePass123!` |
| `MATRIX_ADMIN_USER`          | Matrix admin username       | ✅       | `myadmin`        |
| `MATRIX_ADMIN_PASSWORD`      | Matrix admin password       | ✅       | `SecurePass456!` |
| `MATRIX_REGISTRATION_SECRET` | Matrix registration secret  | ✅       | Random string    |
| `MATRIX_POSTGRES_PASSWORD`   | PostgreSQL database pwd     | ✅       | `DbPass789!`     |

**Note**: DNS is automatically managed by Hetzner using your `HCLOUD_TOKEN`.

**Detailed setup guide**: See [docs/GITHUB_SECRETS.md](docs/GITHUB_SECRETS.md)

## 🏗️ Infrastructure

- **Provider**: Hetzner Cloud
- **OS**: Clean Ubuntu 24.04
- **Instance**: CX23 (2 vCPU, 8GB RAM)
- **Location**: Nuremberg (nbg1)
- **Firewall**: Auto-managed (SSH, HTTP, Traefik, WireGuard)

## 🔧 What Gets Installed

### System Packages

- WireGuard & tools
- Docker & Docker Compose
- PostgreSQL client
- Essential utilities (htop, vim, git, curl, etc.)

### Docker Services

- **Traefik v2.11** - Reverse proxy with Let's Encrypt SSL
- **WireGuard UI v0.6.2** - VPN management interface  
- **Jitsi Meet** - Video conferencing stack (4 containers)
  - Web frontend
  - Prosody XMPP server
  - Jicofo conference focus
  - JVB video bridge
- **Matrix Synapse** - Homeserver with E2E encryption
- **PostgreSQL 15** - Database for Matrix
- **Element Web** - Matrix web client

### Network Configuration

- IP forwarding enabled (IPv4 & IPv6)
- WireGuard interface: `wg0` (10.0.0.1/24)
- NAT/Masquerading for VPN clients

### Firewall Rules (Auto-created)

```
Port 22    (TCP) - SSH
Port 80    (TCP) - HTTP (redirects to HTTPS)
Port 443   (TCP) - HTTPS (all services)
Port 8080  (TCP) - Traefik dashboard
Port 10000 (UDP) - Jitsi video bridge
Port 51820 (UDP) - WireGuard VPN
```

## 🚦 Deployment Options

### Automatic (on Push)

```bash
git push origin main
```

**Note**: Deployment is skipped if only documentation files (`.md`) are changed.

### Manual Redeploy

1. Go to **Actions** → **"Deploy Infrastructure"**
2. Click **"Run workflow"**
3. Wait for completion (~10 minutes)

## 📖 Comprehensive Usage Guides

### 🔐 WireGuard VPN Setup

**Full Guide**: [WIREGUARD_GUIDE.md](WIREGUARD_GUIDE.md)

Quick start:
1. Access WireGuard UI: `https://vpn.yourdomain.com`
2. Create client connections via web interface
3. Download config or scan QR code
4. Import into WireGuard app (all platforms supported)

### 📹 Jitsi Meet Video Conferencing

**Full Guide**: [JITSI_GUIDE.md](JITSI_GUIDE.md)

Quick start:
1. Access Jitsi: `https://meet.yourdomain.com`
2. Create private meetings (authentication required)
3. Share meeting link with participants
4. Features: Screen sharing, recording, virtual backgrounds

### 💬 Matrix Messaging & Element Web

**Full Guide**: [MATRIX_GUIDE.md](MATRIX_GUIDE.md)

Quick start:
1. Access Element Web: `https://chat.yourdomain.com`
2. Login with admin credentials (auto-created from GitHub Secrets)
3. Create encrypted rooms and channels
4. Add users (admin must create accounts)
5. Use clients on all platforms (iOS, Android, Windows, macOS, Linux)

## 🗂️ Server Directory Structure

```
/opt/services/
├── docker-compose.yml     # All service definitions
├── wireguard-ui/          # WireGuard UI database
├── jitsi/                 # Jitsi Meet configuration
│   ├── web/               # Web frontend config
│   ├── prosody/           # XMPP server config
│   ├── jicofo/            # Conference focus config
│   └── jvb/               # Video bridge config
├── matrix/                # Matrix Synapse
│   ├── homeserver.yaml    # Main configuration
│   └── data/              # Runtime data
├── postgres/              # PostgreSQL data
├── element/               # Element Web config
└── traefik/
    ├── traefik.toml       # Static config
    ├── acme.json          # SSL certificates
    └── dynamic/           # Dynamic routing

/etc/wireguard/
└── wg0.conf              # WireGuard server config
```

## 🛠️ Management Commands

### SSH Access

```bash
ssh root@yourdomain.com
```

### View Service Logs

```bash
cd /opt/services
docker compose logs -f [service_name]

# Examples:
docker compose logs -f traefik
docker compose logs -f matrix-synapse
docker compose logs -f jitsi-web
```

### Restart Services

```bash
cd /opt/services
docker compose restart

# Or specific service:
docker compose restart matrix-synapse
```

### Check All Containers

```bash
docker ps
```

### Check WireGuard Status

```bash
wg show
```

### Create Matrix Users (Admin Only)

```bash
docker exec matrix-synapse register_new_matrix_user \
  -u USERNAME -p PASSWORD --no-admin \
  -c /data/homeserver.yaml http://localhost:8008
```

### Manage Jitsi Users

```bash
docker exec jitsi-prosody prosodyctl --config /config/prosody.cfg.lua \
  register USERNAME meet.jitsi PASSWORD
```

### Update Services

```bash
cd /opt/services
docker compose pull
docker compose up -d
```

## 🔒 Security Features

- ✅ **All credentials stored in GitHub Secrets** - Never in code
- ✅ **HTTPS/SSL everywhere** - Let's Encrypt automatic certificates
- ✅ **Jitsi authentication required** - Private video conferencing
- ✅ **Matrix E2E encryption** - Secure messaging
- ✅ **Registration disabled** - Admin controls user creation
- ✅ **Firewall managed by code** - Only required ports open
- ✅ **Regular security updates** - Easy to update via `docker compose pull`

## 🐛 Troubleshooting

### Services Not Accessible

```bash
# Check all containers
docker ps

# Check Traefik logs
docker logs traefik

# Check specific service
docker logs matrix-synapse
docker logs jitsi-web
```

### SSL Certificate Issues

```bash
# Check Traefik ACME logs
docker logs traefik | grep acme

# Verify certificate file
ls -lh /opt/services/traefik/acme.json
```

### Matrix Connection Issues

```bash
# Check Matrix Synapse logs
docker logs matrix-synapse

# Check PostgreSQL connection
docker exec matrix-postgres psql -U synapse -d synapse -c "SELECT version();"

# Test Matrix API
curl https://matrix.yourdomain.com/_matrix/client/versions
```

### Jitsi Video Issues

```bash
# Check Jitsi services
docker ps | grep jitsi

# Check video bridge
docker logs jitsi-jvb

# Verify ports
sudo ufw status
```

### WireGuard Issues

```bash
wg show  # Check WireGuard status
ip a show wg0  # Check interface
sysctl net.ipv4.ip_forward  # Verify IP forwarding
```

### Reset Everything

```bash
cd /opt/services
docker compose down -v
docker compose up -d
```

**For more troubleshooting**: See individual service guides (WIREGUARD_GUIDE.md, JITSI_GUIDE.md, MATRIX_GUIDE.md)

## 📚 Documentation

### Service-Specific Guides
- **[WireGuard VPN Guide](WIREGUARD_GUIDE.md)** - Complete VPN setup for all platforms
- **[Jitsi Meet Guide](JITSI_GUIDE.md)** - Video conferencing setup and features
- **[Matrix Guide](MATRIX_GUIDE.md)** - Messaging server and Element Web client

### Setup Documentation
- **[GitHub Secrets Setup](docs/GITHUB_SECRETS.md)** - Required secrets configuration
- **[Domain Setup](docs/DOMAIN_SETUP.md)** - DNS and domain configuration
- **[Terraform Cloud Setup](docs/terraform-cloud-setup.md)** - Terraform backend setup

### Infrastructure Details
- **[Deployment Info](DEPLOYMENT.md)** - CI/CD pipeline details
- **[Project Structure](STRUCTURE.md)** - Repository organization

## 🎯 Architecture Overview

```
Internet
    │
    ├─→ DNS (Hetzner) ─→ yourdomain.com
    │                     ├─→ vpn.yourdomain.com
    │                     ├─→ meet.yourdomain.com
    │                     ├─→ matrix.yourdomain.com
    │                     └─→ chat.yourdomain.com
    │
    └─→ Hetzner Server (CX23 - Ubuntu 24.04)
         ├─→ Traefik (Reverse Proxy + SSL)
         │    ├─→ WireGuard UI (VPN Management)
         │    ├─→ Jitsi Meet (Video Conferencing)
         │    ├─→ Matrix Synapse (Messaging Server)
         │    └─→ Element Web (Matrix Client)
         │
         ├─→ PostgreSQL (Matrix Database)
         │
         └─→ WireGuard (VPN Server - wg0 interface)
              └─→ 10.0.0.0/24 network
```

## 🚀 What's Deployed

- **10 Docker containers** running simultaneously
- **7 DNS records** automatically configured
- **Let's Encrypt SSL certificates** with auto-renewal
- **Full CI/CD pipeline** with GitHub Actions
- **Zero-downtime deployments** with health checks
- **Automated backups** of Traefik certificates

## 🎨 Tech Stack

- **Infrastructure**: Terraform (Hetzner Cloud Provider)
- **Configuration**: Ansible
- **Containers**: Docker & Docker Compose
- **Reverse Proxy**: Traefik v2.11
- **SSL**: Let's Encrypt ACME
- **VPN**: WireGuard + WireGuard UI
- **Video**: Jitsi Meet (Prosody + Jicofo + JVB)
- **Messaging**: Matrix Synapse + PostgreSQL + Element Web
- **CI/CD**: GitHub Actions

## 🤝 Contributing

Issues and pull requests welcome!

## 📄 License

MIT License - Use and modify freely.
