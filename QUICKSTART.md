# Quick Update Required

## Update GitHub Secret

You only need to update **ONE** secret:

### FIREWALL_NAME

**Old value**: `default-firewall`  
**New value**: `vpn-services-firewall`

### How to Update

1. Go to: https://github.com/mystique4u/caller/settings/secrets/actions
2. Click on `FIREWALL_NAME`
3. Click "Update secret"
4. Change value to: `vpn-services-firewall`
5. Click "Update secret"

## What Changed?

✅ **Firewall is now managed by Terraform**

- No manual `hcloud firewall` commands needed
- Firewall created automatically during deployment
- Can be destroyed and recreated via GitHub Actions

✅ **Upgraded to CX23**

- 8GB RAM (was 4GB)
- Better performance for video conferencing

✅ **Galène video conferencing added**

- Docker-based installation
- Follows official Galène documentation
- Access at `http://YOUR_IP/galene`

## Deploy

After updating the secret:

1. Go to **Actions** → **"Destroy and Redeploy"**
2. Click **"Run workflow"**
3. Type `DESTROY`
4. Wait ~10 minutes

You'll get a fresh server with:

- WireGuard VPN + UI
- Galène video conferencing
- Traefik reverse proxy
- All on CX23 with 8GB RAM
