# How to Add SSH Key to Hetzner Cloud and Get the ID

## Step 1: Generate SSH Key (if you don't have one)

### On Linux/Mac:

```bash
# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.com"

# Press Enter to accept default location (~/.ssh/id_ed25519)
# Enter a passphrase (optional but recommended)

# Display your public key
cat ~/.ssh/id_ed25519.pub
```

### On Windows (PowerShell):

```powershell
# Generate a new SSH key pair
ssh-keygen -t ed25519 -C "your-email@example.com"

# Press Enter to accept default location (C:\Users\YourName\.ssh\id_ed25519)
# Enter a passphrase (optional but recommended)

# Display your public key
type $env:USERPROFILE\.ssh\id_ed25519.pub
```

**Your public key will look like:**

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJl3dI... your-email@example.com
```

## Step 2: Add SSH Key to Hetzner Cloud Console

### Method A: Via Web Console (Recommended for Beginners)

1. **Login to Hetzner Cloud Console**
   - Go to: https://console.hetzner.cloud/
   - Login with your credentials

2. **Navigate to SSH Keys Section**
   - Click on your project name
   - In the left sidebar, click **"Security"**
   - Click on **"SSH Keys"** tab

3. **Add Your SSH Key**
   - Click the **"Add SSH Key"** button (top right)
   - Paste your **public key** (the content from `cat ~/.ssh/id_ed25519.pub`)
   - Give it a name (e.g., "My Laptop", "Work Computer")
   - Click **"Add SSH Key"**

4. **Note the SSH Key ID**
   - After adding, you'll see your SSH key in the list
   - The **ID** is displayed in the list (usually a number like `12345678`)
   - **Write this ID down** - you'll need it for Terraform!

### Visual Guide:

```
Hetzner Console → [Your Project] → Security → SSH Keys
                                                    ↓
                                           [Add SSH Key Button]
                                                    ↓
                                    Paste your public key here
                                                    ↓
                                           Give it a name
                                                    ↓
                                              [Save]
                                                    ↓
                                    Your key appears with an ID
```

## Step 3: Get SSH Key ID via CLI (Alternative Method)

If you have `hcloud` CLI installed:

```bash
# Install hcloud CLI (if not installed)
# Linux/Mac:
curl -L https://github.com/hetznercloud/cli/releases/latest/download/hcloud-linux-amd64.tar.gz | tar xz
sudo mv hcloud /usr/local/bin/

# Set your API token
hcloud context create my-project
# Paste your API token when prompted

# List all SSH keys and their IDs
hcloud ssh-key list

# Output will look like:
# ID        NAME            FINGERPRINT
# 12345678  My Laptop       aa:bb:cc:dd:ee:ff...
# 87654321  Work Computer   11:22:33:44:55:66...
```

## Step 4: Use the SSH Key ID in Your Configuration

### For Terraform:

Edit `terraform/terraform.tfvars`:

```hcl
ssh_key_ids = [12345678]  # Replace with your actual ID

# For multiple keys:
ssh_key_ids = [12345678, 87654321]
```

### For GitHub Secrets:

1. Go to your GitHub repository
2. **Settings** → **Secrets and variables** → **Actions**
3. Add secret `SSH_KEY_IDS` with value: `[12345678]`

### For GitHub Actions (you also need the private key):

Add another secret `SSH_PRIVATE_KEY`:

```bash
# On Linux/Mac - Copy your private key:
cat ~/.ssh/id_ed25519

# On Windows - Copy your private key:
type $env:USERPROFILE\.ssh\id_ed25519
```

Paste the **entire content** (including BEGIN and END lines) as the `SSH_PRIVATE_KEY` secret.

## Common Issues & Solutions

### ❌ "Permission denied (publickey)"

- **Cause**: Wrong private key or key not added to Hetzner
- **Solution**: Verify the key ID is correct and matches the one in Hetzner

### ❌ "No such file or directory: ~/.ssh/id_ed25519"

- **Cause**: SSH key doesn't exist
- **Solution**: Generate a new key using Step 1

### ❌ "SSH Key already exists"

- **Cause**: You're trying to add the same key twice
- **Solution**: Use the existing key ID, or generate a new key pair

## Quick Reference

| Item                   | Location                | Format                                |
| ---------------------- | ----------------------- | ------------------------------------- |
| **Public Key**         | `~/.ssh/id_ed25519.pub` | `ssh-ed25519 AAAA...`                 |
| **Private Key**        | `~/.ssh/id_ed25519`     | `-----BEGIN OPENSSH PRIVATE KEY-----` |
| **SSH Key ID**         | Hetzner Console         | Number like `12345678`                |
| **Terraform Variable** | `terraform.tfvars`      | `ssh_key_ids = [12345678]`            |
| **GitHub Secret**      | Repository Settings     | `SSH_KEY_IDS = [12345678]`            |

## Security Best Practices

✅ **DO:**

- Use different keys for different purposes
- Use strong passphrases for private keys
- Keep private keys secure (never share or commit)
- Use `ed25519` keys (more secure than RSA)

❌ **DON'T:**

- Share your private key with anyone
- Commit private keys to git
- Use the same key everywhere
- Leave private keys unprotected

## Next Steps

After adding your SSH key:

1. ✅ Note down the SSH Key ID
2. ✅ Add it to `terraform/terraform.tfvars` or GitHub Secrets
3. ✅ Test SSH connection after deployment:
   ```bash
   ssh root@YOUR_SERVER_IP
   ```

---

**Need more help?** Check out:

- [Hetzner SSH Key Documentation](https://docs.hetzner.com/cloud/servers/getting-started/adding-ssh-keys)
- [GitHub SSH Documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
