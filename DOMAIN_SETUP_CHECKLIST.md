# Domain Setup Checklist

## ✅ Prerequisites

- [ ] Domain purchased (Namecheap, GoDaddy, etc.)
- [ ] Hetzner Cloud account active
- [ ] GitHub repository forked/created
- [ ] Basic deployment working (IP-only mode)

---

## 📋 Setup Steps

### 1. Create DNS Zone in Hetzner Console

- [ ] Go to https://console.hetzner.cloud/
- [ ] Select your project
- [ ] Click **DNS** in left menu
- [ ] Click **"Add zone"**
- [ ] Enter your domain name (e.g., `itin.buzz`)
- [ ] Click **"Add zone"**
- [ ] Note the nameservers displayed

### 2. Configure GitHub Secrets

Go to: `https://github.com/YOUR_USERNAME/caller/settings/secrets/actions`

Add these 2 new secrets:

- [ ] **DOMAIN_NAME**
  - Your domain (without https:// or path)
  - **Must match** the zone name from Step 1
  - Example: `itin.buzz` or `example.net`

- [ ] **EMAIL_ADDRESS** (optional)
  - Email for Let's Encrypt SSL notifications
  - Example: `admin@itin.buzz`
  - Leave empty to use `admin@yourdomain.com`

**Note**: Your existing `HCLOUD_TOKEN` manages DNS records automatically.

### 3. Deploy Infrastructure

**Option A: Push to Git**

```bash
git add .
git commit -m "Add domain support"
git push origin main
```

**Option B: GitHub Actions**

- [ ] Go to **Actions** tab in GitHub
- [ ] Click **"Destroy and Redeploy"** workflow
- [ ] Type `DESTROY` to confirm
- [ ] Click **Run workflow**
- [ ] Wait ~10-15 minutes for completion

### 4. Check Deployment Output

- [ ] Note the server IP from workflow output
- [ ] Verify DNS nameservers listed in output
- [ ] Check for any errors in workflow logs

### 5. Update Domain Nameservers

At your domain registrar (where you bought the domain):

- [ ] Find DNS or Nameserver settings
- [ ] Change nameservers to:
  ```
  hydrogen.ns.hetzner.com
  oxygen.ns.hetzner.com
  helium.ns.hetzner.de
  ```
- [ ] Save changes
- [ ] Note: Can take 1-48 hours for propagation

### 6. Verify DNS Propagation

**After 1-2 hours**, test DNS:

```bash
# Check if domain resolves to your server IP
dig yourdomain.com

# Check nameservers
dig NS yourdomain.com

# Should show Hetzner nameservers
```

- [ ] Domain resolves to correct IP
- [ ] Nameservers show Hetzner DNS servers

### 7. Wait for SSL Certificate

**After DNS propagates**, Traefik will automatically request SSL certificates.

Check certificate status:

```bash
ssh root@SERVER_IP
docker logs traefik | grep -i acme
```

- [ ] No ACME errors in logs
- [ ] Certificate issued successfully
- [ ] Can take 5-10 minutes after DNS propagation

### 8. Test HTTPS Access

Try accessing your services:

- [ ] **WireGuard UI**: https://vpn.yourdomain.com
  - Should show WireGuard login page
  - Browser shows lock icon (valid SSL)
  - No certificate warnings

- [ ] **Galène Video**: https://meet.yourdomain.com
  - Should show Galène interface
  - Valid SSL certificate

- [ ] **Traefik Dashboard**: https://yourdomain.com:8080/dashboard/
  - Should show Traefik dashboard
  - Valid SSL certificate

### 9. Security Setup

- [ ] **Change WireGuard UI password**
  - Login with admin/admin
  - Go to settings
  - Change password

- [ ] **Change Galène operator password**

  ```bash
  ssh root@SERVER_IP
  nano /opt/services/galene/groups/public.json
  # Change "password": "admin" to strong password
  cd /opt/services
  docker compose restart galene
  ```

- [ ] **Configure Traefik Dashboard auth** (optional)
  - See Traefik documentation
  - Add BasicAuth middleware

---

## 🎉 Success Criteria

✅ Domain resolves to server IP  
✅ HTTPS works without certificate warnings  
✅ WireGuard UI accessible via https://vpn.yourdomain.com  
✅ Galène accessible via https://meet.yourdomain.com  
✅ Default passwords changed  
✅ Services accessible and working

---

## ⚠️ Troubleshooting

### DNS Not Resolving

**Symptoms**: `dig yourdomain.com` shows no results or wrong IP

**Solutions**:

- [ ] Wait longer (can take up to 48 hours)
- [ ] Verify nameservers at domain registrar
- [ ] Check Hetzner DNS console: https://dns.hetzner.com/
- [ ] Try `dig @hydrogen.ns.hetzner.com yourdomain.com`

### SSL Certificate Not Issued

**Symptoms**: HTTPS doesn't work, certificate warnings

**Solutions**:

- [ ] Verify DNS is fully propagated first
- [ ] Check Traefik logs: `docker logs traefik`
- [ ] Verify port 443 is open in firewall
- [ ] Check Let's Encrypt rate limits
- [ ] Verify email address is valid

### Services Not Loading

**Symptoms**: Blank page, 502/503 errors

**Solutions**:

- [ ] Check container status: `docker compose ps`
- [ ] Check logs: `docker compose logs`
- [ ] Restart services: `docker compose restart`
- [ ] Check Traefik routing: `docker logs traefik`

### HTTP Redirects Not Working

**Symptoms**: Can access HTTP but not HTTPS

**Solutions**:

- [ ] Wait for SSL certificate to be issued
- [ ] Check Traefik configuration
- [ ] Verify port 443 in firewall rules
- [ ] Check Traefik logs for redirect errors

---

## 📚 Documentation References

- [Complete Domain Guide](docs/DOMAIN_SETUP.md)
- [GitHub Secrets Guide](docs/GITHUB_SECRETS.md)
- [Architecture Overview](STRUCTURE.md)
- [Quick Start Guide](README.md)

---

## 🆘 Need Help?

1. **Check documentation** in `docs/` folder
2. **Review Traefik logs**: `docker logs traefik`
3. **Check DNS propagation**: `dig yourdomain.com`
4. **Verify secrets**: GitHub Settings → Secrets
5. **Review workflow logs**: GitHub Actions tab

---

## 🔄 Rollback to IP-Only

If you need to revert to IP-only mode:

- [ ] Go to GitHub Secrets
- [ ] Delete or clear these secrets:
  - HETZNER_DNS_TOKEN
  - DOMAIN_NAME
  - EMAIL_ADDRESS
- [ ] Run "Destroy and Redeploy" workflow
- [ ] Access services via `http://SERVER_IP/*`

---

## 📝 Notes

**Current Status**: [ ] Not Started / [ ] In Progress / [ ] Complete

**Domain**: **\*\*\*\***\_**\*\*\*\***

**Server IP**: **\*\*\*\***\_**\*\*\*\***

**DNS Propagation Started**: **\*\*\*\***\_**\*\*\*\***

**SSL Certificate Issued**: **\*\*\*\***\_**\*\*\*\***

**All Services Tested**: **\*\*\*\***\_**\*\*\*\***

**Passwords Changed**: **\*\*\*\***\_**\*\*\*\***
