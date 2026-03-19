# Secure Communication Platform

Complete automation for deploying WireGuard VPN, Jitsi Meet, Matrix Synapse, RouteMaker, and SMTP Mail Server on Hetzner Cloud.

## 📁 Repository Structure

```
.
├── .github/workflows/
│   └── deploy.yml                  # GitHub Actions CI/CD pipeline
├── ansible/
│   ├── ansible.cfg                 # Ansible configuration
│   ├── inventory.ini               # Server inventory template
│   ├── playbook.yml                # Main server configuration playbook
│   ├── tasks/
│   │   ├── backup.yml              # Backup configuration
│   │   ├── directories.yml         # Service directories setup
│   │   ├── matrix.yml              # Matrix Synapse configuration
│   │   ├── routemaker.yml          # RouteMaker deployment
│   │   ├── service-configs.yml     # Service-specific configs
│   │   ├── services.yml            # Docker Compose deployment
│   │   ├── smtp.yml                # SMTP mail server setup
│   │   ├── system-setup.yml        # System packages & Docker
│   │   ├── traefik.yml             # Traefik reverse proxy
│   │   └── wireguard.yml           # WireGuard VPN setup
│   └── templates/
│       ├── docker-compose.yml.j2   # Docker Compose template
│       ├── element-config.json.j2  # Element Web configuration
│       ├── traefik.toml.j2         # Traefik configuration
│       └── wireguard-dynamic.yml.j2 # WireGuard config
├── docs/
│   ├── branch-protection.md        # Guide: Branch protection rules
│   ├── create-new-ssh-key.md       # Guide: Create SSH keys
│   ├── DOMAIN_SETUP.md             # Guide: DNS and domain setup
│   ├── ELEMENT_CALL_SETUP.md       # Guide: Element Call integration
│   ├── FEDERATION_SETUP.md         # Guide: Matrix federation
│   ├── FORMATTERS.md               # Guide: Code formatters
│   ├── GITHUB_SECRETS.md           # Guide: GitHub secrets
│   ├── github-secrets-setup.md     # Guide: Secrets configuration
│   ├── LOCAL_TESTING.md            # Guide: Local development
│   ├── ROUTEMAKER_GUIDE.md         # Guide: RouteMaker usage
│   ├── secrets-update.md           # Guide: Update secrets
│   ├── SMTP_GUIDE.md               # Guide: SMTP server setup
│   ├── SMTP_QUICK_REFERENCE.md     # Quick ref: SMTP commands
│   ├── SPF_RECORDS_GUIDE.md        # Guide: Email authentication
│   ├── ssh-key-setup.md            # Guide: SSH key management
│   ├── terraform-cloud-setup.md    # Guide: Terraform Cloud
│   ├── TROUBLESHOOTING.md          # Guide: Common issues
│   ├── WIREGUARD_UI_FIX.md         # Guide: WireGuard UI fixes
│   └── workspace-execution-mode.md # Guide: Terraform workspace
├── routemaker/
│   ├── Dockerfile                  # RouteMaker container image
│   ├── server.js                   # RouteMaker backend server
│   ├── manage-users.js             # User management CLI
│   ├── package.json                # Node.js dependencies
│   ├── public/                     # Frontend assets
│   │   ├── index.html
│   │   ├── app.js
│   │   ├── style.css
│   │   └── lib/leaflet/            # Leaflet mapping library
│   └── data/                       # SQLite database storage
├── scripts/
│   ├── check-syntax.sh             # Validate code syntax
│   ├── create-ssh-key.sh           # Generate SSH keys
│   ├── format-all.sh               # Format all code
│   ├── get-ssh-key-id.sh           # Get SSH key IDs
│   ├── health-check.sh             # Service health checks
│   ├── pre-push-check.sh           # Pre-push validation
│   ├── routemaker-dev.sh           # RouteMaker development
│   ├── routemaker-users.sh         # Manage RouteMaker users
│   ├── setup-local.sh              # Local environment setup
│   ├── setup-smtp.sh               # SMTP server setup helper
│   └── setup-terraform-cloud.sh    # Terraform Cloud setup
├── terraform/
│   ├── .gitignore                  # Terraform ignore rules
│   ├── main.tf                     # Infrastructure configuration
│   └── terraform.tfvars.example    # Variable template
├── DEPLOYMENT.md                   # Deployment guide
├── HETZNER_DNS_MIGRATION.md        # DNS migration guide
├── JITSI_GUIDE.md                  # Jitsi Meet setup guide
├── MATRIX_GUIDE.md                 # Matrix Synapse guide
├── QUICKSTART_LOCAL.md             # Local testing quickstart
├── QUICKSTART.md                   # Production quickstart
├── README.md                       # Main documentation
├── STRUCTURE.md                    # This file
└── WIREGUARD_GUIDE.md              # WireGuard VPN guide
```

## 🚀 Quick Start

See [README.md](README.md) for complete setup instructions.

## 📚 Documentation

### Service Guides
- **[Main Guide](README.md)** - Complete setup and deployment
- **[WireGuard VPN](WIREGUARD_GUIDE.md)** - VPN setup for all platforms
- **[Jitsi Meet](JITSI_GUIDE.md)** - Video conferencing configuration
- **[Matrix Synapse](MATRIX_GUIDE.md)** - Messaging server setup
- **[SMTP Mail Server](docs/SMTP_GUIDE.md)** - Email server configuration
- **[RouteMaker](docs/ROUTEMAKER_GUIDE.md)** - Collaborative mapping app

### Setup Guides
- **[GitHub Secrets](docs/GITHUB_SECRETS.md)** - CI/CD configuration
- **[Domain Setup](docs/DOMAIN_SETUP.md)** - DNS configuration
- **[SPF Records](docs/SPF_RECORDS_GUIDE.md)** - Email authentication
- **[SSH Keys](docs/ssh-key-setup.md)** - SSH key management
- **[Local Testing](docs/LOCAL_TESTING.md)** - Local development

### Reference
- **[Deployment](DEPLOYMENT.md)** - CI/CD pipeline details
- **[Quickstart](QUICKSTART.md)** - Rapid deployment guide
- **[Local Quickstart](QUICKSTART_LOCAL.md)** - 3-step local setup
- **[SMTP Quick Ref](docs/SMTP_QUICK_REFERENCE.md)** - SMTP commands
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues

## 🛠️ Helper Scripts

### Infrastructure
- `scripts/create-ssh-key.sh` - Interactive SSH key generator
- `scripts/get-ssh-key-id.sh` - Get SSH key IDs from Hetzner
- `scripts/setup-terraform-cloud.sh` - Configure Terraform Cloud

### Services
- `scripts/setup-smtp.sh` - SMTP server setup wizard
- `scripts/routemaker-users.sh` - Manage RouteMaker users
- `scripts/routemaker-dev.sh` - RouteMaker development server

### Development
- `scripts/setup-local.sh` - Local environment setup
- `scripts/health-check.sh` - Service health checks
- `scripts/format-all.sh` - Format all code
- `scripts/check-syntax.sh` - Validate code syntax
- `scripts/pre-push-check.sh` - Pre-push validation

## ⚙️ Technology Stack

### Infrastructure
- **Cloud Provider**: Hetzner Cloud
- **Infrastructure as Code**: Terraform
- **Configuration Management**: Ansible
- **CI/CD**: GitHub Actions
- **Containerization**: Docker + Docker Compose

### Services
- **Reverse Proxy**: Traefik v2.11 with Let's Encrypt
- **VPN**: WireGuard + WireGuard UI v0.6.2
- **Video Conferencing**: Jitsi Meet (Web, Prosody, Jicofo, JVB)
- **Messaging**: Matrix Synapse + PostgreSQL 15
- **Web Client**: Element Web
- **Email**: docker-mailserver (Postfix + SPF/DKIM/DMARC)
- **Mapping**: RouteMaker (Node.js + Leaflet)

### Security
- **SSL/TLS**: Automatic HTTPS with Let's Encrypt
- **Email Auth**: SPF, DKIM, DMARC
- **Firewall**: Hetzner Cloud Firewall
- **VPN**: WireGuard encryption
- **Fail2ban**: Brute force protection (SMTP)

## 📦 Docker Services

The deployment includes:
- `traefik` - Reverse proxy and SSL termination
- `wireguard-ui` - VPN management interface
- `jitsi-web` - Jitsi web frontend
- `jitsi-prosody` - XMPP server
- `jitsi-jicofo` - Conference focus
- `jitsi-jvb` - Video bridge
- `matrix-synapse` - Matrix homeserver
- `matrix-postgres` - PostgreSQL database
- `element-web` - Matrix web client
- `mailserver` - SMTP mail server
- `routemaker` - Collaborative mapping app
- `well-known` - Matrix federation support

## 🔥 Firewall Rules

Automatically configured in Terraform:
- Port 22 (TCP) - SSH
- Port 25 (TCP) - SMTP
- Port 80 (TCP) - HTTP (redirects to HTTPS)
- Port 443 (TCP) - HTTPS (all web services)
- Port 465 (TCP) - SMTPS (SSL/TLS)
- Port 587 (TCP) - SMTP Submission (STARTTLS)
- Port 8080 (TCP) - Traefik dashboard
- Port 8448 (TCP) - Matrix federation
- Port 10000 (UDP) - Jitsi video bridge
- Port 51820 (UDP) - WireGuard VPN

## 🌐 DNS Records

Automatically managed by Hetzner DNS:
- `yourdomain.com` - Main domain
- `vpn.yourdomain.com` - WireGuard UI
- `meet.yourdomain.com` - Jitsi Meet
- `matrix.yourdomain.com` - Matrix homeserver
- `chat.yourdomain.com` - Element Web
- `maker.yourdomain.com` - RouteMaker
- `mail.yourdomain.com` - SMTP server

Additional manual DNS records for email:
- MX record - Mail exchange
- SPF record - Sender authentication
- DKIM record - Email signing
- DMARC record - Email policy

## 🔄 CI/CD Workflow

1. **Trigger**: Push to main branch or manual workflow dispatch
2. **Terraform**: Create/update infrastructure on Hetzner Cloud
3. **Ansible**: Configure server and deploy all services
4. **Validation**: Health checks for all services
5. **DNS**: Automatic DNS record creation
6. **SSL**: Automatic certificate generation via Let's Encrypt

## 📊 Service URLs

After deployment, all services are accessible via HTTPS:

- **Traefik Dashboard**: `https://yourdomain.com:8080/dashboard/`
- **WireGuard UI**: `https://vpn.yourdomain.com`
- **Jitsi Meet**: `https://meet.yourdomain.com`
- **Matrix Synapse**: `https://matrix.yourdomain.com`
- **Element Web**: `https://chat.yourdomain.com`
- **RouteMaker**: `https://maker.yourdomain.com`
- **SMTP Server**: `mail.yourdomain.com:587` (not web-accessible)

## 🎯 Use Cases

### Personal/Small Team Communication Platform
- Secure video calls with Jitsi Meet
- Private messaging with Matrix/Element
- Secure remote access via WireGuard VPN
- Email for password resets and notifications

### Route Planning & Collaboration
- Create and share routes with RouteMaker
- Real-time collaboration features
- Export routes in multiple formats

### Self-Hosted Infrastructure
- Full control over your data
- No third-party dependencies
- Customizable to your needs
- Cost-effective (~€10/month for CX23)

## 💡 Development Workflow

### Local Testing
```bash
# Setup local environment
./scripts/setup-local.sh

# Check syntax
./scripts/check-syntax.sh

# Format code
./scripts/format-all.sh

# Run local deployment
docker-compose -f docker-compose.local.yml up
```

### Service Management
```bash
# Add SMTP email account
./scripts/setup-smtp.sh

# Manage RouteMaker users
./scripts/routemaker-users.sh

# Health check all services
./scripts/health-check.sh
```
