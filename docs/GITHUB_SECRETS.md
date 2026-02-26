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

---

## 3. FIREWALL_NAME
**Purpose**: Name for the firewall (auto-created by Terraform)

**Value**: `vpn-services-firewall`

**Note**: This firewall will be created automatically. No manual setup needed!

---

## 4. SSH_KEY_IDS
**Purpose**: SSH key IDs for server access (as JSON array)

**How to get it**:
1. Your current SSH key ID is: `108153935`
2. If you need to find it: `hcloud ssh-key list`

**Value format**: JSON array of numbers: `[108153935]`

**Example**: `[108153935]` or `[12345, 67890]` for multiple keys

**Important**: Must be valid JSON with square brackets!

---

## 5. SSH_PRIVATE_KEY
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

| Secret Name | Type | Example Value |
|-------------|------|---------------|
| `TF_API_TOKEN` | String | `TYBeJ4Gh8NK...` |
| `HCLOUD_TOKEN` | String | `A1B2C3D4E5F6...` |
| `FIREWALL_NAME` | String | `vpn-services-firewall` |
| `SSH_KEY_IDS` | JSON Array | `[108153935]` |
| `SSH_PRIVATE_KEY` | Multi-line | `-----BEGIN OPENSSH...` |

---

## Verification Steps

After adding all secrets:

1. **Check secrets are set**:
   - Go to `https://github.com/mystique4u/caller/settings/secrets/actions`
   - You should see all 5 secrets listed

2. **Test deployment**:
   - Go to **Actions** tab
   - Run "Destroy and Redeploy" workflow
   - Type `DESTROY` to confirm
   - Wait for completion (~10 minutes)

3. **Access services**:
   - WireGuard UI: `http://SERVER_IP/wireguard`
   - Galène: `http://SERVER_IP/galene`
   - Traefik: `http://SERVER_IP:8080/dashboard/`

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
