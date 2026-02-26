#!/bin/bash
# Format all code files in the repository

set -e

echo "🔧 Formatting repository files..."
echo ""

# Format Terraform files
echo "📄 Formatting Terraform files..."
cd terraform
terraform fmt -recursive
cd ..
echo "✅ Terraform files formatted"
echo ""

# Format YAML files
echo "📄 Checking YAML files..."
if yamllint -d relaxed .github/ ansible/ 2>/dev/null; then
	echo "✅ YAML files are valid"
else
	echo "⚠️  YAML files have warnings (non-critical)"
fi
echo ""

# Format shell scripts
echo "📄 Formatting shell scripts..."
find . -name "*.sh" -type f -exec shfmt -w {} \;
echo "✅ Shell scripts formatted"
echo ""

# Check shell scripts for issues
echo "📄 Checking shell scripts with shellcheck..."
if find . -name "*.sh" -type f -exec shellcheck {} \; 2>/dev/null; then
	echo "✅ Shell scripts passed shellcheck"
else
	echo "⚠️  Shell scripts have warnings (non-critical)"
fi
echo ""

# Format Python files
echo "📄 Formatting Python files..."
if find . -name "*.py" -type f | grep -q .; then
	find . -name "*.py" -type f -exec autopep8 --in-place --aggressive --aggressive {} \;
	echo "✅ Python files formatted"
else
	echo "ℹ️  No Python files found"
fi
echo ""

# Format Markdown files
echo "📄 Formatting Markdown files..."
if command -v prettier &>/dev/null; then
	prettier --write "*.md" "docs/*.md" 2>/dev/null || true
	echo "✅ Markdown files formatted"
else
	echo "ℹ️  Prettier not available for Markdown"
fi
echo ""

echo "✨ Formatting complete!"
echo ""
echo "Summary of installed formatters:"
echo "  - terraform: $(terraform version | head -n1)"
echo "  - shfmt: $(shfmt --version)"
echo "  - shellcheck: $(shellcheck --version | head -n2 | tail -n1)"
echo "  - yamllint: $(yamllint --version)"
echo "  - autopep8: $(autopep8 --version)"
if command -v prettier &>/dev/null; then
	echo "  - prettier: $(prettier --version)"
fi
