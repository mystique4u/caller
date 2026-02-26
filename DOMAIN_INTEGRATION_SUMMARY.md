# Domain and HTTPS Integration - Summary

## What Was Added

This update adds **optional custom domain support** with automatic HTTPS/SSL certificates via Let's Encrypt.

---

## Changes Made

### 1. Terraform Configuration (`terraform/main.tf`)

✅ Added Hetzner DNS provider (timohirt/hetznerdns ~> 2.2.0)  
✅ Added DNS zone resource (conditional on domain_name)  
✅ Added DNS A records: root (@), www, vpn, meet subdomains  
✅ Added DNS AAAA record for IPv6 support  
✅ Added port 443 to firewall rules for HTTPS  
✅ Added variables: `hetzner_dns_token` (sensitive), `domain_name`  
✅ Added outputs: `domain_name`, `dns_zone_id`, `nameservers`

### 2. Ansible Playbook (`ansible/playbook.yml`)

✅ Fixed file corruption (recreated clean version)  
✅ Added conditional HTTPS/HTTP modes based on domain_name  
✅ Traefik configuration with Let's Encrypt certificate resolver  
✅ HTTP to HTTPS redirect when domain is configured  
✅ Service labels with TLS certificate resolver  
✅ Environment variables: DOMAIN_NAME, EMAIL_ADDRESS  
✅ Proper acme.json permissions (0600)

### 3. GitHub Actions Workflows

✅ Updated `deploy.yml`:

- Added `TF_VAR_hetzner_dns_token` environment variable
- Added `TF_VAR_domain_name` environment variable
- Updated Ansible env vars (DOMAIN_NAME, EMAIL_ADDRESS)
- Enhanced deployment output with domain/IP modes

✅ Updated `destroy-and-redeploy.yml`:

- Added new environment variables for destroy phase
- Added new environment variables for deploy phase
- Enhanced final output with HTTPS/HTTP URLs

### 4. Documentation

✅ Updated `docs/GITHUB_SECRETS.md`:

- Added HETZNER_DNS_TOKEN documentation
- Added DOMAIN_NAME documentation
- Added EMAIL_ADDRESS documentation
- Added deployment modes table (IP vs Domain)
- Added troubleshooting for DNS/SSL issues

✅ Created `docs/DOMAIN_SETUP.md`:

- Complete domain setup guide
- DNS record configuration
- SSL certificate details
- Troubleshooting section
- Advanced configuration examples

✅ Created `DOMAIN_QUICKSTART.md`:

- 5-minute setup guide
- Quick reference tables
- Basic troubleshooting

✅ Updated `README.md`:

- Added domain features to main description
- Split access tables (with/without domain)
- Added optional secrets table
- Links to domain guides

---

## How It Works

### Mode 1: IP Address Only (Default)

**When**: No `DOMAIN_NAME` secret configured

**Behavior**:

- Services accessible via `http://SERVER_IP/*`
- No DNS configuration needed
- No SSL certificates
- Works immediately after deployment

### Mode 2: Custom Domain with HTTPS

**When**: `DOMAIN_NAME` and `HETZNER_DNS_TOKEN` secrets configured

**Behavior**:

- Terraform creates DNS zone in Hetzner DNS
- Terraform creates A/AAAA records pointing to server
- Ansible configures Traefik with Let's Encrypt resolver
- Traefik requests SSL certificates via HTTP-01 challenge
- Services accessible via `https://subdomain.yourdomain.com`
- HTTP automatically redirects to HTTPS

---

## DNS Records Created

| Type | Name | Value       | Purpose       |
| ---- | ---- | ----------- | ------------- |
| A    | @    | Server IPv4 | Root domain   |
| A    | www  | Server IPv4 | WWW subdomain |
| A    | vpn  | Server IPv4 | WireGuard UI  |
| A    | meet | Server IPv4 | Galène video  |
| AAAA | @    | Server IPv6 | IPv6 support  |

---

## SSL Certificates

**Issued by**: Let's Encrypt  
**Challenge**: HTTP-01  
**Domains**:

- yourdomain.com
- www.yourdomain.com
- vpn.yourdomain.com
- meet.yourdomain.com

**Storage**: `/opt/services/traefik/acme/acme.json`  
**Auto-renewal**: Traefik handles renewal automatically

---

## Required User Actions

### For Basic Setup (IP Only)

1. Configure 5 GitHub Secrets
2. Push to main or trigger workflow
3. Access via HTTP with IP

### For Domain Setup (HTTPS)

1. Complete basic setup
2. Purchase domain
3. Get Hetzner DNS token
4. Add 3 more GitHub Secrets (HETZNER_DNS_TOKEN, DOMAIN_NAME, EMAIL_ADDRESS)
5. Redeploy
6. **Update nameservers at domain registrar** to:
   - hydrogen.ns.hetzner.com
   - oxygen.ns.hetzner.com
   - helium.ns.hetzner.de
7. Wait 1-48 hours for DNS propagation
8. Access via HTTPS with domain

---

## Testing

### Test Basic Deployment (IP)

```bash
git add .
git commit -m "Test IP-only deployment"
git push origin main
```

Wait ~10 minutes, then access:

- `http://SERVER_IP/wireguard`
- `http://SERVER_IP/galene`
- `http://SERVER_IP:8080/dashboard/`

### Test Domain Deployment (HTTPS)

```bash
# Add domain secrets in GitHub
# Then redeploy
git add .
git commit -m "Add domain support"
git push origin main
```

Wait ~10-15 minutes, then:

1. Update nameservers at domain registrar
2. Check DNS propagation: `dig yourdomain.com`
3. Wait for SSL certificate issuance (5-10 minutes)
4. Access services:
   - `https://vpn.yourdomain.com`
   - `https://meet.yourdomain.com`
   - `https://yourdomain.com:8080/dashboard/`

---

## Switching Between Modes

### IP → Domain

1. Add domain secrets (HETZNER_DNS_TOKEN, DOMAIN_NAME, EMAIL_ADDRESS)
2. Run "Destroy and Redeploy" workflow
3. Update nameservers
4. Wait for DNS propagation

### Domain → IP

1. Remove domain secrets (keep them empty or delete)
2. Run "Destroy and Redeploy" workflow
3. Access via HTTP with IP

---

## Security Considerations

✅ **SSL/TLS**: Automatic HTTPS with Let's Encrypt  
✅ **Certificate Storage**: Secured with 0600 permissions  
✅ **HTTP Redirect**: All HTTP traffic redirected to HTTPS (domain mode)  
✅ **Firewall**: Port 443 added for HTTPS  
✅ **Default Passwords**: Must be changed immediately  
⚠️ **Traefik Dashboard**: Currently insecure (no authentication)

---

## Troubleshooting

### DNS Not Resolving

```bash
# Check propagation
dig yourdomain.com

# Check nameservers
dig NS yourdomain.com
```

**Fix**: Wait up to 48 hours, verify nameservers at registrar

### SSL Certificate Not Issued

```bash
# Check Traefik logs
ssh root@SERVER_IP
docker logs traefik | grep acme
```

**Common Issues**:

- DNS not propagated yet
- Port 80/443 blocked
- Let's Encrypt rate limits
- Invalid email address

### Services Not Accessible

```bash
# Check container status
ssh root@SERVER_IP
cd /opt/services
docker compose ps
docker compose logs
```

---

## Files Modified

| File                                         | Changes                                 |
| -------------------------------------------- | --------------------------------------- |
| `terraform/main.tf`                          | DNS provider, zone, records, variables  |
| `ansible/playbook.yml`                       | Traefik HTTPS config, conditional modes |
| `.github/workflows/deploy.yml`               | New env vars, enhanced output           |
| `.github/workflows/destroy-and-redeploy.yml` | New env vars, enhanced output           |
| `docs/GITHUB_SECRETS.md`                     | Domain secrets documentation            |
| `docs/DOMAIN_SETUP.md`                       | Complete domain guide (NEW)             |
| `DOMAIN_QUICKSTART.md`                       | Quick setup guide (NEW)                 |
| `README.md`                                  | Domain features, updated tables         |

---

## Next Steps

1. **Test basic deployment** without domain
2. **Purchase domain** (optional)
3. **Get Hetzner DNS token** (optional)
4. **Add domain secrets** (optional)
5. **Redeploy with domain** (optional)
6. **Update nameservers** at registrar
7. **Wait for DNS propagation**
8. **Access via HTTPS**
9. **Change default passwords**

---

## Documentation Links

- [Quick Start](README.md)
- [Domain Quick Setup](DOMAIN_QUICKSTART.md)
- [Complete Domain Guide](docs/DOMAIN_SETUP.md)
- [GitHub Secrets Setup](docs/GITHUB_SECRETS.md)
- [Architecture Overview](STRUCTURE.md)

---

## Support

For issues or questions:

1. Check troubleshooting sections in documentation
2. Review Traefik logs: `docker logs traefik`
3. Check DNS propagation: `dig yourdomain.com`
4. Verify GitHub Secrets are configured correctly
5. Review GitHub Actions workflow logs
