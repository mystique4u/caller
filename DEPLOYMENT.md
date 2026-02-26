# Deployment Guide

## 📋 Overview

This project uses a comprehensive CI/CD pipeline with multiple stages:
- **Automated checks** on every push to main
- **Manual deployment** via GitHub Actions
- **Health checks** after deployment

## 🚀 Initial Deployment

### 1. Set up GitHub Secrets

Go to your repository → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:
- `TF_API_TOKEN` - Terraform Cloud API token
- `HCLOUD_TOKEN` - Hetzner Cloud API token
- `FIREWALL_NAME` - Name for your firewall (e.g., "vpn-firewall")
- `SSH_KEY_IDS` - Hetzner SSH key IDs (comma-separated, e.g., "108153935")
- `SSH_PRIVATE_KEY` - Your SSH private key for Ansible
- `DOMAIN_NAME` - Your domain (e.g., "itin.buzz") - optional
- `EMAIL_ADDRESS` - Email for Let's Encrypt - optional

**Optional for testing:**
- `LETSENCRYPT_ENV` - Set to `staging` for test certificates (avoids rate limits)
  - Use `staging` for testing deployments
  - Use `production` (default) for real certificates
  - Staging certificates will show browser warnings but won't hit rate limits

### 2. Deploy Infrastructure

1. Go to **Actions** tab in GitHub
2. Select **"Deploy Infrastructure"** workflow
3. Click **"Run workflow"**
4. Select:
   - Branch: `main`
   - Action: `apply`
   - Skip validation: `false` (recommended)
5. Click **"Run workflow"** button
6. Wait for completion (~10-15 minutes)

**First deployment with domain:**
- SSL certificates will be automatically requested from Let's Encrypt
- Certificates are stored in `/opt/services/traefik/acme/acme.json`
- On redeployment, existing certificates are reused (no new requests)
- Certificates auto-renew 30 days before expiration

### 3. Verify Deployment

The workflow will automatically run health checks:
- ✅ Server connectivity
- ✅ HTTP/HTTPS services
- ✅ WireGuard VPN port
- ✅ All subdomains (if domain configured)

## 🔄 Redeploying Changes

### Scenario 1: Infrastructure Changes (Terraform)

**When to use:** Changing server size, firewall rules, DNS records, etc.

1. **Make changes** to `terraform/main.tf`
2. **Commit and push** to main:
   ```bash
   git add terraform/main.tf
   git commit -m "feat: Update server type to CX33"
   git push origin main
   ```
3. **GitHub Actions automatically:**
   - ✅ Runs all checks
   - ✅ Creates Terraform plan
   - ⏸️ Stops (no auto-deploy)
4. **Review the plan** in Actions → Latest workflow run → Plan Summary
5. **Deploy manually:**
   - Actions → Deploy Infrastructure → Run workflow
   - Action: `apply`
   - Run workflow

### Scenario 2: Configuration Changes (Ansible)

**When to use:** Updating Docker containers, services, or configurations

1. **Make changes** to `ansible/playbook.yml`
2. **Commit and push:**
   ```bash
   git add ansible/playbook.yml
   git commit -m "feat: Update WireGuard UI to v0.6.3"
   git push origin main
   ```
3. **Checks run automatically** (validates Ansible syntax)
4. **Deploy manually:**
   - Actions → Deploy Infrastructure → Run workflow
   - Action: `apply`
   - Run workflow

**Note:** Ansible changes only reconfigure the server, don't recreate it.

### Scenario 3: Quick Configuration Update (Without Terraform)

**When to use:** Only Ansible changes, Terraform unchanged

1. Push your Ansible changes
2. Deploy with workflow_dispatch
3. Terraform will show "no changes" (exit code 0)
4. Ansible will still run and update configurations

### Scenario 4: Emergency Changes

**When to use:** Critical fixes that need immediate deployment

1. Make your changes
2. Actions → Deploy Infrastructure → Run workflow
3. Action: `apply`
4. **Skip validation: `true`** (not recommended, but faster)
5. Run workflow

**⚠️ Warning:** Skipping validation bypasses security checks!

## 🗑️ Destroying Infrastructure

### Safety Features:
- Requires typing exact word "DESTROY"
- Requires providing a reason
- Shows destroy plan before execution
- Requires manual approval

### Steps:

1. Go to **Actions** → **"Destroy Infrastructure"**
2. Click **"Run workflow"**
3. Enter:
   - Confirm destroy: `DESTROY` (exact text)
   - Reason: "Reason for destroying infrastructure"
4. Click **"Run workflow"**
5. **Review** the destroy plan in artifacts
6. **Approve** the deployment in GitHub (if environment protection is set up)
7. Infrastructure is destroyed

## 📊 Workflow Stages

### On Push to Main:
```
┌─────────────────────────────────────────┐
│  Code Quality Checks                     │
│  - Secrets scan                          │
│  - File permissions                      │
│  - Ansible syntax                        │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Terraform Validation                    │
│  - Format check                          │
│  - Init & validate                       │
│  - Best practices                        │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Security Scanning                       │
│  - tfsec                                 │
│  - Exposed ports check                   │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Terraform Plan                          │
│  - Create plan                           │
│  - Upload artifact                       │
│  - Show summary                          │
└──────────────┬──────────────────────────┘
               ↓
         ⏸️  STOPS HERE
    (Review required for deployment)
```

### Manual Deploy (workflow_dispatch with 'apply'):
```
         Previous stages...
               ↓
┌─────────────────────────────────────────┐
│  Approval Gate                           │
│  - Manual confirmation required          │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Terraform Apply                         │
│  - Deploy infrastructure                 │
│  - Output server IP                      │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Ansible Configuration                   │
│  - Install services                      │
│  - Configure HTTPS                       │
│  - Deploy containers                     │
└──────────────┬──────────────────────────┘
               ↓
┌─────────────────────────────────────────┐
│  Health Checks                           │
│  - Server connectivity                   │
│  - HTTP/HTTPS endpoints                  │
│  - Service availability                  │
│  - Generate report                       │
└─────────────────────────────────────────┘
```

## 🔧 Troubleshooting Redeployments

### Server creation fails: "resource_unavailable"

**Error:** `error during placement (resource_unavailable...)`

**Cause:** The requested server type (CX23) is temporarily out of stock in the selected location.

**Current Hetzner Status (as of Feb 2026):**
- ⚠️ FSN1 (Falkenstein) - Limited availability
- ⚠️ NBG1 (Nuremberg) - May have capacity issues
- ✅ HEL1 (Helsinki) - Usually better availability
- ✅ ASH (Ashburn, USA) - Alternative option

**Solutions:**

1. **Try Helsinki location** (recommended for Europe):
   ```bash
   # Add GitHub Secret:
   # Name: TF_VAR_server_location
   # Value: hel1
   ```
   
   Then redeploy.

2. **Try Ashburn location** (if US location acceptable):
   ```bash
   # Add GitHub Secret:
   # Name: TF_VAR_server_location
   # Value: ash
   ```

3. **Wait and retry in NBG1** (15-60 minutes):
   - Server types frequently become available again
   - Check Hetzner status: https://status.hetzner.cloud/

4. **Use different server type** (edit `terraform/main.tf`):
   - `cx23` (2 vCPU, 8GB RAM) - recommended
   - `cx33` (4 vCPU, 16GB RAM) - larger (usually better availability)
   - `cx21` (2 vCPU, 4GB RAM) - smaller (might be tight)

### Let's Encrypt Rate Limits

**Error:** Too many certificate requests or validation failures

**Cause:** Let's Encrypt has rate limits to prevent abuse:
- 50 certificates per domain per week
- 5 failed validations per hour
- 300 new orders per account per 3 hours

**Solutions:**

1. **Use staging environment for testing** (recommended):
   ```bash
   # Add GitHub Secret:
   # Name: LETSENCRYPT_ENV
   # Value: staging
   ```
   - Staging certificates will show browser warnings
   - No rate limits for testing
   - Switch to `production` when ready

2. **Certificates are automatically preserved**:
   - Stored in `/opt/services/traefik/acme/acme.json`
   - Reused on redeployment (no new requests)
   - Auto-renewed 30 days before expiration
   - Only deleted if you destroy infrastructure

3. **Wait for rate limit reset**:
   - Failed validations: 1 hour
   - Certificate limit: 1 week
   - Check status: https://crt.sh/ (search your domain)

4. **Ensure DNS is correct before deploying**:
   - Verify nameservers are updated
   - Test with: `dig yourdomain.com`
   - Wait for DNS propagation (5-30 minutes)

### Plan shows no changes but you made updates:
- Check if file is committed: `git status`
- Check if pushed: `git log origin/main`
- Verify correct file path in commit

### Ansible fails on redeployment:
- Services might be running: Ansible handles this
- SSH connection issues: Check firewall rules
- DNS not updated: Health checks will warn

### Health checks fail:
- **SSL warnings:** Normal for first 5-10 minutes
- **Subdomain unreachable:** Check DNS propagation
- **All services fail:** Wait 2-3 minutes and recheck

### How to force redeploy without changes:
```bash
# Trigger workflow manually
# No code changes needed
# Just run: Actions → Deploy Infrastructure → apply
```

### How to update only one service:
1. Edit `ansible/playbook.yml`
2. Change the specific service version/config
3. Push and deploy
4. Only affected services are updated

## 📝 Best Practices

### Before Every Deployment:
1. ✅ Review the Terraform plan carefully
2. ✅ Check health check results from previous deployment
3. ✅ Ensure DNS is configured (if using domain)
4. ✅ Backup any important data

### After Every Deployment:
1. ✅ Wait for health checks to complete
2. ✅ Manually verify key services
3. ✅ Check Traefik dashboard
4. ✅ Test WireGuard VPN connection

### Regular Maintenance:
- Update Docker image versions monthly
- Review security scan results
- Monitor server resources
- Rotate SSH keys periodically

## 🆘 Emergency Procedures

### If deployment fails:
1. Check workflow logs for errors
2. Fix the issue in code
3. Push changes (triggers new checks)
4. Redeploy with fixes

### If services are down:
1. Check health check results
2. SSH into server: `ssh root@<server-ip>`
3. Check Docker: `docker ps -a`
4. Check logs: `docker logs <container-name>`
5. Restart if needed: `docker restart <container-name>`

### If you need to rollback:
1. Go to previous working commit: `git log`
2. Revert: `git revert <commit-hash>`
3. Push and redeploy

### Complete infrastructure reset:
1. Run destroy workflow
2. Wait for completion
3. Fix any issues
4. Run deploy workflow fresh

## 📚 Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs)
- [Hetzner Cloud API](https://docs.hetzner.cloud/)
- [Ansible Documentation](https://docs.ansible.com/)
- [WireGuard Documentation](https://www.wireguard.com/quickstart/)

## 🔗 Quick Links

- **Hetzner Console:** https://console.hetzner.cloud/
- **Terraform Cloud:** https://app.terraform.io/
- **GitHub Actions:** https://github.com/YOUR_USERNAME/caller/actions
- **Domain DNS:** https://dns.hetzner.com/
