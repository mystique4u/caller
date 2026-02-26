# Domain and HTTPS Setup Guide

## Overview

This guide explains how to configure a custom domain with automatic HTTPS/SSL certificates for your WireGuard VPN server.

---

## Benefits of Using a Custom Domain

✅ **HTTPS/SSL Encryption**: Secure connections with Let's Encrypt certificates  
✅ **Easy to Remember**: Use `vpn.yourdomain.com` instead of IP addresses  
✅ **Professional**: Better user experience with branded URLs  
✅ **Automatic DNS Management**: Terraform handles all DNS records  
✅ **Certificate Auto-Renewal**: Let's Encrypt certificates renew automatically

---

## Prerequisites

1. **Purchase a domain** from any registrar (Namecheap, GoDaddy, etc.)
2. **Hetzner Cloud account** with API token configured
3. **Create DNS Zone in Hetzner Console** (see Step 1 below)
4. **GitHub Secrets configured** (see [GITHUB_SECRETS.md](GITHUB_SECRETS.md))

---

## Step 1: Create DNS Zone in Hetzner Console

Before running Terraform, create your DNS zone:

1. Go to https://console.hetzner.cloud/
2. Select your project
3. Click on **DNS** in the left menu
4. Click **"Add zone"**
5. Enter your domain name (e.g., `itin.buzz`)
6. Click **"Add zone"**
7. Note the nameservers shown (you'll need these for your registrar)

**Important**: Terraform will use this existing zone and add DNS records to it automatically.

---

## Step 2: Configure GitHub Secrets

Add these **optional** secrets for domain support:

### DOMAIN_NAME

- **Value**: Your domain (without `https://` or `/`)
- **Example**: `itin.buzz` or `example.net`
- **Must match**: The zone name you created in Step 1

### EMAIL_ADDRESS (optional)

- **Value**: Email for Let's Encrypt notifications
- **Example**: `admin@itin.buzz`
- **Note**: Defaults to `admin@yourdomain.com` if not set

**Note**: Your existing `HCLOUD_TOKEN` manages both servers and DNS records.

---

## Step 3: Update Nameservers

**Go to your domain registrar** (where you bought the domain):

1. Find **DNS Settings** or **Nameservers** section
2. Change nameservers to:
   ```
   hydrogen.ns.hetzner.com
   oxygen.ns.hetzner.com
   helium.ns.hetzner.de
   ```
3. Save changes

**DNS Propagation**: Can take 1-48 hours. Check with:

```bash
dig yourdomain.com
```

---

## Step 4: Deploy

### First-time deployment:

```bash
# Commit changes
git add .
git commit -m "Add domain support"
git push origin main
```

### Or use GitHub Actions:

1. Go to **Actions** tab
2. Run **"Destroy and Redeploy"** workflow
3. Type `DESTROY` to confirm
4. Wait ~10-15 minutes

---

## What Gets Created

### DNS Records (Automatic)

| Record Type | Name   | Points To           | Purpose        |
| ----------- | ------ | ------------------- | -------------- |
| A           | `@`    | Server IPv4         | Root domain    |
| A           | `www`  | Server IPv4         | WWW subdomain  |
| A           | `vpn`  | Server IPv4         | WireGuard UI   |
| A           | `meet` | Server IPv4         | Galène Video   |
| AAAA        | `@`    | Server IPv6         | IPv6 support   |
| NS          | `@`    | Hetzner nameservers | DNS delegation |

### SSL Certificates (Automatic)

Let's Encrypt certificates for:

- `yourdomain.com`
- `www.yourdomain.com`
- `vpn.yourdomain.com`
- `meet.yourdomain.com`

**Auto-renewal**: Traefik handles renewal before expiry (every 60 days)

---

## Access Your Services

After DNS propagation:

### With HTTPS (Domain configured)

| Service           | URL                                      | Credentials     |
| ----------------- | ---------------------------------------- | --------------- |
| WireGuard UI      | `https://vpn.yourdomain.com`             | admin / admin   |
| Galène Video      | `https://meet.yourdomain.com`            | See below       |
| Traefik Dashboard | `https://yourdomain.com:8080/dashboard/` | None (insecure) |

### Without Domain (IP only)

| Service           | URL                                | Credentials   |
| ----------------- | ---------------------------------- | ------------- |
| WireGuard UI      | `http://SERVER_IP/wireguard`       | admin / admin |
| Galène Video      | `http://SERVER_IP/galene`          | See below     |
| Traefik Dashboard | `http://SERVER_IP:8080/dashboard/` | None          |

### Galène Access

- **Room**: `public`
- **Operator password**: `admin`
- **User access**: No password (public room)

---

## Troubleshooting

### Domain doesn't resolve

**Check DNS propagation**:

```bash
dig yourdomain.com
# Should show your server IP
```

**Solutions**:

- Verify nameservers at registrar
- Wait up to 48 hours for DNS propagation
- Check Hetzner DNS console: https://dns.hetzner.com/

### SSL certificate not issued

**Check Traefik logs**:

```bash
ssh root@SERVER_IP
docker logs traefik
```

**Common causes**:

- DNS not propagated yet (wait 24-48 hours)
- Port 80/443 not open (check firewall)
- Let's Encrypt rate limits (5 certs/week per domain)
- Email address invalid

**Solutions**:

- Wait for DNS propagation
- Verify firewall rules in Hetzner Console
- Check rate limits: https://letsencrypt.org/docs/rate-limits/

### HTTPS not working but HTTP works

**Wait for certificate issuance**:

- First certificate can take 5-10 minutes
- Check Traefik logs: `docker logs traefik`
- Look for `acme` messages

**Force renewal**:

```bash
ssh root@SERVER_IP
cd /opt/services
docker compose down
rm -f traefik/acme/acme.json
docker compose up -d
```

### Mixed content warnings

**Issue**: Some resources load over HTTP

**Solution**: Traefik automatically redirects HTTP to HTTPS. Clear browser cache.

---

## Switching Between Modes

### From IP-only to Domain

1. Purchase domain
2. Add `HETZNER_DNS_TOKEN` and `DOMAIN_NAME` to GitHub Secrets
3. Run "Destroy and Redeploy" workflow
4. Update nameservers at registrar
5. Wait for DNS propagation

### From Domain back to IP-only

1. Remove `HETZNER_DNS_TOKEN` and `DOMAIN_NAME` from GitHub Secrets
2. Run "Destroy and Redeploy" workflow
3. Access via HTTP with IP address

---

## Security Best Practices

✅ **Change default passwords immediately**:

- WireGuard UI: admin / admin → Change in settings
- Galène operator: admin → Edit `/opt/services/galene/groups/public.json`

✅ **Use strong passwords** (16+ characters)

✅ **Enable 2FA** where available

✅ **Monitor certificate expiry** (auto-renewed by Traefik)

✅ **Keep services updated**:

```bash
ssh root@SERVER_IP
cd /opt/services
docker compose pull
docker compose up -d
```

---

## Cost Breakdown

| Item                | Cost          | Frequency |
| ------------------- | ------------- | --------- |
| Domain registration | $10-15/year   | Annual    |
| Hetzner DNS         | Free          | -         |
| Let's Encrypt SSL   | Free          | -         |
| Hetzner Cloud CX23  | ~€10.20/month | Monthly   |

**Total**: ~€10.20/month + domain registration

---

## Advanced Configuration

### Custom Subdomains

Edit `terraform/main.tf` to add more DNS records:

```hcl
resource "hetznerdns_record" "custom" {
  zone_id = hetznerdns_zone.domain[0].id
  name    = "custom"  # custom.yourdomain.com
  value   = hcloud_server.vpn_server.ipv4_address
  type    = "A"
  ttl     = 3600
}
```

### Additional SSL Certificates

Edit `ansible/playbook.yml` to add Traefik labels:

```yaml
- "traefik.http.routers.custom.rule=Host(`custom.{{ domain_name }}`)"
- "traefik.http.routers.custom.tls.certresolver=letsencrypt"
```

### Wildcard Certificates

Requires DNS challenge instead of HTTP challenge. See Traefik docs:  
https://doc.traefik.io/traefik/https/acme/

---

## Need Help?

- **Hetzner DNS Docs**: https://docs.hetzner.com/dns-console/dns/general/
- **Traefik ACME Docs**: https://doc.traefik.io/traefik/https/acme/
- **Let's Encrypt Docs**: https://letsencrypt.org/getting-started/
- **GitHub Issues**: https://github.com/mystique4u/caller/issues
