#!/bin/bash
#
# SMTP Mail Server Quick Setup Script
# =====================================
# This script helps you quickly set up the SMTP mail server
# after deployment.
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOMAIN="${DOMAIN_NAME:-example.com}"
SERVER_IP="${SERVER_IP:-}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    SMTP Mail Server Setup Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to print colored messages
info() {
    echo -e "${BLUE}ℹ${NC}  $1"
}

success() {
    echo -e "${GREEN}✓${NC}  $1"
}

warning() {
    echo -e "${YELLOW}⚠${NC}  $1"
}

error() {
    echo -e "${RED}✗${NC}  $1"
}

# Check if running on server or locally
if [ -f /opt/services/mailserver/setup-email.sh ]; then
    ON_SERVER=true
    info "Running on server"
else
    ON_SERVER=false
    info "Running locally - will use SSH to connect to server"
fi

# Get domain and server IP if not set
if [ -z "$DOMAIN" ] || [ "$DOMAIN" = "example.com" ]; then
    echo ""
    read -p "Enter your domain name (e.g., example.com): " DOMAIN
fi

if [ "$ON_SERVER" = false ]; then
    if [ -z "$SERVER_IP" ]; then
        read -p "Enter your server IP address: " SERVER_IP
    fi
fi

echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  Domain: $DOMAIN"
[ "$ON_SERVER" = false ] && echo "  Server: $SERVER_IP"
echo ""

# Function to add email account
add_email_account() {
    local email=$1
    
    info "Adding email account: $email"
    
    if [ "$ON_SERVER" = true ]; then
        /opt/services/mailserver/setup-email.sh add "$email"
    else
        ssh root@$SERVER_IP "/opt/services/mailserver/setup-email.sh add $email"
    fi
    
    success "Email account created: $email"
}

# Function to generate DKIM keys
generate_dkim() {
    info "Generating DKIM keys..."
    
    if [ "$ON_SERVER" = true ]; then
        /opt/services/mailserver/generate-dkim.sh
    else
        ssh root@$SERVER_IP "/opt/services/mailserver/generate-dkim.sh"
    fi
}

# Main menu
show_menu() {
    echo ""
    echo -e "${GREEN}What would you like to do?${NC}"
    echo ""
    echo "  1) Add noreply@$DOMAIN account"
    echo "  2) Add custom email account"
    echo "  3) List all email accounts"
    echo "  4) Generate DKIM keys and show DNS record"
    echo "  5) Show DNS configuration summary"
    echo "  6) Test SMTP server"
    echo "  7) View mail server logs"
    echo "  8) Exit"
    echo ""
}

# Function to show DNS summary
show_dns_summary() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}    DNS Records Configuration${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    echo -e "${GREEN}1. A Record (Mail Server):${NC}"
    echo "   Type: A"
    echo "   Host: mail.$DOMAIN"
    echo "   Value: $SERVER_IP"
    echo "   TTL: 3600"
    echo ""
    
    echo -e "${GREEN}2. MX Record:${NC}"
    echo "   Type: MX"
    echo "   Host: $DOMAIN"
    echo "   Priority: 10"
    echo "   Value: mail.$DOMAIN"
    echo "   TTL: 3600"
    echo ""
    
    echo -e "${GREEN}3. SPF Record:${NC}"
    echo "   Type: TXT"
    echo "   Host: $DOMAIN"
    echo "   Value: v=spf1 mx ip4:$SERVER_IP ~all"
    echo "   TTL: 3600"
    echo ""
    
    echo -e "${GREEN}4. DKIM Record:${NC}"
    echo "   Generate with option 4 in menu"
    echo ""
    
    echo -e "${GREEN}5. DMARC Record:${NC}"
    echo "   Type: TXT"
    echo "   Host: _dmarc.$DOMAIN"
    echo "   Value: v=DMARC1; p=quarantine; rua=mailto:postmaster@$DOMAIN"
    echo "   TTL: 3600"
    echo ""
    
    info "Full guide: docs/SMTP_GUIDE.md"
    info "SPF details: docs/SPF_RECORDS_GUIDE.md"
}

# Function to test SMTP server
test_smtp() {
    echo ""
    info "Testing SMTP server connection..."
    
    if command -v telnet &> /dev/null; then
        timeout 5 telnet mail.$DOMAIN 587 &> /dev/null && \
            success "SMTP server is responding on port 587" || \
            error "Cannot connect to SMTP server on port 587"
    else
        warning "telnet not installed, skipping connection test"
    fi
    
    if command -v dig &> /dev/null; then
        echo ""
        info "Checking DNS records..."
        
        # Check A record
        if dig +short mail.$DOMAIN | grep -q '.'; then
            success "A record found: $(dig +short mail.$DOMAIN)"
        else
            warning "A record not found for mail.$DOMAIN"
        fi
        
        # Check MX record
        if dig +short MX $DOMAIN | grep -q '.'; then
            success "MX record found: $(dig +short MX $DOMAIN)"
        else
            warning "MX record not found for $DOMAIN"
        fi
        
        # Check SPF record
        if dig +short TXT $DOMAIN | grep -q 'spf'; then
            success "SPF record found"
            dig +short TXT $DOMAIN | grep spf
        else
            warning "SPF record not found for $DOMAIN"
        fi
    else
        warning "dig not installed, skipping DNS checks"
    fi
}

# Function to view logs
view_logs() {
    info "Viewing mail server logs (Ctrl+C to exit)..."
    
    if [ "$ON_SERVER" = true ]; then
        docker logs -f mailserver
    else
        ssh root@$SERVER_IP "docker logs -f mailserver"
    fi
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice [1-8]: " choice
    
    case $choice in
        1)
            add_email_account "noreply@$DOMAIN"
            ;;
        2)
            read -p "Enter email address (e.g., support@$DOMAIN): " custom_email
            add_email_account "$custom_email"
            ;;
        3)
            info "Listing email accounts..."
            if [ "$ON_SERVER" = true ]; then
                /opt/services/mailserver/setup-email.sh list
            else
                ssh root@$SERVER_IP "/opt/services/mailserver/setup-email.sh list"
            fi
            ;;
        4)
            generate_dkim
            ;;
        5)
            show_dns_summary
            ;;
        6)
            test_smtp
            ;;
        7)
            view_logs
            ;;
        8)
            success "Setup complete!"
            echo ""
            info "Next steps:"
            echo "  1. Configure DNS records (option 5)"
            echo "  2. Wait for DNS propagation (up to 48 hours)"
            echo "  3. Test with mail-tester.com"
            echo "  4. Use SMTP in your applications"
            echo ""
            info "Documentation: docs/SMTP_GUIDE.md"
            exit 0
            ;;
        *)
            error "Invalid option. Please choose 1-8."
            ;;
    esac
done
