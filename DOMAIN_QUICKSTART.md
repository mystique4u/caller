# Domain and HTTPS Setup - Quick Start

## What You Need

1. **A domain** (buy from Namecheap, GoDaddy, etc.)
2. **Hetzner Cloud account** (you already have this)
3. **Email address** (for Let's Encrypt SSL certificates)

---

## 4-Minute Setup

### Step 1: Create DNS Zone

1. Go to https://console.hetzner.cloud/
2. Click **DNS** → **Add zone**
3. Enter your domain (e.g., `itin.buzz`)
4. Click **Add zone**
5. Note the nameservers shown

### Step 2: Add GitHub Secrets

Go to: `https://github.com/YOUR_USERNAME/caller/settings/secrets/actions`

Add these 2 new secrets:

| Secret Name   | Value                   | Example           |
| ------------- | ----------------------- | ----------------- |
| DOMAIN_NAME   | Your domain from Step 1 | `itin.buzz`       |
| EMAIL_ADDRESS | Your email              | `admin@itin.buzz` |

**Note**: Use the EXACT domain name from the zone you created in Step 1.

### Step 3: Deploy

```bash
git push origin main
```

Or run **"Destroy and Redeploy"** workflow in GitHub Actions.

### Step 4: Update Nameservers

At your domain registrar, change nameservers to:

```
hydrogen.ns.hetzner.com
oxygen.ns.hetzner.com
helium.ns.hetzner.de
```

Wait 1-48 hours for DNS propagation.

---

## What You Get

After DNS propagation:

| Service      | URL                                      |
| ------------ | ---------------------------------------- |
| WireGuard UI | `https://vpn.yourdomain.com`             |
| Video Calls  | `https://meet.yourdomain.com`            |
| Dashboard    | `https://yourdomain.com:8080/dashboard/` |

**All with automatic HTTPS and SSL certificates!**

---

## Without Domain (Optional)

Skip domain setup and use IP addresses:

| Service      | URL                                |
| ------------ | ---------------------------------- |
| WireGuard UI | `http://SERVER_IP/wireguard`       |
| Video Calls  | `http://SERVER_IP/galene`          |
| Dashboard    | `http://SERVER_IP:8080/dashboard/` |

Just don't add the `HETZNER_DNS_TOKEN` and `DOMAIN_NAME` secrets.

---

## Troubleshooting

**Domain not working?**

```bash
# Check if DNS is propagated
dig yourdomain.com

# Should show your server IP
```

**SSL certificate not issued?**

Wait 24-48 hours for DNS propagation. Check logs:

```bash
ssh root@SERVER_IP
docker logs traefik
```

---

## Full Documentation

- [Complete Domain Setup Guide](docs/DOMAIN_SETUP.md)
- [GitHub Secrets Guide](docs/GITHUB_SECRETS.md)
- [Architecture Overview](STRUCTURE.md)
