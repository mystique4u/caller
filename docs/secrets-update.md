# GitHub Secrets Configuration Update

## Required Secrets

All configuration is now stored in GitHub Secrets. No manual firewall setup needed!

### 1. TF_API_TOKEN

**Terraform Cloud API Token** (for state storage)

- Go to: https://app.terraform.io/app/settings/tokens
- Create token
- Add to GitHub Secrets

### 2. HCLOUD_TOKEN

**Hetzner Cloud API Token**

- Go to: https://console.hetzner.cloud/
- Select your project
- Go to Security → API Tokens
- Generate new token
- Add to GitHub Secrets

### 3. FIREWALL_NAME

**Firewall Name** (managed by Terraform)

- Value: `vpn-services-firewall`
- This is now created automatically by Terraform!

### 4. SSH_KEY_IDS

**SSH Key IDs as JSON array**

- Format: `[108153935]`
- Your current SSH key ID: `108153935`

### 5. SSH_PRIVATE_KEY

**Private SSH Key for Ansible**

- Content of `~/.ssh/hetzner-wireguard` file
- Include full key including headers

## What Changed?

### ✅ Automated Firewall Management

- Firewall is now created and managed by Terraform
- No manual `hcloud firewall create` commands needed
- All rules defined in `terraform/main.tf`:
  - Port 22 (SSH)
  - Port 80 (HTTP - Traefik)
  - Port 8080 (Traefik Dashboard)
  - Port 51820 (WireGuard UDP)

### ✅ CX23 Instance Type

- Changed from CX22 to CX23
- 2 vCPU, 8GB RAM (previously 4GB)
- Better performance for video conferencing

### ✅ All Configuration in GitHub Secrets

- No hardcoded values
- Easy to rotate credentials
- Secure storage

## Updating Secrets

Go to your repository:

```
https://github.com/mystique4u/caller/settings/secrets/actions
```

Click "New repository secret" for each value above.

## Verification

After updating secrets, trigger deployment:

1. Go to Actions tab
2. Select "Destroy and Redeploy" workflow
3. Run workflow with "DESTROY" confirmation
4. Wait for completion (~10 minutes)

## Notes

- Old firewall "default-firewall" is no longer used
- New firewall "vpn-services-firewall" is created automatically
- Can be destroyed and recreated via GitHub Actions
