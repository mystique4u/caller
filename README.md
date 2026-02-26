# VPN & Services Server# WireGuard VPN on Hetzner Cloud



Fully automated deployment of WireGuard VPN, Galène video conferencing, and Traefik reverse proxy on Hetzner Cloud using Terraform and Ansible.Automated deployment of a WireGuard VPN server on Hetzner Cloud using Terraform, Ansible, and GitHub Actions.



## 🚀 Features## 🎯 Overview



- **WireGuard VPN** with Web UI for easy client managementThis project automates the deployment of a WireGuard VPN server using:

- **Galène** - Lightweight video conferencing server  - **Terraform**: Infrastructure provisioning on Hetzner Cloud

- **Traefik** - Modern reverse proxy with automatic routing- **Ansible**: Server configuration and management

- **Docker-based** - All services run in containers- **GitHub Actions**: CI/CD pipeline for automated deployment

- **Fully automated** - Zero manual configuration needed- **WireGuard Image**: Pre-configured Hetzner image with WireGuard UI

- **IP-based access** - Works out of the box without domain setup

## 📋 Prerequisites

## 📋 Services & Access

### Required Accounts & Tools

After deployment, access your services at:- Hetzner Cloud account ([sign up here](https://www.hetzner.com/cloud))

- GitHub account (for Actions)

| Service | URL | Default Credentials |- Domain name (optional but recommended for HTTPS)

|---------|-----|-------------------|

| Traefik Dashboard | `http://YOUR_IP:8080/dashboard/` | No auth |### Local Development Tools

| WireGuard UI | `http://YOUR_IP/wireguard` | `admin` / `admin` |- [Terraform](https://www.terraform.io/downloads) >= 1.6.0

| Galène Video | `http://YOUR_IP/galene` | Room: `public`, Password: `admin` |- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) >= 2.14

- SSH key pair

## 🚦 Quick Start

## 🚀 Quick Start

1. Push to `main` branch - automatic deployment starts

2. Wait ~5 minutes for completion### 1. Initial Setup

3. Access services using your server IP

#### a) Create SSH Keys in Hetzner Cloud

## 📖 Full Documentation1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/)

2. Navigate to **Security** → **SSH Keys**

See detailed guides in `/docs`:3. Add your SSH public key

- [Branch Protection Setup](docs/branch-protection.md)4. Note the SSH key ID (you'll need this)

- [Terraform Cloud Setup](docs/terraform-cloud-setup.md)

- [GitHub Secrets Configuration](docs/github-secrets-setup.md)#### b) Create API Token

1. In Hetzner Console, go to **Security** → **API Tokens**

## 🔧 Prerequisites2. Generate a new token with **Read & Write** permissions

3. Save it securely (you'll need this for GitHub Secrets)

- Hetzner Cloud account with API token

- Terraform Cloud account (free tier)#### c) Create Firewall (Optional but Recommended)

- GitHub repository with Actions enabled1. Go to **Firewalls** in Hetzner Console

- SSH key pair for server access2. Create a new firewall with these rules:

   - **Inbound:**

## 🛠️ Manual Redeploy     - SSH: TCP port 22 (from your IP or 0.0.0.0/0)

     - HTTPS: TCP port 443 (from 0.0.0.0/0)

1. Go to **Actions** → **Destroy and Redeploy**     - WireGuard: UDP port 51820 (from 0.0.0.0/0)

2. Click **Run workflow**   - **Outbound:** Allow all

3. Type `DESTROY` to confirm3. Note the firewall name

4. Wait for completion

### 2. Configure GitHub Secrets

## ⚠️ Security Notes

Add these secrets to your GitHub repository (**Settings** → **Secrets and variables** → **Actions**):

- Change default passwords immediately after deployment

- Services use HTTP (not HTTPS) on IP addresses| Secret Name | Description | Example |

- Configure a domain + Let's Encrypt for production use|-------------|-------------|---------|

| `HCLOUD_TOKEN` | Your Hetzner Cloud API token | `your-api-token-here` |

## 📝 Infrastructure| `FIREWALL_NAME` | Name of your Hetzner firewall | `default-firewall` |

| `SSH_KEY_IDS` | JSON array of SSH key IDs | `[123456]` |

- **OS**: Clean Ubuntu 24.04| `SSH_PRIVATE_KEY` | Your SSH private key (for Ansible) | `-----BEGIN OPENSSH PRIVATE KEY-----...` |

- **Instance**: Hetzner CX22 (2 vCPU, 4GB RAM)| `WIREGUARD_DOMAIN` | Your domain name (optional) | `vpn.example.com` |

- **Location**: Nuremberg (nbg1)| `WIREGUARD_ADMIN_USER` | Admin username for UI (optional) | `admin` |

- **Firewall**: Ports 22, 80, 8080, 51820| `WIREGUARD_ADMIN_PASSWORD` | Admin password (optional) | Leave empty for interactive setup |



## 🤝 Contributing### 3. Deploy via GitHub Actions



Issues and PRs welcome!#### Automatic Deployment

1. Push to the `main` branch:
   ```bash
   git add .
   git commit -m "Initial WireGuard setup"
   git push origin main
   ```

2. GitHub Actions will automatically:
   - Run Terraform to create the server
   - Configure the server with Ansible
   - Output the server IP address

#### Manual Deployment
1. Go to **Actions** tab in your repository
2. Select **Deploy WireGuard VPN to Hetzner Cloud**
3. Click **Run workflow**
4. Choose action: `apply`, `plan`, or `destroy`

### 4. Initial Server Configuration

After deployment, SSH into your server to complete the WireGuard setup:

```bash
# SSH into the server (use the IP from GitHub Actions output)
ssh root@YOUR_SERVER_IP

# The WireGuard setup script will guide you through:
# 1. Setting up domain name (if you have one)
# 2. Creating admin credentials
# 3. Configuring Let's Encrypt SSL
```

### 5. Access WireGuard UI

After setup is complete:
- **URL**: `https://YOUR_SERVER_IP` or `https://your-domain.com`
- **Login**: Use credentials you set during initial setup
- **Create clients**: Click "New Client" in the UI
- **Apply config**: Always click "Apply Config" after changes

## 📁 Project Structure

```
.
├── .github/
│   └── workflows/
│       └── deploy.yml          # GitHub Actions workflow
├── ansible/
│   ├── ansible.cfg             # Ansible configuration
│   ├── inventory.ini           # Server inventory
│   └── playbook.yml            # Configuration playbook
├── terraform/
│   ├── .gitignore              # Terraform gitignore
│   ├── main.tf                 # Main Terraform config
│   └── terraform.tfvars.example # Example variables
└── README.md
```

## 🛠️ Local Deployment (Alternative)

If you prefer to deploy manually without GitHub Actions:

### 1. Configure Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
nano terraform.tfvars
```

### 2. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply changes
terraform apply

# Get the server IP
terraform output public_ip
```

### 3. Configure with Ansible

```bash
cd ../ansible

# Update inventory with your server IP
nano inventory.ini

# Run the playbook
ansible-playbook -i inventory.ini playbook.yml
```

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