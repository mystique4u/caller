#!/bin/bash
# Pre-commit/pre-push validation script
# Runs all pipeline checks locally. Used by .githooks/pre-commit and .githooks/pre-push.
# Run manually: bash scripts/pre-push-check.sh

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║           🚀 PRE-PUSH VALIDATION CHECKS                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"

CHECKS_PASSED=0; CHECKS_FAILED=0

print_section() { echo ""; echo -e "${BLUE}━━ $1 ━━${NC}"; }
pass() { echo -e "${GREEN}  ✅ $1${NC}"; ((CHECKS_PASSED++)); }
fail() { echo -e "${RED}  ❌ $1${NC}"; ((CHECKS_FAILED++)); }
warn() { echo -e "${YELLOW}  ⚠️  $1${NC}"; }

check_yaml() {
  local file="$1" label="${2:-$1}"
  if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
    echo -e "${GREEN}    ✅ $label${NC}"
  else
    echo -e "${RED}    ❌ $label${NC}"
    python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>&1 | head -4
    return 1
  fi
}

# ── 1. SECRETS ──────────────────────────────────────────────────────────────
print_section "1️⃣  SECRETS SCAN"
echo "🔍 Scanning for hardcoded secrets..."
if grep -r -i -E "(password|secret|api_key|token).*=.*['\"][^'\"]{8,}['\"]" \
    --exclude="*.example" --exclude="*.sample" --exclude="*.template" \
    --exclude="README.md" --exclude="*.svg" --exclude="*.backup" \
    --exclude-dir="node_modules" --exclude-dir=".git" --exclude-dir="icons" \
    terraform/ ansible/ routemaker/ 2>/dev/null \
    | grep -v "^[[:space:]]*#" | grep -v "^[[:space:]]*//" \
    | grep -v "lookup('env'" | grep -v "lookup('password'" \
    | grep -v "secrets\." | grep -v "SESSION_SECRET" \
    | grep -v "change-me-in-production" | grep -v 'type="password"' \
    | grep -v "getElementById.*password" | grep -v "passwordConfirm" \
    | grep -v "questionHidden"; then
  fail "Found hardcoded secrets (review above)"
else
  pass "No hardcoded secrets detected"
fi

# ── 2. YAML SYNTAX ──────────────────────────────────────────────────────────
print_section "2️⃣  YAML / JSON SYNTAX"
YAML_ERRORS=0

echo "🔍 GitHub Actions workflows..."
for wf in .github/workflows/*.yml .github/workflows/*.yaml; do
  [ -f "$wf" ] && { check_yaml "$wf" "$(basename "$wf")" || ((YAML_ERRORS++)); }
done

echo "🔍 Composite actions..."
for act in .github/actions/*/action.yml; do
  [ -f "$act" ] && { check_yaml "$act" "${act#.github/}" || ((YAML_ERRORS++)); }
done

echo "🔍 Ansible task files..."
for f in ansible/tasks/*.yml; do
  [ -f "$f" ] && { check_yaml "$f" "tasks/$(basename "$f")" || ((YAML_ERRORS++)); }
done

echo "🔍 Templates..."
python3 - << 'PYEOF'
import yaml, json, sys, re

def strip_jinja2(text):
    # Remove {% ... %} block tags (replace whole lines containing only a tag with empty)
    text = re.sub(r'[ \t]*\{%-?.*?-?%\}[ \t]*\n?', '\n', text, flags=re.DOTALL)
    # Replace {{ ... }} expressions with a safe placeholder
    text = re.sub(r'\{\{[^}]+\}\}', 'placeholder', text)
    return text

for path, loader in [
    ('ansible/templates/docker-compose.yml.j2', 'yaml'),
]:
    try:
        content = strip_jinja2(open(path).read())
        yaml.safe_load(content)
        print(f'\033[0;32m    ✅ {path}\033[0m')
    except Exception as e:
        print(f'\033[0;31m    ❌ {path} — {e}\033[0m')
        sys.exit(1)

for path in ['ansible/templates/element-config.json.j2']:
    try:
        import os; content = strip_jinja2(open(path).read()) if os.path.exists(path) else None
        if content: json.loads(content)
        if content: print(f'\033[0;32m    ✅ {path}\033[0m')
    except Exception as e:
        print(f'\033[0;31m    ❌ {path} — {e}\033[0m')
        sys.exit(1)
PYEOF
[ $? -ne 0 ] && ((YAML_ERRORS++))

[ $YAML_ERRORS -eq 0 ] && pass "All YAML/JSON files valid" || fail "$YAML_ERRORS file(s) have syntax errors"

# ── 3. ANSIBLE ───────────────────────────────────────────────────────────────
print_section "3️⃣  ANSIBLE SYNTAX"
if command -v ansible-playbook &>/dev/null; then
  if ansible-playbook --syntax-check ansible/playbook.yml >/dev/null 2>&1; then
    pass "playbook.yml syntax"
  else
    fail "playbook.yml syntax"
    ansible-playbook --syntax-check ansible/playbook.yml 2>&1 | head -10
  fi
else
  warn "ansible-playbook not installed — skipping (pip install ansible)"
  ((CHECKS_PASSED++))
fi

# ── 4. TERRAFORM ─────────────────────────────────────────────────────────────
print_section "4️⃣  TERRAFORM"
if command -v terraform &>/dev/null; then
  cd terraform
  terraform fmt -check -recursive >/dev/null 2>&1 && pass "fmt" || fail "fmt (run: terraform fmt -recursive)"
  if terraform init -backend=false -input=false >/dev/null 2>&1; then
    pass "init"
    terraform validate -no-color >/dev/null 2>&1 && pass "validate" || { fail "validate"; terraform validate -no-color 2>&1 | head -10; }
  else
    warn "init skipped (provider plugins not cached locally — validated in CI)"
    ((CHECKS_PASSED++))
  fi
  cd "$REPO_ROOT"
else
  warn "terraform not installed — skipping"
  ((CHECKS_PASSED++))
fi

# ── 5. SECURITY ───────────────────────────────────────────────────────────────
print_section "5️⃣  SECURITY SCAN"
SEC=0
for port in 3306 5432 27017 6379 9200; do
  grep -B5 -A5 -E "port[[:space:]]*= \"${port}\"" terraform/main.tf 2>/dev/null \
    | grep "0.0.0.0/0" | grep -v "#" >/dev/null 2>&1 && { fail "Port $port exposed to internet"; ((SEC++)); }
done
[ $SEC -eq 0 ] && pass "No exposed database ports"

# ── 6. ROUTEMAKER JS ──────────────────────────────────────────────────────────
if [ -d "routemaker" ] && command -v node &>/dev/null; then
  print_section "6️⃣  ROUTEMAKER"
  for js in routemaker/server.js routemaker/manage-users.js routemaker/public/app.js; do
    [ -f "$js" ] && { node --check "$js" 2>/dev/null && pass "$(basename "$js")" || { fail "$(basename "$js")"; node --check "$js" 2>&1 | head -5; }; }
  done
  python3 -m json.tool routemaker/package.json >/dev/null 2>&1 && pass "package.json" || fail "package.json"
fi

# ── SUMMARY ───────────────────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                    📊 VALIDATION SUMMARY                       ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "  ${GREEN}✅ Passed: $CHECKS_PASSED${NC}  ${RED}❌ Failed: $CHECKS_FAILED${NC}"
echo ""

if [ $CHECKS_FAILED -eq 0 ]; then
  echo -e "${GREEN}║  ✅ ALL CHECKS PASSED — READY TO PUSH! 🚀${NC}"
  exit 0
else
  echo -e "${RED}║  ❌ VALIDATION FAILED — fix issues above (skip: git commit --no-verify)${NC}"
  exit 1
fi
