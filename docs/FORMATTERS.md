# Code Formatting Tools

All code formatters are now installed and ready to use!

## 🔧 Installed Tools

### Terraform Formatter

```bash
terraform fmt -recursive
terraform fmt -check -diff  # Check without modifying
```

### Shell Script Formatter (shfmt)

```bash
shfmt -w script.sh          # Format a file
shfmt -w scripts/*.sh       # Format all scripts
```

### Shell Script Linter (shellcheck)

```bash
shellcheck script.sh        # Check a file
shellcheck scripts/*.sh     # Check all scripts
```

### YAML Linter (yamllint)

```bash
yamllint file.yml           # Check a file
yamllint .github/           # Check directory
```

### Python Formatter (autopep8)

```bash
autopep8 --in-place --aggressive --aggressive script.py
```

### Markdown/JSON/YAML Formatter (prettier)

```bash
prettier --write "*.md"     # Format markdown
prettier --write "*.json"   # Format JSON
prettier --check "*.md"     # Check without modifying
```

## 🚀 Quick Format Everything

Run the automated script:

```bash
./scripts/format-all.sh
```

This will:

- ✅ Format all Terraform files
- ✅ Check YAML syntax
- ✅ Format shell scripts
- ✅ Check shell scripts with shellcheck
- ✅ Format Python files
- ✅ Format Markdown files

## 📝 Pre-Commit Hook (Optional)

To automatically format before each commit, create `.git/hooks/pre-commit`:

```bash
#!/bin/bash
./scripts/format-all.sh
git add -A
```

Then make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

## 🔍 Tool Versions

```
Terraform: v1.14.5
shfmt: 3.8.0
shellcheck: 0.9.0
yamllint: 1.33.0
autopep8: 2.0.4
prettier: 3.8.1
```

## 📚 Documentation Links

- [Terraform fmt](https://developer.hashicorp.com/terraform/cli/commands/fmt)
- [shfmt](https://github.com/mvdan/sh)
- [shellcheck](https://www.shellcheck.net/)
- [yamllint](https://yamllint.readthedocs.io/)
- [autopep8](https://github.com/hhatto/autopep8)
- [prettier](https://prettier.io/)

## 🎯 Usage Examples

### Format before committing

```bash
./scripts/format-all.sh
git add -A
git commit -m "Your message"
git push
```

### Check Terraform syntax

```bash
cd terraform
terraform fmt -check
terraform validate
```

### Fix shell script issues

```bash
shfmt -w scripts/*.sh
shellcheck scripts/*.sh
```

### Format documentation

```bash
prettier --write "**/*.md"
```

## ⚠️ Common Issues

### YAML warnings about line length

These are non-critical. Lines over 80 characters are flagged but won't break anything.

### ShellCheck info messages

`SC2162: read without -r` - These are style suggestions, not errors.

### Prettier not formatting

Make sure you're in the repository root directory when running prettier.

## 🤝 Contributing

After making changes, always run:

```bash
./scripts/format-all.sh
```

This ensures consistent code style across the repository.
