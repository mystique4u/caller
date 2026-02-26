# GitHub Secrets Configuration

## Required Secrets List

Configure these secrets in GitHub at:  
`https://github.com/mystique4u/caller/settings/secrets/actions`

---

## 1. TF_API_TOKEN

**Purpose**: Terraform Cloud authentication for remote state storage

**How to get it**:

1. Go to https://app.terraform.io/app/settings/tokens
2. Click "Create an API token"
3. Name it: `github-actions-caller`
4. Copy the token (shown once!)

**Value format**: `abcdefg...xyz` (long alphanumeric string)

**Example**: `TYBeJ4Gh8NKLMnoPQRsTUvWxYz1234567890aBcDeF`

---

## 2. HCLOUD_TOKEN

**Purpose**: Hetzner Cloud API access for creating infrastructure

**How to get it**:

1. Go to https://console.hetzner.cloud/
2. Select your project
3. Go to **Security** → **API Tokens**
4. Click "Generate API token"
5. Name it: `terraform-github-actions`
6. Set permissions: **Read & Write**
7. Copy the token

**Value format**: `abcdefghijklmnopqrstuvwxyz...` (long string)

**Example**: `A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T0`

**Note**: This token is used for both servers AND DNS management (integrated API)

---

## 3. DOMAIN_NAME

**Purpose**: Your custom domain for HTTPS access

**How to get it**:

1. Purchase a domain from any registrar (Namecheap, GoDaddy, etc.)
2. Use the domain without protocol or path

**Value format**: `example.com` (just the domain)

**Examples**: `mydomain.com` or `myvpn.net`

**Note**: Leave empty to use IP address only (HTTP). With domain, you get:

- `https://vpn.yourdomain.com` - WireGuard UI
- `https://meet.yourdomain.com` - Galène Video
- `https://yourdomain.com:8080/dashboard/` - Traefik Dashboard

---

## 4. EMAIL_ADDRESS

**Purpose**: Email for Let's Encrypt SSL certificate notifications

**Value format**: `your-email@example.com`

**Examples**: `admin@mydomain.com` or `you@gmail.com`

**Note**: Optional, defaults to `admin@yourdomain.com` if not set

---

## 5. FIREWALL_NAME

**Purpose**: Name for the firewall (auto-created by Terraform)

**Value**: `vpn-services-firewall`

**Note**: This firewall will be created automatically. No manual setup needed!

---

## 7. SSH_KEY_IDS

**Purpose**: SSH key IDs for server access (as JSON array)

**How to get it**:

1. Your current SSH key ID is: `108153935`
2. If you need to find it: `hcloud ssh-key list`

**Value format**: JSON array of numbers: `[108153935]`

**Example**: `[108153935]` or `[12345, 67890]` for multiple keys

**Important**: Must be valid JSON with square brackets!

---

## 8. SSH_PRIVATE_KEY

**Purpose**: Private SSH key for Ansible to configure the server

**How to get it**:

```bash
cat ~/.ssh/hetzner-wireguard
```

**Value format**: Full SSH private key including headers

**Example**:

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAABlwAAAAdzc2gtcn
...
(many lines)
...
-----END OPENSSH PRIVATE KEY-----
```

**Important**:

- Include BOTH header lines (`-----BEGIN...` and `-----END...`)
- Include ALL lines in between
- Do NOT add extra spaces or newlines

---

## Quick Reference Table

| Secret Name       | Type       | Example Value           | Required |
| ----------------- | ---------- | ----------------------- | -------- |
| `TF_API_TOKEN`    | String     | `TYBeJ4Gh8NK...`        | Yes      |
| `HCLOUD_TOKEN`    | String     | `A1B2C3D4E5F6...`       | Yes      |
| `DOMAIN_NAME`     | String     | `example.com`           | No\*     |
| `EMAIL_ADDRESS`   | String     | `admin@example.com`     | No       |
| `FIREWALL_NAME`   | String     | `vpn-services-firewall` | Yes      |
| `SSH_KEY_IDS`     | JSON Array | `[108153935]`           | Yes      |
| `SSH_PRIVATE_KEY` | Multi-line | `-----BEGIN OPENSSH...` | Yes      |

\* Required only if you want HTTPS with custom domain. Without domain, services use HTTP with IP address.

**Note**: The `HCLOUD_TOKEN` now manages both servers AND DNS (Hetzner unified the APIs).

---

## Two Deployment Modes

### Mode 1: IP Address Only (HTTP)

**Requires**: `TF_API_TOKEN`, `HCLOUD_TOKEN`, `FIREWALL_NAME`, `SSH_KEY_IDS`, `SSH_PRIVATE_KEY`

**Access**:

- WireGuard UI: `http://SERVER_IP/wireguard`
- Galène Video: `http://SERVER_IP/galene`
- Traefik Dashboard: `http://SERVER_IP:8080/dashboard/`

### Mode 2: Custom Domain (HTTPS)

**Requires**: All secrets from Mode 1 + `DOMAIN_NAME`, `EMAIL_ADDRESS`

**Access**:

- WireGuard UI: `https://vpn.yourdomain.com`
- Galène Video: `https://meet.yourdomain.com`
- Traefik Dashboard: `https://yourdomain.com:8080/dashboard/`

**DNS Setup**:  
DNS is automatically managed by Hetzner Cloud API. Update nameservers at your domain registrar to:

- `hydrogen.ns.hetzner.com`
- `oxygen.ns.hetzner.com`
- `helium.ns.hetzner.de`

---

## Verification Steps

After adding all secrets:

1. **Check secrets are set**:
   - Go to `https://github.com/mystique4u/caller/settings/secrets/actions`
   - Required: `TF_API_TOKEN`, `HCLOUD_TOKEN`, `FIREWALL_NAME`, `SSH_KEY_IDS`, `SSH_PRIVATE_KEY`
   - Optional: `DOMAIN_NAME`, `EMAIL_ADDRESS`

2. **Test deployment**:
   - Go to **Actions** tab
   - Run "Destroy and Redeploy" workflow
   - Type `DESTROY` to confirm
   - Wait for completion (~10-15 minutes)

3. **Access services**:
   - **With domain**: Check the workflow output for HTTPS URLs
   - **Without domain**: Use `http://SERVER_IP/wireguard` and other HTTP URLs

---

## Common Issues

### Issue: "Required token could not be found"

**Solution**: Make sure `TF_API_TOKEN` is set correctly in GitHub Secrets

### Issue: "Invalid credentials" from Hetzner

**Solution**: Regenerate `HCLOUD_TOKEN` with Read & Write permissions

### Issue: "No valid SSH key IDs"

**Solution**: Verify `SSH_KEY_IDS` is valid JSON: `[108153935]`

### Issue: Ansible connection fails

**Solution**: Check that `SSH_PRIVATE_KEY` includes full key with headers

### Issue: SSL certificate not issued

**Solution**:

- Verify `HETZNER_DNS_TOKEN` is valid
- Ensure domain nameservers are updated to Hetzner DNS
- Wait up to 24 hours for DNS propagation
- Check Let's Encrypt rate limits at https://letsencrypt.org/docs/rate-limits/

### Issue: Domain doesn't resolve

**Solution**:

- Update nameservers at your domain registrar
- Use `dig yourdomain.com` to check DNS propagation
- DNS changes can take 1-48 hours

---

## Security Best Practices

✅ **Never commit secrets to git**  
✅ **Rotate tokens regularly** (every 90 days)  
✅ **Use least privilege** (only required permissions)  
✅ **Monitor Actions logs** for any token leaks  
✅ **Keep SSH keys secure** (chmod 600)

---

## Need Help?

- Terraform Cloud docs: https://developer.hashicorp.com/terraform/cloud-docs
- Hetzner Cloud API: https://docs.hetzner.cloud/
- GitHub Secrets: https://docs.github.com/en/actions/security-guides/encrypted-secrets
