# Quick Matrix Server Diagnostic

## Run these commands on your server to diagnose the issue:

### 1. Check which containers are running:
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
```

### 2. Check Matrix Synapse status and logs:
```bash
# Check if Synapse is running
docker ps | grep matrix-synapse

# Check recent logs
docker logs matrix-synapse --tail 50

# Check for configuration errors
docker logs matrix-synapse 2>&1 | grep -i "error\|exception\|failed" | tail -20
```

### 3. Check if Synapse config is valid:
```bash
# Look for YAML syntax errors
docker exec matrix-synapse python -m synapse.config -c /data/homeserver.yaml

# Check experimental_features block
docker exec matrix-synapse grep -A 10 "experimental_features" /data/homeserver.yaml
```

### 4. Check Traefik routing:
```bash
# Check Traefik logs
docker logs traefik --tail 50

# Check if Traefik can reach Matrix
curl -v http://localhost:8008/health
```

### 5. Check well-known files:
```bash
# Verify files exist
ls -la /opt/services/well-known/matrix/

# Check content
cat /opt/services/well-known/matrix/client
cat /opt/services/well-known/matrix/server
```

### 6. Test connectivity:
```bash
# Test Matrix from localhost
curl http://localhost:8008/health

# Test through Traefik (replace with your domain)
curl https://matrix.yourdomain.com/_matrix/client/versions
```

## Common Issues & Quick Fixes:

### Issue 1: YAML Syntax Error in homeserver.yaml
**Symptoms:** Synapse won't start, logs show "yaml.scanner.ScannerError"

**Fix:**
```bash
# Backup current config
cp /opt/services/matrix/synapse/homeserver.yaml /opt/services/matrix/synapse/homeserver.yaml.backup

# Remove the problematic experimental_features block
docker exec matrix-synapse sed -i '/# BEGIN ANSIBLE MANAGED BLOCK - Experimental Features/,/# END ANSIBLE MANAGED BLOCK - Experimental Features/d' /data/homeserver.yaml

# Restart Synapse
docker restart matrix-synapse

# Check logs
docker logs matrix-synapse -f
```

### Issue 2: Duplicate configuration entries
**Symptoms:** Multiple "experimental_features:" or "trusted_key_servers:" in config

**Fix:**
```bash
# Check for duplicates
docker exec matrix-synapse grep -n "experimental_features:" /data/homeserver.yaml
docker exec matrix-synapse grep -n "trusted_key_servers:" /data/homeserver.yaml

# If you see duplicates, edit the file manually
docker exec -it matrix-synapse vi /data/homeserver.yaml
# Or copy it out, edit locally, and copy back
```

### Issue 3: Traefik can't route to Matrix
**Symptoms:** 502 Bad Gateway, "Server unreachable"

**Fix:**
```bash
# Restart Traefik
docker restart traefik

# Check Traefik can reach Matrix container
docker exec traefik ping matrix-synapse

# Restart all services
cd /opt/services
docker-compose restart
```

### Issue 4: Port conflicts
**Symptoms:** Services won't start, "address already in use"

**Fix:**
```bash
# Check what's using ports
netstat -tlnp | grep -E ":(80|443|8008|8448)"

# Stop and restart services
cd /opt/services
docker-compose down
docker-compose up -d
```

## Emergency Recovery:

If nothing works, revert the experimental_features:

```bash
# SSH to server
ssh root@YOUR_SERVER_IP

# Backup current config
cp /opt/services/matrix/synapse/homeserver.yaml /tmp/homeserver.yaml.broken

# Remove experimental features block
sed -i '/# BEGIN ANSIBLE MANAGED BLOCK/,/# END ANSIBLE MANAGED BLOCK/d' /opt/services/matrix/synapse/homeserver.yaml

# Restart services
cd /opt/services
docker-compose restart matrix-synapse

# Check if it works
docker logs matrix-synapse -f
curl http://localhost:8008/health
```

## After fixing, test:

```bash
# Test Matrix API
curl https://matrix.yourdomain.com/_matrix/client/versions

# Test well-known
curl https://yourdomain.com/.well-known/matrix/client
curl https://yourdomain.com/.well-known/matrix/server

# Test Element
# Open https://chat.yourdomain.com in browser
```

## Get detailed logs:

```bash
# Full Synapse logs
docker logs matrix-synapse > /tmp/synapse.log

# Specific errors
docker logs matrix-synapse 2>&1 | grep -E "ERROR|CRITICAL|Exception" > /tmp/synapse-errors.log

# Traefik logs
docker logs traefik > /tmp/traefik.log

# View live logs
docker logs matrix-synapse -f
```
