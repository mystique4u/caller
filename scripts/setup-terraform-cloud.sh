#!/bin/bash
# Terraform Cloud Setup Helper

echo "☁️  Terraform Cloud Setup Helper"
echo "================================"
echo ""

# Check if organization and workspace names are correct
echo "📋 Current Configuration:"
echo "   Organization: itin"
echo "   Workspace: hetznercloud"
echo ""

read -p "Are these correct? (y/n): " CORRECT

if [ "$CORRECT" != "y" ]; then
	read -p "Enter your organization name: " ORG_NAME
	read -p "Enter your workspace name: " WORKSPACE_NAME

	echo ""
	echo "⚠️  You need to update terraform/main.tf with:"
	echo "   organization = \"$ORG_NAME\""
	echo "   workspace name = \"$WORKSPACE_NAME\""
	echo ""
	exit 0
fi

echo ""
echo "🔑 Step 1: Get Terraform Cloud API Token"
echo "----------------------------------------"
echo "1. Go to: https://app.terraform.io/app/settings/tokens"
echo "2. Click 'Create an API token'"
echo "3. Description: 'GitHub Actions - caller'"
echo "4. Copy the token"
echo ""
read -p "Have you created the API token? (y/n): " HAS_TOKEN

if [ "$HAS_TOKEN" == "y" ]; then
	echo ""
	echo "✅ Great! Now add it to GitHub:"
	echo "   Go to: https://github.com/mystique4u/caller/settings/secrets/actions"
	echo "   Name: TF_API_TOKEN"
	echo "   Value: <paste your token>"
	echo ""
fi

echo ""
echo "⚙️  Step 2: Configure Workspace Variables"
echo "----------------------------------------"
echo "Go to: https://app.terraform.io/app/itin/workspaces/hetznercloud/variables"
echo ""
echo "Add these Terraform variables:"
echo ""
echo "1. hcloud_token"
echo "   Value: <your Hetzner API token>"
echo "   Sensitive: ✅ YES"
echo ""
echo "2. firewall_name"
echo "   Value: default-firewall"
echo "   Sensitive: ❌ NO"
echo ""
echo "3. ssh_key_ids"
echo "   Value: [108153935]"
echo "   Sensitive: ❌ NO"
echo ""
echo "4. domain_name (optional)"
echo "   Value: vpn.example.com"
echo "   Sensitive: ❌ NO"
echo ""
read -p "Have you added the workspace variables? (y/n): " HAS_VARS

echo ""
echo "🧪 Step 3: Test Configuration"
echo "-----------------------------"
echo ""
read -p "Do you want to test Terraform Cloud login? (y/n): " TEST_LOGIN

if [ "$TEST_LOGIN" == "y" ]; then
	echo ""
	echo "Running: terraform login"
	echo ""
	cd ../terraform
	terraform login

	if [ $? -eq 0 ]; then
		echo ""
		echo "✅ Login successful!"
		echo ""
		echo "Testing backend initialization..."
		terraform init

		if [ $? -eq 0 ]; then
			echo ""
			echo "✅ Backend initialized successfully!"
			echo ""
			echo "Checking workspace..."
			terraform workspace list
		fi
	fi
fi

echo ""
echo "📋 Setup Summary"
echo "================"
echo ""
echo "✅ Checklist:"
echo "   [ ] Terraform Cloud account: https://app.terraform.io/"
echo "   [ ] Organization 'itin' exists"
echo "   [ ] Workspace 'hetznercloud' created"
echo "   [ ] API token created"
echo "   [ ] GitHub secret 'TF_API_TOKEN' added"
echo "   [ ] Workspace variables configured"
echo "   [ ] Local terraform login successful"
echo ""
echo "🚀 Next Steps:"
echo "   1. Commit and push your changes"
echo "   2. GitHub Actions will use Terraform Cloud"
echo "   3. State will be stored remotely"
echo ""
echo "📚 Documentation:"
echo "   - Setup Guide: docs/terraform-cloud-setup.md"
echo "   - Branch Protection: docs/branch-protection.md"
echo ""
echo "Done! 🎉"
