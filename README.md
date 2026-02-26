# VPN & Services Server

Fully automated deployment of **WireGuard VPN**, **Galène video conferencing**, and **Traefik reverse proxy** on Hetzner Cloud with optional **custom domain and HTTPS support**.

## 🚀 Features

- ✅ **Fully Automated** - Zero manual configuration
- ✅ **WireGuard VPN** with Web UI for client management
- ✅ **Galène** - Lightweight video conferencing
- ✅ **Traefik** - Modern reverse proxy with automatic HTTPS
- ✅ **Docker-based** - All services containerized
- ✅ **Firewall Automated** - Created and managed by Terraform
- ✅ **Custom Domain Support** - Automatic DNS and SSL certificates
- ✅ **IP-based Access** - Works out of the box without domain

## 📋 Access Your Services

### With Custom Domain (HTTPS)

| Service               | URL                                      | Credentials                   |
| --------------------- | ---------------------------------------- | ----------------------------- |
| **Traefik Dashboard** | `https://yourdomain.com:8080/dashboard/` | No auth                       |
| **WireGuard UI**      | `https://vpn.yourdomain.com`             | `admin` / `admin`             |
| **Galène Video**      | `https://meet.yourdomain.com`            | Room: `public`, Pass: `admin` |

### Without Domain (HTTP)

| Service               | URL                              | Credentials                   |
| --------------------- | -------------------------------- | ----------------------------- |
| **Traefik Dashboard** | `http://YOUR_IP:8080/dashboard/` | No auth                       |
| **WireGuard UI**      | `http://YOUR_IP/wireguard`       | `admin` / `admin`             |
| **Galène Video**      | `http://YOUR_IP/galene`          | Room: `public`, Pass: `admin` |

## ⚡ Quick Start

### Without Domain (Basic)

1. **Configure Required GitHub Secrets** (see below)
2. **Push to main** or trigger "Destroy and Redeploy" workflow
3. **Wait ~10 minutes** for deployment
4. **Access services** using your server IP (HTTP)
5. **Change default passwords** immediately!

### With Custom Domain (HTTPS)

1. **Complete basic setup** above
2. **Follow**: [DOMAIN_QUICKSTART.md](DOMAIN_QUICKSTART.md)
3. **Add 3 more secrets**: `HETZNER_DNS_TOKEN`, `DOMAIN_NAME`, `EMAIL_ADDRESS`
4. **Redeploy** and update nameservers at domain registrar
5. **Access services** via HTTPS with your domain

## 🔐 Required GitHub Secrets

Go to: `https://github.com/YOUR_USERNAME/caller/settings/secrets/actions`

### Basic Setup (HTTP with IP)

| Secret Name       | Description                  | Example Value           |
| ----------------- | ---------------------------- | ----------------------- |
| `TF_API_TOKEN`    | Terraform Cloud API token    | `***`                   |
| `HCLOUD_TOKEN`    | Hetzner Cloud API token      | `***`                   |
| `FIREWALL_NAME`   | Firewall name (auto-created) | `vpn-services-firewall` |
| `SSH_KEY_IDS`     | SSH key IDs as JSON array    | `[108153935]`           |
| `SSH_PRIVATE_KEY` | Private SSH key for Ansible  | Full key content        |

### Optional: Custom Domain (HTTPS)

| Secret Name     | Description                 | Example Value       |
| --------------- | --------------------------- | ------------------- |
| `DOMAIN_NAME`   | Your domain                 | `example.com`       |
| `EMAIL_ADDRESS` | Email for SSL notifications | `admin@example.com` |

**Note**: DNS is automatically managed by your `HCLOUD_TOKEN` - no separate DNS token needed!

**Detailed setup guides**:

- [GitHub Secrets Guide](docs/GITHUB_SECRETS.md)
- [Domain Setup Guide](docs/DOMAIN_SETUP.md)
- [Quick Domain Setup](DOMAIN_QUICKSTART.md)

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
- Essential utilities (htop, vim, git, etc.)

### Docker Services

- **Traefik v2.11** - Reverse proxy & routing
- **WireGuard UI v0.6.2** - VPN management interface
- **Galène** - Video conferencing (via Docker)

### Network Configuration

- IP forwarding enabled (IPv4 & IPv6)
- WireGuard interface: `wg0` (10.0.0.1/24)
- NAT/Masquerading for VPN clients

### Firewall Rules (Auto-created)

```
Port 22    (TCP) - SSH
Port 80    (TCP) - HTTP via Traefik
Port 8080  (TCP) - Traefik dashboard
Port 51820 (UDP) - WireGuard VPN
```

## 🚦 Deployment Options

### Automatic (on Push)

```bash
git push origin main
```

### Manual Redeploy

1. Go to **Actions** → **"Destroy and Redeploy"**
2. Click **"Run workflow"**
3. Type `DESTROY` to confirm
4. Wait for completion

## 📖 Usage Guides

### WireGuard VPN

1. Access: `http://YOUR_IP/wireguard`
2. Login: `admin` / `admin`
3. **Change password immediately!**
4. Create clients:
   - Click "New Client"
   - Enter name
   - Download QR code or config file
5. Import into WireGuard app

### Galène Video Conferencing

1. Access: `http://YOUR_IP/galene`
2. Join room: `public`
3. Operator password: `admin`
4. Share room URL with participants

### Traefik Dashboard

1. Access: `http://YOUR_IP:8080/dashboard/`
2. Monitor service health
3. View routing rules
4. Check real-time metrics

## 🗂️ Server Directory Structure

```
/opt/services/
├── docker-compose.yml     # All service definitions
├── wireguard-ui/          # WireGuard UI database
├── galene/
│   ├── groups/            # Room configurations
│   └── data/              # Runtime data
└── traefik/
    ├── traefik.toml       # Static config
    └── dynamic/           # Dynamic routing

/etc/wireguard/
└── wg0.conf              # WireGuard server config
```

## 🛠️ Management Commands

### SSH Access

```bash
ssh -i ~/.ssh/hetzner-wireguard root@YOUR_IP
```

### View Logs

```bash
cd /opt/services
docker compose logs -f [service_name]
```

### Restart Services

```bash
cd /opt/services
docker compose restart
```

### Check WireGuard

```bash
wg show
```

### Update Services

```bash
cd /opt/services
docker compose pull
docker compose up -d
```

## 🔒 Security Notes

- ⚠️ **Change all default passwords immediately!**
- Services use HTTP (not HTTPS) on IP addresses
- For production: configure domain + Let's Encrypt
- Backup `/opt/services/` and `/etc/wireguard/` regularly
- Firewall automatically restricts access to required ports only

## 🐛 Troubleshooting

### Services Not Accessible

```bash
docker ps  # Check running containers
docker logs traefik  # Check Traefik logs
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

## 📚 Documentation

- [Secrets Configuration Update](docs/GITHUB_SECRETS.md)
- [Pre-Deployment Checklist](CHECKLIST.md)
- [Quick Start Guide](QUICKSTART.md)
- [Terraform Cloud Setup](docs/terraform-cloud-setup.md)
- [GitHub Secrets Setup](docs/github-secrets-setup.md)
- [Branch Protection](docs/branch-protection.md)

## 🎯 Key Improvements

### ✅ No Manual Firewall Setup

- Firewall automatically created by Terraform
- All rules defined in code
- Can be destroyed and recreated

### ✅ Enhanced Performance

- CX23 instance (8GB RAM, was 4GB)
- Better for video conferencing
- Handles more concurrent connections

### ✅ All Config in GitHub Secrets

- No hardcoded credentials
- Easy credential rotation
- Secure storage

### ✅ Galène Integration

- Official installation method followed
- Docker-based deployment
- HTTP mode for IP-based access

## 🤝 Contributing

Issues and pull requests welcome!

## 📄 License

MIT License - Use and modify freely.
