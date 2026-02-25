# 🔑 Creating a New SSH Key for Hetzner

## Quick Guide: Create & Add SSH Key

### Option 1: Using the Helper Script (Easiest)

```bash
# Run the helper script
./scripts/create-ssh-key.sh

# Follow the prompts:
# 1. Enter a name for your key (e.g., "hetzner-wireguard")
# 2. Enter your email
# 3. Choose a passphrase (or press Enter for no passphrase)
```

The script will:
- ✅ Create a new SSH key pair
- ✅ Display your public key
- ✅ Show you exactly what to do next

---

### Option 2: Manual Creation

#### Step 1: Create the SSH Key

```bash
# Create a new SSH key with a specific name
ssh-keygen -t ed25519 -f ~/.ssh/hetzner-wireguard -C "your-email@example.com"

# You'll be prompted:
# - Enter passphrase (recommended but optional)
# - Confirm passphrase
```

**What the options mean:**
- `-t ed25519` = Use modern, secure Ed25519 algorithm
- `-f ~/.ssh/hetzner-wireguard` = File name for your key
- `-C "email"` = Comment to identify the key

#### Step 2: View Your Public Key

```bash
# Display your public key
cat ~/.ssh/hetzner-wireguard.pub
```

**Copy the entire output** - it looks like:
```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJl3dIa... your-email@example.com
```

#### Step 3: Add to Hetzner Cloud Console

1. Go to: https://console.hetzner.cloud/
2. Navigate: **Security** → **SSH Keys**
3. Click **"Add SSH Key"** button
4. **Paste your public key** (from Step 2)
5. **Give it a name** in Hetzner (e.g., "WireGuard VPN Key")
6. Click **"Add SSH Key"**
7. **Note the ID number** that appears (e.g., 12345678)

---

## 📝 Using Multiple Keys

If you have several local SSH keys and want to use specific ones:

### List Your Existing Keys
```bash
# See all your SSH keys
ls -la ~/.ssh/*.pub

# Example output:
# ~/.ssh/id_ed25519.pub         ← Your default key
# ~/.ssh/work_laptop.pub        ← Work key
# ~/.ssh/personal_laptop.pub    ← Personal key
# ~/.ssh/hetzner-wireguard.pub  ← New Hetzner key
```

### Add Specific Key to Hetzner

Choose which key(s) you want to use:

```bash
# Display the specific key you want to add
cat ~/.ssh/hetzner-wireguard.pub

# Or if you want to use your existing default key
cat ~/.ssh/id_ed25519.pub
```

Then add it to Hetzner Console as shown above.

---

## 🎯 Configuration

### For Terraform (using the ID)

After adding your key to Hetzner and getting the ID:

**Edit `terraform/terraform.tfvars`:**
```hcl
# Single key
ssh_key_ids = [12345678]

# Multiple keys (add multiple IDs)
ssh_key_ids = [12345678, 87654321, 11223344]
```

### For GitHub Actions

**Add to GitHub Secrets:**

1. **`SSH_KEY_IDS`** (the Hetzner key IDs)
   ```json
   [12345678, 87654321]
   ```

2. **`SSH_PRIVATE_KEY`** (your private key for Ansible to connect)
   ```bash
   # Copy your private key content
   cat ~/.ssh/hetzner-wireguard
   
   # Or use your default key
   cat ~/.ssh/id_ed25519
   ```
   
   Paste the **entire content** (including BEGIN and END lines) into GitHub Secret.

---

## 🔐 SSH Key Best Practices

### ✅ DO:
- **Use different keys for different purposes**
  - `~/.ssh/id_ed25519` - Default/personal
  - `~/.ssh/work_rsa` - Work
  - `~/.ssh/hetzner-wireguard` - Hetzner VPN
  
- **Use strong passphrases** on private keys
- **Keep private keys secure** (never share or commit to git)
- **Add all relevant keys** to Hetzner (work + personal laptops)

### ❌ DON'T:
- Share private keys (files WITHOUT .pub extension)
- Commit private keys to git
- Use the same key everywhere
- Leave private keys unprotected

---

## 🛠️ SSH Config (Optional but Recommended)

Create `~/.ssh/config` to manage multiple keys:

```bash
# Hetzner WireGuard VPN Server
Host wireguard-vpn
    HostName YOUR_SERVER_IP
    User root
    IdentityFile ~/.ssh/hetzner-wireguard
    StrictHostKeyChecking no

# Default Hetzner connections
Host *.hetzner.cloud
    User root
    IdentityFile ~/.ssh/hetzner-wireguard
```

Then connect easily:
```bash
ssh wireguard-vpn
```

---

## 📋 Quick Reference

| Item | File Location | Use |
|------|--------------|-----|
| **Private Key** | `~/.ssh/hetzner-wireguard` | Keep secret, use for SSH connections |
| **Public Key** | `~/.ssh/hetzner-wireguard.pub` | Add to Hetzner Console |
| **Key ID** | From Hetzner Console | Use in `terraform.tfvars` |

### Commands Cheat Sheet
```bash
# Create new key
ssh-keygen -t ed25519 -f ~/.ssh/hetzner-wireguard -C "email@example.com"

# View public key
cat ~/.ssh/hetzner-wireguard.pub

# View private key (for GitHub Secret)
cat ~/.ssh/hetzner-wireguard

# List all keys
ls -la ~/.ssh/

# Test SSH connection
ssh -i ~/.ssh/hetzner-wireguard root@YOUR_SERVER_IP

# Get SSH key fingerprint
ssh-keygen -lf ~/.ssh/hetzner-wireguard.pub
```

---

## 🚀 Next Steps

After creating and adding your SSH key:

1. ✅ Create the SSH key (see above)
2. ✅ Add public key to Hetzner Console
3. ✅ Note the SSH Key ID
4. ✅ Update `terraform/terraform.tfvars` with the ID
5. ✅ Add private key to GitHub Secrets (if using Actions)
6. ✅ Deploy your WireGuard VPN! 🎉

---

**Need help?** Run the helper script: `./scripts/create-ssh-key.sh`
