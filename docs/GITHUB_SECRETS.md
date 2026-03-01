# GitHub Secrets Configuration

## Required Secrets List

Configure these secrets in GitHub at:  
`Settings` → `Secrets and variables` → `Actions` → `New repository secret`

---

## Infrastructure Secrets

### 1. TF_API_TOKEN

**Purpose**: Terraform Cloud authentication for remote state storage

**How to get it**:

1. Go to https://app.terraform.io/app/settings/tokens
2. Click "Create an API token"
3. Name it: `github-actions-caller`
4. Copy the token (shown once!)

**Value format**: `abcdefg...xyz` (long alphanumeric string)

**Example**: `TYBeJ4Gh8NKLMnoPQRsTUvWxYz1234567890aBcDeF`

---

### 2. HCLOUD_TOKEN

**Purpose**: Hetzner Cloud API access for creating infrastructure and managing DNS

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

**Note**: This token manages both servers AND DNS (Hetzner unified API)

---

### 3. DOMAIN_NAME

**Purpose**: Your custom domain for HTTPS access

**How to get it**:

1. Purchase a domain from any registrar (Namecheap, GoDaddy, etc.)
2. Use the domain without protocol or path

**Value format**: `example.com` (just the domain)

**Examples**: `mydomain.com` or `myvpn.net`

**Subdomains automatically configured**:
- `vpn.yourdomain.com` - WireGuard UI
- `meet.yourdomain.com` - Jitsi Meet
- `matrix.yourdomain.com` - Matrix Synapse
- `chat.yourdomain.com` - Element Web
- `yourdomain.com:8080/dashboard/` - Traefik

---

### 4. EMAIL_ADDRESS

**Purpose**: Email for Let's Encrypt SSL certificate notifications

**Value format**: `your-email@example.com`

**Examples**: `admin@mydomain.com` or `you@gmail.com`

**Note**: Required for SSL certificates

---

### 5. FIREWALL_NAME

**Purpose**: Name for the firewall (auto-created by Terraform)

**Value**: `vpn-services-firewall`

**Note**: This firewall is created automatically. No manual setup needed!

---

### 6. SSH_KEY_IDS

**Purpose**: SSH key IDs for server access (as JSON array)

**How to get it**:

1. List your SSH keys: `hcloud ssh-key list`
2. Use the numeric ID(s)

**Value format**: JSON array of numbers: `[108153935]`

**Example**: `[108153935]` or `[12345, 67890]` for multiple keys

**Important**: Must be valid JSON with square brackets!

---

### 7. SSH_PRIVATE_KEY

**Purpose**: Private SSH key for Ansible to configure the server

**How to get it**:

```bash
cat ~/.ssh/your-private-key
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

## Service Credentials

### 8. JITSI_ADMIN_USER

**Purpose**: Admin username for Jitsi Meet authentication

**Value format**: Any username (lowercase, no spaces)

**Example**: `admin` or `jitsiadmin`

**Note**: This user can create and moderate video conferences

---

### 9. JITSI_ADMIN_PASSWORD

**Purpose**: Admin password for Jitsi Meet

**Value format**: Strong password (minimum 12 characters recommended)

**Example**: `MySecurePass123!`

**Security**: Use a unique, strong password. Store it securely!

---

### 10. MATRIX_ADMIN_USER

**Purpose**: Admin username for Matrix messaging server

**Value format**: Username only (no @ symbol or domain)

**Example**: `admin` or `matrixadmin`

**Login as**: `@MATRIX_ADMIN_USER:yourdomain.com`

---

### 11. MATRIX_ADMIN_PASSWORD

**Purpose**: Admin password for Matrix account

**Value format**: Strong password (minimum 12 characters recommended)

**Example**: `MatrixSecure456!`

**Note**: User is auto-created during deployment

---

### 12. MATRIX_REGISTRATION_SECRET

**Purpose**: Secret key for Matrix registration (security feature)

**Value format**: Random string (minimum 20 characters)

**How to generate**:

```bash
openssl rand -base64 32
```

**Example**: `rK9mN2pQ7sT4vX8zA3bC5dE6fG8hJ0kL2mN5oP7qR9s`

---

### 13. MATRIX_POSTGRES_PASSWORD

**Purpose**: PostgreSQL database password for Matrix

**Value format**: Strong password (minimum 12 characters)

**How to generate**:

```bash
openssl rand -base64 24
```

**Example**: `DbSecure789XyZ!@#$`

**Note**: Never used directly - only by Matrix Synapse internally

---

## Quick Reference Table

### Infrastructure Secrets (Required)

| Secret Name       | Type       | Example Value           |
| ----------------- | ---------- | ----------------------- |
| `TF_API_TOKEN`    | String     | `TYBeJ4Gh8NK...`        |
| `HCLOUD_TOKEN`    | String     | `A1B2C3D4E5F6...`       |
| `DOMAIN_NAME`     | String     | `example.com`           |
| `EMAIL_ADDRESS`   | String     | `admin@example.com`     |
| `FIREWALL_NAME`   | String     | `vpn-services-firewall` |
| `SSH_KEY_IDS`     | JSON Array | `[108153935]`           |
| `SSH_PRIVATE_KEY` | Multi-line | `-----BEGIN OPENSSH...` |

### Service Credentials (Required)

| Secret Name                  | Type   | Example Value        |
| ---------------------------- | ------ | -------------------- |
| `JITSI_ADMIN_USER`           | String | `admin`              |
| `JITSI_ADMIN_PASSWORD`       | String | `MySecurePass123!`   |
| `MATRIX_ADMIN_USER`          | String | `admin`              |
| `MATRIX_ADMIN_PASSWORD`      | String | `MatrixSecure456!`   |
| `MATRIX_REGISTRATION_SECRET` | String | `rK9mN2pQ7sT4...`    |
| `MATRIX_POSTGRES_PASSWORD`   | String | `DbSecure789XyZ!@#$` |

---

## DNS Setup

DNS is automatically managed by Hetzner Cloud API using your `HCLOUD_TOKEN`.

**Update nameservers at your domain registrar to**:

- `hydrogen.ns.hetzner.com`
- `oxygen.ns.hetzner.com`
- `helium.ns.hetzner.de`

**Records automatically created**:

| Type | Subdomain | Target      | Service        |
| ---- | --------- | ----------- | -------------- |
| A    | @         | Server IPv4 | Root domain    |
| AAAA | @         | Server IPv6 | Root IPv6      |
| A    | www       | Server IPv4 | WWW subdomain  |
| A    | vpn       | Server IPv4 | WireGuard UI   |
| A    | meet      | Server IPv4 | Jitsi Meet     |
| A    | matrix    | Server IPv4 | Matrix Synapse |
| A    | chat      | Server IPv4 | Element Web    |

---

## Verification Steps

After adding all secrets:

1. **Check secrets are set**:
   - Go to `Settings` → `Secrets and variables` → `Actions`
   - Verify all 13 secrets are configured

2. **Test deployment**:
   - Go to **Actions** tab
   - Run "Deploy Infrastructure" workflow
   - Wait ~10 minutes for completion

3. **Update DNS nameservers**:
   - Login to your domain registrar
   - Update nameservers to Hetzner's
   - Wait 1-24 hours for DNS propagation

4. **Access services**:
   - WireGuard UI: `https://vpn.yourdomain.com`
   - Jitsi Meet: `https://meet.yourdomain.com`
   - Element Web: `https://chat.yourdomain.com`
   - Matrix Server: `https://matrix.yourdomain.com`

---

## Security Best Practices

1. **Use strong, unique passwords** for all service credentials
2. **Generate random secrets** using `openssl rand -base64 32`
3. **Never commit secrets** to Git repository
4. **Rotate passwords regularly** (every 90 days recommended)
5. **Use a password manager** to store credentials securely
6. **Enable 2FA** on your GitHub account
7. **Limit repository access** to trusted team members only

---

## Troubleshooting

### Secret Not Working

- Ensure no extra spaces or newlines
- For JSON arrays, verify bracket syntax: `[123]`
- For SSH keys, include complete key with headers
- Restart workflow after updating secrets

### DNS Not Resolving

- Verify nameservers updated at registrar
- Wait 24 hours for full DNS propagation
- Test with: `dig yourdomain.com NS`

### SSL Certificate Issues

- Verify EMAIL_ADDRESS is valid
- Check Traefik logs: `docker logs traefik | grep acme`
- Ensure ports 80 and 443 are open

---

## Quick Setup Script

Generate all required passwords at once:

```bash
echo "=== Service Passwords ==="
echo "JITSI_ADMIN_PASSWORD:      $(openssl rand -base64 16)"
echo "MATRIX_ADMIN_PASSWORD:     $(openssl rand -base64 16)"
echo "MATRIX_REGISTRATION_SECRET: $(openssl rand -base64 32)"
echo "MATRIX_POSTGRES_PASSWORD:   $(openssl rand -base64 24)"
```

Copy the output and add each value as a GitHub Secret.

---

## Related Documentation

- **[Main README](../README.md)** - Project overview
- **[WireGuard Guide](../WIREGUARD_GUIDE.md)** - VPN setup
- **[Jitsi Guide](../JITSI_GUIDE.md)** - Video conferencing
- **[Matrix Guide](../MATRIX_GUIDE.md)** - Messaging server
- **[Domain Setup](DOMAIN_SETUP.md)** - DNS configuration
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
