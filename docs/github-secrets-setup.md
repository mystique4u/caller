# GitHub Actions Secrets Configuration

## 🔐 Required Secrets for Deployment

You need to add these secrets to your GitHub repository to deploy via GitHub Actions.

### How to Add Secrets:

1. Go to your repository: https://github.com/mystique4u/caller
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **"New repository secret"**
4. Add each secret below

---

## 📋 Secrets to Add:

### 1. **HCLOUD_TOKEN**

- **Name:** `HCLOUD_TOKEN`
- **Value:** Your Hetzner Cloud API token
- **Get it from:** https://console.hetzner.cloud/ → Security → API Tokens

```
Example: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

---

### 2. **FIREWALL_NAME**

- **Name:** `FIREWALL_NAME`
- **Value:** `default-firewall`

```
default-firewall
```

---

### 3. **SSH_KEY_IDS**

- **Name:** `SSH_KEY_IDS`
- **Value:** `[108153935]`

```
[108153935]
```

**Note:** This is a JSON array format. Your SSH key ID is: **108153935**

---

### 4. **SSH_PRIVATE_KEY**

- **Name:** `SSH_PRIVATE_KEY`
- **Value:** Your private key content

Get it by running:

```bash
cat ~/.ssh/hetzner-wireguard
```

Copy the **entire output** including the BEGIN and END lines:

```
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAMwAAAAtzc2gtZW
...
(many more lines)
...
-----END OPENSSH PRIVATE KEY-----
```

⚠️ **IMPORTANT:** This is your PRIVATE key - keep it secure!

---

### 5. **WIREGUARD_DOMAIN** (Optional)

- **Name:** `WIREGUARD_DOMAIN`
- **Value:** Your domain name (if you have one)

```
vpn.yourdomain.com
```

**Or leave empty if you don't have a domain yet**

---

### 6. **WIREGUARD_ADMIN_USER** (Optional)

- **Name:** `WIREGUARD_ADMIN_USER`
- **Value:** `admin`

```
admin
```

---

### 7. **WIREGUARD_ADMIN_PASSWORD** (Optional)

- **Name:** `WIREGUARD_ADMIN_PASSWORD`
- **Value:** Leave empty for interactive setup

```
(leave empty)
```

---

## ✅ Summary - Copy These Values:

| Secret Name        | Value                                       |
| ------------------ | ------------------------------------------- |
| `HCLOUD_TOKEN`     | `your-api-token-here`                       |
| `FIREWALL_NAME`    | `default-firewall`                          |
| `SSH_KEY_IDS`      | `[108153935]`                               |
| `SSH_PRIVATE_KEY`  | Output from: `cat ~/.ssh/hetzner-wireguard` |
| `WIREGUARD_DOMAIN` | (optional - your domain or leave empty)     |

---

## 🚀 After Adding Secrets:

Once all secrets are added, deploy by:

```bash
cd /home/optimus/dev/repos/caller
git add .
git commit -m "Configure WireGuard deployment"
git push origin main
```

GitHub Actions will automatically:

1. ✅ Run Terraform to create the server
2. ✅ Configure WireGuard with Ansible
3. ✅ Output the server IP address

---

## 🎯 Quick Commands to Get Values:

```bash
# Get your private key
cat ~/.ssh/hetzner-wireguard

# Verify your SSH key ID
hcloud ssh-key list | grep wireguard-key

# Verify your firewall
hcloud firewall list | grep default-firewall
```

---

**Ready?** Add these secrets to GitHub, then push your code! 🎉
