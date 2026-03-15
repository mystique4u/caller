# Matrix Federation Setup Guide

## What Was Fixed

Your Matrix homeserver federation setup was missing several critical configurations. The following changes have been made to fix federation:

### 1. Added `/.well-known/matrix/server` file
- **Purpose**: Tells other Matrix servers how to reach your homeserver for federation
- **Configuration**: Points to `matrix.yourdomain.com:443`
- **Location**: `/opt/services/well-known/matrix/server`

### 2. Exposed Port 8448 for Federation
- **Traefik**: Added port 8448 to Traefik container
- **Entrypoint**: Created new `federation` entrypoint in traefik.toml
- **Router**: Configured Matrix Synapse to handle federation traffic on port 8448

### 3. Added `public_baseurl` Configuration
- **Purpose**: Tells Synapse its public URL for generating links and federation
- **Value**: `https://matrix.yourdomain.com`

### 4. Configured Trusted Key Servers
- **Purpose**: Allows your homeserver to verify other servers' keys
- **Default**: matrix.org as the key server

## Deployment Steps

After making these changes, you need to redeploy your services:

```bash
# SSH to your server
ssh root@YOUR_SERVER_IP

# Navigate to services directory
cd /opt/services

# Re-run the Ansible playbook (from your local machine)
ansible-playbook -i ansible/inventory.ini ansible/playbook.yml

# Or manually restart the services on the server
docker-compose down
docker-compose up -d

# Check that services are running
docker ps
```

## Testing Federation

### 1. Check Well-Known Files

Test that your well-known files are accessible:

```bash
# Test client well-known
curl https://yourdomain.com/.well-known/matrix/client

# Expected output:
# {
#   "m.homeserver": {
#     "base_url": "https://matrix.yourdomain.com"
#   }
# }

# Test server well-known (critical for federation)
curl https://yourdomain.com/.well-known/matrix/server

# Expected output:
# {
#   "m.server": "matrix.yourdomain.com:443"
# }
```

### 2. Test Federation Port

Verify port 8448 is accessible:

```bash
# Test from external machine
curl -k https://matrix.yourdomain.com:8448/_matrix/federation/v1/version

# Expected output:
# {
#   "server": {
#     "name": "Synapse",
#     "version": "1.x.x"
#   }
# }
```

### 3. Use Matrix Federation Tester

Visit the official Matrix Federation Tester:

**URL**: https://federationtester.matrix.org/

Enter your domain name (e.g., `yourdomain.com`) and click "Check".

The tester will verify:
- ✅ DNS resolution
- ✅ Server discovery (well-known files)
- ✅ TLS certificate validity
- ✅ Federation API accessibility
- ✅ Key validity

### 4. Test Federation with Another Server

Try to message a user on another Matrix server:

```
@user:matrix.org
```

Or join a public room on another server:

```
#test:matrix.org
```

## Troubleshooting

### Federation Tester Shows Errors

**Error: "Unable to find /.well-known/matrix/server"**
- Check that the well-known file is accessible at `https://yourdomain.com/.well-known/matrix/server`
- Verify Traefik routing for well-known service

**Error: "Connection refused on port 8448"**
- Verify firewall allows port 8448 (should be open in Hetzner Cloud firewall)
- Check Traefik is exposing port 8448
- Verify Matrix Synapse container is running

**Error: "SSL certificate error"**
- Wait for Let's Encrypt to issue certificates (can take a few minutes)
- Check `/opt/services/traefik/acme/acme.json` has certificates

### Check Synapse Logs

```bash
# View Matrix Synapse logs
docker logs matrix-synapse -f

# Look for federation-related errors
docker logs matrix-synapse 2>&1 | grep -i federation
```

### Check Traefik Logs

```bash
# View Traefik logs
docker logs traefik -f

# Check routing
docker logs traefik 2>&1 | grep -i matrix
```

### Verify Configuration

```bash
# Check homeserver.yaml has public_baseurl
grep public_baseurl /opt/services/matrix/synapse/homeserver.yaml

# Should output:
# public_baseurl: https://matrix.yourdomain.com
```

## DNS Requirements

Ensure these DNS records are configured in Hetzner DNS (via Terraform):

1. **A Record**: `matrix.yourdomain.com` → Your server IP
2. **SRV Record**: `_matrix._tcp.yourdomain.com` → `0 0 8448 matrix.yourdomain.com.`

## Firewall Requirements

Ensure these ports are open in your Hetzner Cloud firewall:

- **Port 443** (HTTPS) - Client connections
- **Port 8448** (TCP) - Federation (Matrix server-to-server)

These are already configured in your Terraform `main.tf`.

## Common Issues

### Issue: Users from other servers can't message me

**Solution**: 
1. Verify federation is working with the tester
2. Check that the other server doesn't have you blocked
3. Try messaging them first to establish the connection

### Issue: Can't join rooms on other servers

**Solution**:
1. Verify your server can reach the other server
2. Check firewall rules on both ends
3. Verify DNS and well-known files are correct

### Issue: Federation worked, then stopped

**Solution**:
1. Check if SSL certificates expired
2. Verify DNS records haven't changed
3. Check if Synapse container restarted and lost configuration
4. Review Synapse logs for errors

## Federation Architecture

```
User's Client
    ↓
https://matrix.yourdomain.com (port 443)
    ↓
Traefik (reverse proxy)
    ↓
Matrix Synapse (port 8008 - client API)

Other Matrix Server
    ↓
https://matrix.yourdomain.com:8448
    ↓
Traefik (federation entrypoint)
    ↓
Matrix Synapse (port 8008 - federation API)
```

## Well-Known Files Explained

### `/.well-known/matrix/client`
- Used by Matrix clients to discover your homeserver
- Contains the base URL for client connections

### `/.well-known/matrix/server` (Critical for Federation)
- Used by other Matrix servers to discover your federation endpoint
- Contains the hostname and port for federation
- Without this, other servers won't be able to reach you

## Next Steps

After fixing federation:

1. **Test thoroughly** using the Matrix Federation Tester
2. **Create a test user** on your server
3. **Try messaging** a user on another server (e.g., @test:matrix.org)
4. **Join public rooms** hosted on other servers
5. **Invite external users** to rooms on your server

## Additional Resources

- [Matrix Federation Documentation](https://matrix.org/docs/guides/federation)
- [Matrix Federation Tester](https://federationtester.matrix.org/)
- [Synapse Documentation](https://matrix-org.github.io/synapse/latest/)
- [Delegation Guide](https://matrix-org.github.io/synapse/latest/delegate.html)
