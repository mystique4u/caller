# WireGuard VPN Infrastructure

Complete automation for deploying WireGuard VPN on Hetzner Cloud.

## 📁 Repository Structure

```
.
├── .github/workflows/
│   └── deploy.yml              # GitHub Actions CI/CD pipeline
├── ansible/
│   ├── ansible.cfg             # Ansible configuration
│   ├── inventory.ini           # Server inventory template
│   └── playbook.yml            # Server configuration playbook
├── docs/
│   ├── create-new-ssh-key.md   # Guide: Create SSH keys
│   ├── github-secrets-setup.md # Guide: Configure GitHub secrets
│   └── ssh-key-setup.md        # Guide: SSH key management
├── scripts/
│   ├── create-ssh-key.sh       # Helper: Generate SSH keys
│   └── get-ssh-key-id.sh       # Helper: Get SSH key IDs
├── terraform/
│   ├── .gitignore              # Terraform ignore rules
│   ├── main.tf                 # Infrastructure configuration
│   └── terraform.tfvars.example # Variable template
└── README.md                   # Main documentation
```

## 🚀 Quick Start

See [README.md](README.md) for complete setup instructions.

## 📚 Documentation

- **[Main Guide](README.md)** - Complete setup and deployment
- **[SSH Key Setup](docs/ssh-key-setup.md)** - SSH key management
- **[GitHub Secrets](docs/github-secrets-setup.md)** - CI/CD configuration
- **[Create SSH Key](docs/create-new-ssh-key.md)** - Generate new keys

## 🛠️ Helper Scripts

- `scripts/create-ssh-key.sh` - Interactive SSH key generator
- `scripts/get-ssh-key-id.sh` - Get SSH key IDs from Hetzner

## ⚙️ Technology Stack

- **Infrastructure**: Terraform + Hetzner Cloud
- **Configuration**: Ansible
- **CI/CD**: GitHub Actions
- **VPN**: WireGuard + WireGuard UI
