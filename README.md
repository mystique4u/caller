# VPN & Services Server# VPN & Services Server# WireGuard VPN on Hetzner Cloud



Fully automated deployment of **WireGuard VPN**, **Galène video conferencing**, and **Traefik reverse proxy** on Hetzner Cloud.



## 🚀 FeaturesFully automated deployment of WireGuard VPN, Galène video conferencing, and Traefik reverse proxy on Hetzner Cloud using Terraform and Ansible.Automated deployment of a WireGuard VPN server on Hetzner Cloud using Terraform, Ansible, and GitHub Actions.



- ✅ **Fully Automated** - Zero manual configuration

- ✅ **WireGuard VPN** with Web UI for client management

- ✅ **Galène** - Lightweight video conferencing## 🚀 Features## 🎯 Overview

- ✅ **Traefik** - Modern reverse proxy

- ✅ **Docker-based** - All services containerized

- ✅ **Firewall Automated** - Created and managed by Terraform

- ✅ **IP-based Access** - Works out of the box- **WireGuard VPN** with Web UI for easy client managementThis project automates the deployment of a WireGuard VPN server using:



## 📋 Access Your Services- **Galène** - Lightweight video conferencing server  - **Terraform**: Infrastructure provisioning on Hetzner Cloud



| Service | URL | Credentials |- **Traefik** - Modern reverse proxy with automatic routing- **Ansible**: Server configuration and management

|---------|-----|-------------|

| **Traefik Dashboard** | `http://YOUR_IP:8080/dashboard/` | No auth |- **Docker-based** - All services run in containers- **GitHub Actions**: CI/CD pipeline for automated deployment

| **WireGuard UI** | `http://YOUR_IP/wireguard` | `admin` / `admin` |

| **Galène Video** | `http://YOUR_IP/galene` | Room: `public`, Pass: `admin` |- **Fully automated** - Zero manual configuration needed- **WireGuard Image**: Pre-configured Hetzner image with WireGuard UI



## ⚡ Quick Start- **IP-based access** - Works out of the box without domain setup



1. **Configure GitHub Secrets** (see below)## 📋 Prerequisites

2. **Push to main** or trigger "Destroy and Redeploy" workflow

3. **Wait ~10 minutes** for deployment## 📋 Services & Access

4. **Access services** using your server IP

5. **Change default passwords** immediately!### Required Accounts & Tools



## 🔐 Required GitHub SecretsAfter deployment, access your services at:- Hetzner Cloud account ([sign up here](https://www.hetzner.com/cloud))



Go to: `https://github.com/YOUR_USERNAME/caller/settings/secrets/actions`- GitHub account (for Actions)



| Secret Name | Description | Example Value || Service | URL | Default Credentials |- Domain name (optional but recommended for HTTPS)

|-------------|-------------|---------------|

| `TF_API_TOKEN` | Terraform Cloud API token | `***` ||---------|-----|-------------------|

| `HCLOUD_TOKEN` | Hetzner Cloud API token | `***` |

| `FIREWALL_NAME` | Firewall name (auto-created) | `vpn-services-firewall` || Traefik Dashboard | `http://YOUR_IP:8080/dashboard/` | No auth |### Local Development Tools

| `SSH_KEY_IDS` | SSH key IDs as JSON array | `[108153935]` |

| `SSH_PRIVATE_KEY` | Private SSH key for Ansible | Full key content || WireGuard UI | `http://YOUR_IP/wireguard` | `admin` / `admin` |- [Terraform](https://www.terraform.io/downloads) >= 1.6.0



**See detailed setup**: [`docs/secrets-update.md`](docs/secrets-update.md)| Galène Video | `http://YOUR_IP/galene` | Room: `public`, Password: `admin` |- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) >= 2.14



## 🏗️ Infrastructure- SSH key pair



- **Provider**: Hetzner Cloud## 🚦 Quick Start

- **OS**: Clean Ubuntu 24.04  

- **Instance**: CX23 (2 vCPU, 8GB RAM)## 🚀 Quick Start

- **Location**: Nuremberg (nbg1)

- **Firewall**: Auto-managed (SSH, HTTP, Traefik, WireGuard)1. Push to `main` branch - automatic deployment starts



## 🔧 What Gets Installed2. Wait ~5 minutes for completion### 1. Initial Setup



### System Packages3. Access services using your server IP

- WireGuard & tools

- Docker & Docker Compose#### a) Create SSH Keys in Hetzner Cloud

- Essential utilities (htop, vim, git, etc.)

## 📖 Full Documentation1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/)

### Docker Services

- **Traefik v2.11** - Reverse proxy & routing2. Navigate to **Security** → **SSH Keys**

- **WireGuard UI v0.6.2** - VPN management interface

- **Galène** - Video conferencing (via Docker)See detailed guides in `/docs`:3. Add your SSH public key



### Network Configuration- [Branch Protection Setup](docs/branch-protection.md)4. Note the SSH key ID (you'll need this)

- IP forwarding enabled (IPv4 & IPv6)

- WireGuard interface: `wg0` (10.0.0.1/24)- [Terraform Cloud Setup](docs/terraform-cloud-setup.md)

- NAT/Masquerading for VPN clients

- [GitHub Secrets Configuration](docs/github-secrets-setup.md)#### b) Create API Token

### Firewall Rules (Auto-created)

```1. In Hetzner Console, go to **Security** → **API Tokens**

Port 22    (TCP) - SSH

Port 80    (TCP) - HTTP via Traefik## 🔧 Prerequisites2. Generate a new token with **Read & Write** permissions

Port 8080  (TCP) - Traefik dashboard

Port 51820 (UDP) - WireGuard VPN3. Save it securely (you'll need this for GitHub Secrets)

```

- Hetzner Cloud account with API token

## 🚦 Deployment Options

- Terraform Cloud account (free tier)#### c) Create Firewall (Optional but Recommended)

### Automatic (on Push)

```bash- GitHub repository with Actions enabled1. Go to **Firewalls** in Hetzner Console

git push origin main

```- SSH key pair for server access2. Create a new firewall with these rules:



### Manual Redeploy   - **Inbound:**

1. Go to **Actions** → **"Destroy and Redeploy"**

2. Click **"Run workflow"**## 🛠️ Manual Redeploy     - SSH: TCP port 22 (from your IP or 0.0.0.0/0)

3. Type `DESTROY` to confirm

4. Wait for completion     - HTTPS: TCP port 443 (from 0.0.0.0/0)



## 📖 Usage Guides1. Go to **Actions** → **Destroy and Redeploy**     - WireGuard: UDP port 51820 (from 0.0.0.0/0)



### WireGuard VPN2. Click **Run workflow**   - **Outbound:** Allow all



1. Access: `http://YOUR_IP/wireguard`3. Type `DESTROY` to confirm3. Note the firewall name

2. Login: `admin` / `admin`

3. **Change password immediately!**4. Wait for completion

4. Create clients:

   - Click "New Client"### 2. Configure GitHub Secrets

   - Enter name

   - Download QR code or config file## ⚠️ Security Notes

5. Import into WireGuard app

Add these secrets to your GitHub repository (**Settings** → **Secrets and variables** → **Actions**):

### Galène Video Conferencing

- Change default passwords immediately after deployment

1. Access: `http://YOUR_IP/galene`

2. Join room: `public`- Services use HTTP (not HTTPS) on IP addresses| Secret Name | Description | Example |

3. Operator password: `admin`

4. Share room URL with participants- Configure a domain + Let's Encrypt for production use|-------------|-------------|---------|



### Traefik Dashboard| `HCLOUD_TOKEN` | Your Hetzner Cloud API token | `your-api-token-here` |



1. Access: `http://YOUR_IP:8080/dashboard/`## 📝 Infrastructure| `FIREWALL_NAME` | Name of your Hetzner firewall | `default-firewall` |

2. Monitor service health

3. View routing rules| `SSH_KEY_IDS` | JSON array of SSH key IDs | `[123456]` |

4. Check real-time metrics

- **OS**: Clean Ubuntu 24.04| `SSH_PRIVATE_KEY` | Your SSH private key (for Ansible) | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

## 🗂️ Server Directory Structure

- **Instance**: Hetzner CX22 (2 vCPU, 4GB RAM)| `WIREGUARD_DOMAIN` | Your domain name (optional) | `vpn.example.com` |

```

/opt/services/- **Location**: Nuremberg (nbg1)| `WIREGUARD_ADMIN_USER` | Admin username for UI (optional) | `admin` |

├── docker-compose.yml     # All service definitions

├── wireguard-ui/          # WireGuard UI database- **Firewall**: Ports 22, 80, 8080, 51820| `WIREGUARD_ADMIN_PASSWORD` | Admin password (optional) | Leave empty for interactive setup |

├── galene/

│   ├── groups/            # Room configurations

│   └── data/              # Runtime data

└── traefik/## 🤝 Contributing### 3. Deploy via GitHub Actions

    ├── traefik.toml       # Static config

    └── dynamic/           # Dynamic routing



/etc/wireguard/Issues and PRs welcome!#### Automatic Deployment

└── wg0.conf              # WireGuard server config

```1. Push to the `main` branch:

   ```bash

## 🛠️ Management Commands   git add .

   git commit -m "Initial WireGuard setup"

### SSH Access   git push origin main

```bash   ```

ssh -i ~/.ssh/hetzner-wireguard root@YOUR_IP

```2. GitHub Actions will automatically:

   - Run Terraform to create the server

### View Logs   - Configure the server with Ansible

```bash   - Output the server IP address

cd /opt/services

docker compose logs -f [service_name]#### Manual Deployment

```1. Go to **Actions** tab in your repository

2. Select **Deploy WireGuard VPN to Hetzner Cloud**

### Restart Services3. Click **Run workflow**

```bash4. Choose action: `apply`, `plan`, or `destroy`

cd /opt/services

docker compose restart### 4. Initial Server Configuration

```

After deployment, SSH into your server to complete the WireGuard setup:

### Check WireGuard

```bash```bash

wg show# SSH into the server (use the IP from GitHub Actions output)

```ssh root@YOUR_SERVER_IP



### Update Services# The WireGuard setup script will guide you through:

```bash# 1. Setting up domain name (if you have one)

cd /opt/services# 2. Creating admin credentials

docker compose pull# 3. Configuring Let's Encrypt SSL

docker compose up -d```

```

### 5. Access WireGuard UI

## 🔒 Security Notes

After setup is complete:

- ⚠️ **Change all default passwords immediately!**- **URL**: `https://YOUR_SERVER_IP` or `https://your-domain.com`

- Services use HTTP (not HTTPS) on IP addresses- **Login**: Use credentials you set during initial setup

- For production: configure domain + Let's Encrypt- **Create clients**: Click "New Client" in the UI

- Backup `/opt/services/` and `/etc/wireguard/` regularly- **Apply config**: Always click "Apply Config" after changes

- Firewall automatically restricts access to required ports only

## 📁 Project Structure

## 🐛 Troubleshooting

```

### Services Not Accessible.

```bash├── .github/

docker ps  # Check running containers│   └── workflows/

docker logs traefik  # Check Traefik logs│       └── deploy.yml          # GitHub Actions workflow

```├── ansible/

│   ├── ansible.cfg             # Ansible configuration

### WireGuard Issues│   ├── inventory.ini           # Server inventory

```bash│   └── playbook.yml            # Configuration playbook

wg show  # Check WireGuard status├── terraform/

ip a show wg0  # Check interface│   ├── .gitignore              # Terraform gitignore

sysctl net.ipv4.ip_forward  # Verify IP forwarding│   ├── main.tf                 # Main Terraform config

```│   └── terraform.tfvars.example # Example variables

└── README.md

### Reset Everything```

```bash

cd /opt/services## 🛠️ Local Deployment (Alternative)

docker compose down -v

docker compose up -dIf you prefer to deploy manually without GitHub Actions:

```

### 1. Configure Terraform

## 📚 Documentation

```bash

- [Secrets Configuration Update](docs/secrets-update.md)cd terraform

- [Terraform Cloud Setup](docs/terraform-cloud-setup.md)cp terraform.tfvars.example terraform.tfvars

- [GitHub Secrets Setup](docs/github-secrets-setup.md)# Edit terraform.tfvars with your values

- [Branch Protection](docs/branch-protection.md)nano terraform.tfvars

```

## 🎯 Key Improvements

### 2. Deploy Infrastructure

### ✅ No Manual Firewall Setup

- Firewall automatically created by Terraform```bash

- All rules defined in code# Initialize Terraform

- Can be destroyed and recreatedterraform init



### ✅ Enhanced Performance# Review the plan

- CX23 instance (8GB RAM, was 4GB)terraform plan

- Better for video conferencing

- Handles more concurrent connections# Apply changes

terraform apply

### ✅ All Config in GitHub Secrets

- No hardcoded credentials# Get the server IP

- Easy credential rotationterraform output public_ip

- Secure storage```



### ✅ Galène Integration### 3. Configure with Ansible

- Official installation method followed

- Docker-based deployment```bash

- HTTP mode for IP-based accesscd ../ansible



## 🤝 Contributing# Update inventory with your server IP

nano inventory.ini

Issues and pull requests welcome!

# Run the playbook

## 📄 Licenseansible-playbook -i inventory.ini playbook.yml

```

MIT License - Use and modify freely.

## 🔧 Configuration

### Terraform Variables

Edit `terraform/terraform.tfvars`:

```hcl
hcloud_token   = "your-token"
firewall_name  = "default-firewall"
ssh_key_ids    = [123456]
domain_name    = "vpn.example.com"
```

### DNS Configuration

If using a domain:
1. Create an **A record** pointing to your server's IPv4
2. Create an **AAAA record** pointing to your server's IPv6 (optional)
3. Wait for DNS propagation (use [DNS Checker](https://dnschecker.org))

## 📱 Connecting Clients

### Mobile (iOS/Android)
1. Login to WireGuard UI
2. Click "New Client"
3. Enter client name
4. Click "Apply Config"
5. Click QR code icon
6. Scan with WireGuard mobile app

### Desktop (Windows/Mac/Linux)
1. Login to WireGuard UI
2. Click "New Client"
3. Enter client name
4. Click "Apply Config"
5. Download config file
6. Import to WireGuard desktop app

Download WireGuard apps: [wireguard.com/install](https://www.wireguard.com/install/)

## 🔒 Security Best Practices

1. **Firewall**: Always use a Hetzner firewall
2. **SSH Keys**: Disable password authentication
3. **Strong Password**: Use strong admin password for UI
4. **Regular Updates**: Keep the server updated:
   ```bash
   apt update && apt upgrade -y
   ```
5. **Limit Access**: Restrict SSH to your IP only
6. **Monitor Logs**: Check WireGuard logs regularly:
   ```bash
   journalctl -u wg-quick@wg0 -f
   ```

## 🔄 Updating WireGuard

### Update WireGuard and System Packages
```bash
ssh root@YOUR_SERVER_IP
apt update && apt upgrade -y
systemctl restart wg-quick@wg0
```

### Update WireGuard UI
```bash
# Download latest release
LATEST=$(curl -s https://api.github.com/repos/ngoduykhanh/wireguard-ui/releases/latest | grep "tag_name" | cut -d '"' -f 4)
wget https://github.com/ngoduykhanh/wireguard-ui/releases/download/${LATEST}/wireguard-ui-${LATEST}-linux-amd64.tar.gz
tar -xzf wireguard-ui-${LATEST}-linux-amd64.tar.gz
mv wireguard-ui /usr/local/bin/
systemctl restart wireguard-ui
```

### Update Caddy
```bash
wget https://github.com/caddyserver/caddy/releases/latest/download/caddy_*_linux_amd64.tar.gz
tar -C /usr/local/bin -xzf caddy_*_linux_amd64.tar.gz caddy
systemctl restart caddy
```

## 🧹 Cleanup

### Destroy via GitHub Actions
1. Go to **Actions** → **Run workflow**
2. Select action: `destroy`
3. Run workflow

### Destroy via Terraform
```bash
cd terraform
terraform destroy
```

## 📊 Monitoring

### Check WireGuard Status
```bash
ssh root@YOUR_SERVER_IP
wg show
```

### Check Services
```bash
systemctl status wg-quick@wg0
systemctl status wireguard-ui
systemctl status caddy
```

### View Logs
```bash
journalctl -u wg-quick@wg0 -f
journalctl -u wireguard-ui -f
journalctl -u caddy -f
```

## 🐛 Troubleshooting

### Can't Access WireGuard UI
1. Check if services are running:
   ```bash
   systemctl status wireguard-ui caddy
   ```
2. Verify firewall rules allow HTTPS (port 443)
3. Check DNS if using a domain

### WireGuard Not Working
1. Check WireGuard status:
   ```bash
   wg show
   ```
2. Verify port 51820 UDP is open in firewall
3. Check logs:
   ```bash
   journalctl -u wg-quick@wg0 -xe
   ```

### GitHub Actions Failing
1. Verify all secrets are set correctly
2. Check Terraform state in Hetzner backend
3. Review Action logs for specific errors

## 📚 Resources

- [Hetzner Cloud Docs](https://docs.hetzner.com/cloud/)
- [WireGuard Documentation](https://www.wireguard.com/)
- [WireGuard UI GitHub](https://github.com/ngoduykhanh/wireguard-ui)
- [Terraform Hetzner Provider](https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs)

## 📝 License

This project is provided as-is for educational purposes.

## 🤝 Contributing

Feel free to open issues or submit pull requests for improvements!

---

**Happy VPN-ing! 🚀🔒**