#!/bin/bash
# Health check script for all services

set -e

echo "=========================================="
echo "Service Health Check"
echo "=========================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if we're on the server or need to SSH
if [ -f "/opt/services/docker-compose.yml" ]; then
    REMOTE=""
else
    echo "Run this script on the server, or specify SSH host:"
    echo "Usage: ./health-check.sh [user@host]"
    if [ -n "$1" ]; then
        REMOTE="ssh $1"
    else
        exit 1
    fi
fi

# Function to check if a container is running
check_container() {
    local container=$1
    local status=$($REMOTE docker ps --filter name=$container --format "{{.Status}}" 2>/dev/null || echo "not found")
    
    if [[ $status == *"Up"* ]]; then
        echo -e "${GREEN}✓${NC} $container: Running ($status)"
        return 0
    else
        echo -e "${RED}✗${NC} $container: Not running ($status)"
        return 1
    fi
}

# Function to check HTTP endpoint
check_http() {
    local url=$1
    local name=$2
    local status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 $url 2>/dev/null || echo "000")
    
    if [ "$status" -ge 200 ] && [ "$status" -lt 500 ]; then
        echo -e "${GREEN}✓${NC} $name: HTTP $status"
        return 0
    else
        echo -e "${RED}✗${NC} $name: HTTP $status (unreachable)"
        return 1
    fi
}

echo "1. Docker Container Status"
echo "-----------------------------------"
check_container "traefik"
check_container "matrix-synapse"
check_container "matrix-postgres"
check_container "element"
check_container "well-known"
check_container "livekit"
check_container "matrix-rtc"
check_container "coturn"
check_container "jitsi-web"
check_container "wireguard-ui"
echo ""

echo "2. Matrix Synapse Health"
echo "-----------------------------------"
if $REMOTE docker exec matrix-synapse curl -s http://localhost:8008/health >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Synapse internal health check: OK"
else
    echo -e "${RED}✗${NC} Synapse internal health check: FAILED"
fi

# Check Synapse logs for errors
echo "Recent Synapse errors:"
$REMOTE docker logs matrix-synapse --tail 20 2>&1 | grep -i "error\|exception\|failed" | tail -5 || echo "No recent errors"
echo ""

echo "3. Database Connection"
echo "-----------------------------------"
if $REMOTE docker exec matrix-postgres pg_isready -U synapse >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} PostgreSQL: Ready"
else
    echo -e "${RED}✗${NC} PostgreSQL: Not ready"
fi
echo ""

echo "4. Traefik Status"
echo "-----------------------------------"
$REMOTE docker logs traefik --tail 20 2>&1 | grep -i "error\|warn" | tail -5 || echo "No recent errors"
echo ""

echo "5. Configuration Files"
echo "-----------------------------------"
if $REMOTE test -f /opt/services/matrix/synapse/homeserver.yaml; then
    echo -e "${GREEN}✓${NC} homeserver.yaml exists"
    
    # Check for critical settings
    if $REMOTE grep -q "public_baseurl" /opt/services/matrix/synapse/homeserver.yaml; then
        echo -e "${GREEN}✓${NC} public_baseurl is configured"
    else
        echo -e "${YELLOW}⚠${NC} public_baseurl not found"
    fi
    
    # Check for syntax errors in experimental_features
    if $REMOTE grep -A 5 "experimental_features:" /opt/services/matrix/synapse/homeserver.yaml | grep -q "msc"; then
        echo -e "${GREEN}✓${NC} experimental_features configured"
    else
        echo -e "${YELLOW}⚠${NC} experimental_features not found or incomplete"
    fi
else
    echo -e "${RED}✗${NC} homeserver.yaml not found"
fi

if $REMOTE test -f /opt/services/well-known/matrix/client; then
    echo -e "${GREEN}✓${NC} .well-known/matrix/client exists"
else
    echo -e "${RED}✗${NC} .well-known/matrix/client not found"
fi

if $REMOTE test -f /opt/services/well-known/matrix/server; then
    echo -e "${GREEN}✓${NC} .well-known/matrix/server exists"
else
    echo -e "${RED}✗${NC} .well-known/matrix/server not found"
fi
echo ""

echo "6. Port Accessibility (from inside server)"
echo "-----------------------------------"
$REMOTE netstat -tlnp 2>/dev/null | grep -E ":(80|443|8008|8448|7880|7881)" || echo "No listening ports found"
echo ""

echo "=========================================="
echo "Quick Fixes"
echo "=========================================="
echo ""
echo "If services are down, try:"
echo "  cd /opt/services && docker-compose restart"
echo ""
echo "If configuration is invalid:"
echo "  cd /opt/services && docker-compose logs matrix-synapse"
echo ""
echo "To view full Synapse config:"
echo "  docker exec matrix-synapse cat /data/homeserver.yaml | grep -A 10 experimental"
echo ""
