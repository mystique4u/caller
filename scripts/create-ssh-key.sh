#!/bin/bash
# Script to create a new SSH key for Hetzner WireGuard VPN

echo "🔑 SSH Key Generator for Hetzner WireGuard VPN"
echo "=============================================="
echo ""

# Ask for key name
read -p "Enter a name for your SSH key (e.g., 'hetzner-wireguard'): " KEY_NAME
KEY_NAME=${KEY_NAME:-hetzner-wireguard}

# Ask for email
read -p "Enter your email address: " EMAIL
EMAIL=${EMAIL:-your-email@example.com}

# Define the file path
KEY_PATH="$HOME/.ssh/${KEY_NAME}"

echo ""
echo "📝 Creating new SSH key..."
echo "   Name: ${KEY_NAME}"
echo "   Location: ${KEY_PATH}"
echo ""

# Generate the SSH key
ssh-keygen -t ed25519 -f "${KEY_PATH}" -C "${EMAIL}"

echo ""
echo "✅ SSH Key created successfully!"
echo ""
echo "📋 Your PUBLIC key (copy this to Hetzner):"
echo "=============================================="
cat "${KEY_PATH}.pub"
echo "=============================================="
echo ""
echo "📌 Next steps:"
echo "1. Copy the PUBLIC key above"
echo "2. Go to: https://console.hetzner.cloud/"
echo "3. Navigate to: Security → SSH Keys → Add SSH Key"
echo "4. Paste the key and give it a name (e.g., 'Wireguard VPN Key')"
echo "5. Note the SSH Key ID number"
echo ""
echo "💾 Your keys are saved at:"
echo "   Private key: ${KEY_PATH}"
echo "   Public key:  ${KEY_PATH}.pub"
echo ""
echo "⚠️  IMPORTANT: Keep your private key secure!"
echo "   Never share or commit: ${KEY_PATH}"
echo ""
