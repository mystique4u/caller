#!/bin/bash
# Pre-push validation script - Run all pipeline checks locally before pushing
# This mirrors the GitHub Actions pipeline validation steps

# Note: Don't use 'set -e' here since we handle errors manually

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           🚀 PRE-PUSH VALIDATION CHECKS                       ║"
echo "║        Running all pipeline checks locally...                 ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Track overall status
CHECKS_PASSED=0
CHECKS_FAILED=0

# Function to print section headers
print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Function to handle check results
check_result() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1 passed${NC}"
        ((CHECKS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ $1 failed${NC}"
        ((CHECKS_FAILED++))
        return 1
    fi
}

# ═══════════════════════════════════════════════════════════════
# 1. CODE QUALITY CHECKS
# ═══════════════════════════════════════════════════════════════
print_section "1️⃣  CODE QUALITY CHECKS"

echo "🔍 Scanning for potential hardcoded secrets..."
if grep -r -i -E "(password|secret|api_key|token).*=.*['\"][^'\"]{8,}['\"]" \
  --exclude="*.example" \
  --exclude="*.sample" \
  --exclude="*.template" \
  --exclude="README.md" \
  --exclude="*.svg" \
  --exclude="*.backup" \
  --exclude-dir="node_modules" \
  --exclude-dir=".git" \
  --exclude-dir="icons" \
  terraform/ ansible/ routemaker/ 2>/dev/null | \
  grep -v "^[[:space:]]*#" | \
  grep -v "^[[:space:]]*//" | \
  grep -v "lookup('env'" | \
  grep -v "lookup('password'" | \
  grep -v "secrets\." | \
  grep -v "SESSION_SECRET" | \
  grep -v "change-me-in-production" | \
  grep -v "type=\"password\"" | \
  grep -v "getElementById.*password" | \
  grep -v "questionHidden.*[Pp]assword" | \
  grep -v "passwordConfirm" ; then
  echo -e "${RED}❌ Found hardcoded secrets (review above)${NC}"
  ((CHECKS_FAILED++))
else
  echo -e "${GREEN}✅ No hardcoded secrets detected${NC}"
  ((CHECKS_PASSED++))
fi

echo ""
echo "🔍 Checking file permissions..."
if find . -type f \( -name "*.tf" -o -name "*.yml" -o -name "*.yaml" \) -executable 2>/dev/null | grep -v node_modules | grep -q .; then
  echo -e "${YELLOW}⚠️  Warning: Found executable config files${NC}"
  find . -type f \( -name "*.tf" -o -name "*.yml" -o -name "*.yaml" \) -executable 2>/dev/null | grep -v node_modules | head -5
  # Not a critical failure
else
  echo -e "${GREEN}✅ File permissions OK${NC}"
  ((CHECKS_PASSED++))
fi

echo ""
echo "🔍 Validating Ansible syntax..."
if command -v ansible-playbook &> /dev/null; then
  ANSIBLE_FAILED=0
  for playbook in ansible/*.yml; do
    if [ -f "$playbook" ]; then
      if ansible-playbook --syntax-check "$playbook" > /dev/null 2>&1; then
        check_result "$(basename $playbook)"
      else
        ((ANSIBLE_FAILED++))
      fi
    fi
  done
  if [ $ANSIBLE_FAILED -gt 0 ]; then
    echo -e "${RED}❌ $ANSIBLE_FAILED Ansible playbooks failed syntax check${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  Ansible not installed - skipping syntax check${NC}"
  echo "   Install with: pip install ansible"
  # Not considered a failure if Ansible is not installed
  ((CHECKS_PASSED++))
fi

# ═══════════════════════════════════════════════════════════════
# 2. TERRAFORM VALIDATION
# ═══════════════════════════════════════════════════════════════
print_section "2️⃣  TERRAFORM VALIDATION"

cd terraform

echo "🔍 Checking Terraform formatting..."
terraform fmt -check -recursive > /dev/null 2>&1
check_result "Terraform formatting"

echo ""
echo "🔧 Initializing Terraform..."
terraform init > /dev/null 2>&1
check_result "Terraform init"

echo ""
echo "🔍 Validating Terraform configuration..."
terraform validate -no-color > /dev/null 2>&1
check_result "Terraform validate"

cd ..

# ═══════════════════════════════════════════════════════════════
# 3. SECURITY SCANNING
# ═══════════════════════════════════════════════════════════════
print_section "3️⃣  SECURITY SCANNING"

echo "🔍 Checking for exposed database ports..."
cd terraform
SECURITY_ISSUES=0
for port in 3306 5432 27017 6379 9200; do
  if grep -B5 -A5 -E "port[[:space:]]*= \"${port}\"" main.tf 2>/dev/null | grep "0.0.0.0/0" | grep -v "#" > /dev/null 2>&1; then
    echo -e "${RED}❌ Database port $port exposed to internet!${NC}"
    ((SECURITY_ISSUES++))
  fi
done

if [ $SECURITY_ISSUES -eq 0 ]; then
  echo -e "${GREEN}✅ No exposed database ports${NC}"
  ((CHECKS_PASSED++))
else
  echo -e "${RED}❌ Found $SECURITY_ISSUES security issues${NC}"
  ((CHECKS_FAILED++))
fi

cd ..

# ═══════════════════════════════════════════════════════════════
# 4. ROUTEMAKER VALIDATION (if exists)
# ═══════════════════════════════════════════════════════════════
if [ -d "routemaker" ]; then
  print_section "4️⃣  ROUTEMAKER VALIDATION"
  
  cd routemaker
  
  echo "🔍 Validating JavaScript syntax..."
  node -c server.js > /dev/null 2>&1
  check_result "server.js syntax"
  
  node -c manage-users.js > /dev/null 2>&1
  check_result "manage-users.js syntax"
  
  node -c public/app.js > /dev/null 2>&1
  check_result "public/app.js syntax"
  
  echo ""
  echo "🔍 Validating package.json..."
  cat package.json | python3 -m json.tool > /dev/null 2>&1
  check_result "package.json format"
  
  cd ..
fi

# ═══════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    📊 VALIDATION SUMMARY                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "  ${GREEN}✅ Passed: $CHECKS_PASSED${NC}"
echo -e "  ${RED}❌ Failed: $CHECKS_FAILED${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║            ✅ ALL CHECKS PASSED - READY TO PUSH! 🚀           ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    exit 0
else
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║      ❌ VALIDATION FAILED - FIX ISSUES BEFORE PUSHING         ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Fix the issues above and run this script again before pushing."
    exit 1
fi
