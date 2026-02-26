# ✅ Pre-Deployment Checklist

## Terraform Syntax: PASSED ✅

```bash
terraform fmt -check -diff
# Output: Clean (no errors)
```

Configuration is valid and properly formatted!

---

## Required GitHub Secrets

Configure these 5 secrets before deploying:

### Secret #1: TF_API_TOKEN
- **Purpose**: Terraform Cloud authentication
- **Get from**: https://app.terraform.io/app/settings/tokens
- **Format**: Long alphanumeric string
- **Status**: ⚠️ UPDATE REQUIRED

### Secret #2: HCLOUD_TOKEN  
- **Purpose**: Hetzner Cloud API access
- **Get from**: https://console.hetzner.cloud/ → Security → API Tokens
- **Format**: Long alphanumeric string
- **Permissions**: Read & Write
- **Status**: ⚠️ CHECK IF CURRENT

### Secret #3: FIREWALL_NAME
- **Purpose**: Firewall identifier (auto-created)
- **Value**: `vpn-services-firewall`
- **Status**: ⚠️ MUST UPDATE from `default-firewall`

### Secret #4: SSH_KEY_IDS
- **Purpose**: SSH key for server access
- **Value**: `[108153935]`
- **Format**: JSON array
- **Status**: ⚠️ CHECK IF CURRENT

### Secret #5: SSH_PRIVATE_KEY
- **Purpose**: Ansible authentication
- **Get from**: `cat ~/.ssh/hetzner-wireguard`
- **Format**: Full private key with headers
- **Status**: ⚠️ CHECK IF CURRENT

---

## Quick Setup Commands

### Check your SSH key ID:
```bash
hcloud ssh-key list
```

### View your private key:
```bash
cat ~/.ssh/hetzner-wireguard
```

---

## What's Changed

✅ **Firewall automated** - Created by Terraform (no manual setup)  
✅ **CX23 instance** - Upgraded to 8GB RAM  
✅ **All config in secrets** - No hardcoded values  
✅ **Terraform validated** - Syntax check passed  

---

## Ready to Deploy?

1. **Update GitHub Secrets**: See [docs/GITHUB_SECRETS.md](docs/GITHUB_SECRETS.md)
2. **Trigger Workflow**: Actions → "Destroy and Redeploy" → Type `DESTROY`
3. **Wait ~10 minutes**: Monitor deployment progress
4. **Access services**: Use new server IP

---

## After Deployment

Services will be available at:

- **WireGuard UI**: `http://YOUR_IP/wireguard` (admin/admin)
- **Galène Video**: `http://YOUR_IP/galene` (room: public)  
- **Traefik Dashboard**: `http://YOUR_IP:8080/dashboard/`

**⚠️ Change default passwords immediately!**

---

## Infrastructure Details

```yaml
Provider: Hetzner Cloud
Instance: CX23 (2 vCPU, 8GB RAM)
OS: Ubuntu 24.04 (clean base)
Location: Nuremberg (nbg1)
Firewall: Auto-managed via Terraform
  - Port 22 (SSH)
  - Port 80 (HTTP/Traefik)
  - Port 8080 (Traefik Dashboard)
  - Port 51820 (WireGuard UDP)
```

---

## Documentation

📖 [Full Secrets Guide](docs/GITHUB_SECRETS.md)  
📖 [Quick Update Guide](QUICKSTART.md)  
📖 [Main README](README.md)
