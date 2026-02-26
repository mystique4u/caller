# Terraform Cloud Setup Guide

## ☁️ Configure Terraform Cloud for State Management

You already have a Terraform Cloud account. Here's how to configure it:

---

## 📋 **Step 1: Create Organization & Workspace**

### A. Login to Terraform Cloud

1. Go to: https://app.terraform.io/
2. Login with your account

### B. Create/Verify Organization

1. Click on your profile → **Organizations**
2. If you have organization "itin" - great! Use it
3. If not, create new organization:
   - Click **"Create new organization"**
   - Name: `itin` (or your preferred name)
   - Click **"Create organization"**

### C. Create Workspace

1. In your organization, click **"New workspace"**
2. Choose workflow: **"Version control workflow"** or **"CLI-driven workflow"**
   - **Recommended**: CLI-driven workflow (for GitHub Actions)
3. Workspace name: `hetznercloud`
4. Click **"Create workspace"**

---

## 🔑 **Step 2: Get Terraform Cloud API Token**

### Create API Token:

1. Click your profile → **User Settings**
2. Go to **Tokens**
3. Click **"Create an API token"**
4. Description: `GitHub Actions - caller`
5. Copy the token (you'll need it for GitHub Secrets)

---

## ⚙️ **Step 3: Update Terraform Configuration**

Your `terraform/main.tf` already has the backend configured:

```hcl
terraform {
  backend "remote" {
    organization = "itin"  # ← Your organization name

    workspaces {
      name = "hetznercloud"  # ← Your workspace name
    }
  }
}
```

### If You Need to Change Organization/Workspace:

Edit `terraform/main.tf` and update:

```hcl
terraform {
  backend "remote" {
    organization = "your-org-name"  # ← Change this

    workspaces {
      name = "your-workspace-name"  # ← Change this
    }
  }
}
```

---

## 🔐 **Step 4: Configure Workspace Variables**

In Terraform Cloud workspace settings, add these variables:

### A. Go to Workspace Settings

1. Open workspace: `hetznercloud`
2. Go to **Variables** tab

### B. Add Terraform Variables (Sensitive):

| Variable Name   | Value                        | Sensitive | Category  |
| --------------- | ---------------------------- | --------- | --------- |
| `hcloud_token`  | Your Hetzner API token       | ✅ Yes    | Terraform |
| `firewall_name` | `default-firewall`           | ❌ No     | Terraform |
| `ssh_key_ids`   | `[108153935]`                | ❌ No     | Terraform |
| `domain_name`   | `vpn.example.com` (optional) | ❌ No     | Terraform |

**How to add:**

1. Click **"Add variable"**
2. Select **"Terraform variable"**
3. Enter variable name (without `TF_VAR_` prefix)
4. Enter value
5. Check **"Sensitive"** if needed
6. Click **"Save variable"**

---

## 🔗 **Step 5: Add Terraform Cloud Token to GitHub**

### Add GitHub Secret:

1. Go to: https://github.com/mystique4u/caller/settings/secrets/actions
2. Click **"New repository secret"**
3. Name: `TF_API_TOKEN`
4. Value: Your Terraform Cloud API token (from Step 2)
5. Click **"Add secret"**

---

## 📝 **Step 6: Update GitHub Actions Workflow**

I'll update your workflow to use Terraform Cloud:

```yaml
env:
  TERRAFORM_VERSION: "1.6.0"
  TF_API_TOKEN: ${{ secrets.TF_API_TOKEN }} # ← Add this


  # Remove these - they'll be in Terraform Cloud workspace
  # TF_VAR_hcloud_token: ${{ secrets.HCLOUD_TOKEN }}
  # TF_VAR_firewall_name: ${{ secrets.FIREWALL_NAME }}
  # TF_VAR_ssh_key_ids: ${{ secrets.SSH_KEY_IDS }}
  # TF_VAR_domain_name: ${{ secrets.WIREGUARD_DOMAIN }}
```

---

## 🧪 **Step 7: Test the Setup**

### A. Local Test (Optional):

```bash
cd terraform

# Login to Terraform Cloud
terraform login
# Paste your API token when prompted

# Initialize
terraform init

# Verify backend connection
terraform workspace list

# Test plan
terraform plan
```

### B. GitHub Actions Test:

```bash
# Commit and push
git add .
git commit -m "Configure Terraform Cloud backend"
git push origin main

# Watch GitHub Actions run
# Go to: https://github.com/mystique4u/caller/actions
```

---

## 🎯 **Benefits of Terraform Cloud:**

✅ **Remote State Management**

- State stored securely in the cloud
- No need to manage state files locally
- Automatic state locking

✅ **Team Collaboration**

- Multiple people can work safely
- State locking prevents conflicts
- Audit logs for all changes

✅ **Secure Variable Storage**

- Sensitive values encrypted
- Never stored in GitHub
- Centralized management

✅ **State History**

- Keep track of all state versions
- Rollback if needed
- Audit trail

---

## 🔧 **Workflow Options:**

### Option 1: CLI-Driven (Recommended for GitHub Actions)

- GitHub Actions triggers Terraform
- State managed in Terraform Cloud
- Variables in Terraform Cloud workspace

### Option 2: VCS-Driven (Alternative)

- Connect Terraform Cloud directly to GitHub
- Terraform Cloud watches for changes
- Auto-runs on PR/merge

---

## 📊 **Workspace Settings:**

### Execution Mode:

- **Local**: Terraform runs on your machine/GitHub Actions
- **Remote**: Terraform runs on Terraform Cloud servers

**Recommended**: **Local** (for GitHub Actions)

### Apply Method:

- **Auto apply**: Automatically applies after plan
- **Manual apply**: Requires manual approval

**Recommended**: **Manual apply** (for production safety)

---

## 🆘 **Troubleshooting:**

### "Error: No valid credential sources"

```bash
# Run locally:
terraform login

# Or set environment variable:
export TF_TOKEN_app_terraform_io="your-token"
```

### "Error: workspace not found"

- Verify organization name in `main.tf`
- Verify workspace name in `main.tf`
- Check workspace exists in Terraform Cloud

### "Error: backend initialization required"

```bash
terraform init -reconfigure
```

---

## 📋 **Quick Setup Checklist:**

- [ ] Terraform Cloud account created
- [ ] Organization created/verified: `itin`
- [ ] Workspace created: `hetznercloud`
- [ ] API token generated
- [ ] Workspace variables added (hcloud_token, firewall_name, ssh_key_ids)
- [ ] GitHub secret added: `TF_API_TOKEN`
- [ ] GitHub Actions workflow updated
- [ ] Test run successful

---

## 🔗 **Useful Links:**

- Terraform Cloud: https://app.terraform.io/
- Documentation: https://developer.hashicorp.com/terraform/cloud-docs
- CLI Configuration: https://developer.hashicorp.com/terraform/cli/cloud

---

**Ready to configure?** Let me know if you need help with any step!
