#!/bin/bash
# Syntax checker for Ansible playbooks and templates

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Running syntax checks..."
echo ""

# Check if yamllint is available
if command -v yamllint &> /dev/null; then
    USE_YAMLLINT=true
    echo "✓ Using yamllint for validation"
else
    USE_YAMLLINT=false
    echo "⚠️  yamllint not found, using basic Python validation"
    echo "   Install with: sudo dnf install yamllint"
fi
echo ""

# 1. Check Ansible playbook syntax
echo "📋 Checking Ansible playbook..."
if ansible-playbook --syntax-check ansible/playbook.yml &> /dev/null; then
    echo -e "${GREEN}✅ ansible/playbook.yml${NC}"
else
    echo -e "${RED}❌ ansible/playbook.yml - Syntax error${NC}"
    ansible-playbook --syntax-check ansible/playbook.yml
    exit 1
fi
echo ""

# 2. Check task files
echo "📝 Checking task files..."
for file in ansible/tasks/*.yml; do
    filename=$(basename "$file")
    if $USE_YAMLLINT; then
        if yamllint "$file" 2>&1 | grep -q "error"; then
            echo -e "${RED}❌ $filename${NC}"
            yamllint "$file"
            exit 1
        else
            echo -e "${GREEN}✅ $filename${NC}"
        fi
    else
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo -e "${GREEN}✅ $filename${NC}"
        else
            echo -e "${RED}❌ $filename${NC}"
            python3 -c "import yaml; yaml.safe_load(open('$file'))"
            exit 1
        fi
    fi
done
echo ""

# 3. Check templates
echo "📄 Checking templates..."

# docker-compose.yml.j2
echo -n "Checking docker-compose.yml.j2... "
python3 << 'PYEOF'
import yaml, sys
try:
    with open('ansible/templates/docker-compose.yml.j2', 'r') as f:
        content = f.read()
        # Replace common Jinja2 variables
        for var in ['domain_name', 'jitsi_web_image', 'jitsi_prosody_image', 'jitsi_jicofo_image', 
                    'jitsi_jvb_image', 'matrix_postgres_image', 'postgres_password', 'matrix_synapse_image',
                    'matrix_registration_secret', 'element_web_image', 'livekit_image', 'lk_jwt_service_image',
                    'livekit_api_key', 'livekit_api_secret', 'coturn_image']:
            content = content.replace('{{ ' + var + ' }}', 'test')
        content = content.replace('{{ wireguard_ui_version }}', '0.6.2')
        content = content.replace('{{ email_address }}', 'test@test.com')
        content = content.replace('{{ wireguard_port }}', '51820')
        content = content.replace('{{ server_ip }}', '1.2.3.4')
        yaml.safe_load(content)
    print('\033[0;32m✅\033[0m')
except Exception as e:
    print(f'\033[0;31m❌\033[0m - {e}')
    sys.exit(1)
PYEOF

# element-config.json.j2
echo -n "Checking element-config.json.j2... "
python3 << 'PYEOF'
import json, sys
try:
    with open('ansible/templates/element-config.json.j2', 'r') as f:
        content = f.read().replace('{{ domain_name }}', 'example.com')
        json.loads(content)
    print('\033[0;32m✅\033[0m')
except Exception as e:
    print(f'\033[0;31m❌\033[0m - {e}')
    sys.exit(1)
PYEOF

# traefik.toml.j2
echo -n "Checking traefik.toml.j2... "
if [ -f ansible/templates/traefik.toml.j2 ]; then
    echo -e "${GREEN}✅${NC}"
else
    echo -e "${RED}❌ File not found${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All syntax checks passed!${NC}"

# 4. Check GitHub Actions workflows
echo ""
echo "🔄 Checking GitHub Actions workflows..."
WORKFLOW_ERRORS=0
for file in .github/workflows/*.yml; do
    filename=$(basename "$file")
    if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
        echo -e "${GREEN}✅ $filename${NC}"
    else
        echo -e "${RED}❌ $filename${NC}"
        python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>&1 | head -5
        WORKFLOW_ERRORS=1
    fi
done

# Check composite actions
for file in .github/actions/*/action.yml; do
    if [ -f "$file" ]; then
        filename=$(basename $(dirname "$file"))/action.yml
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo -e "${GREEN}✅ $filename${NC}"
        else
            echo -e "${RED}❌ $filename${NC}"
            python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>&1 | head -5
            WORKFLOW_ERRORS=1
        fi
    fi
done

if [ $WORKFLOW_ERRORS -eq 1 ]; then
    echo ""
    echo -e "${RED}❌ GitHub Actions workflow errors found${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🎉 All checks passed!${NC}"
