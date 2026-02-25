# Branch Protection Setup for GitHub

## 🔒 Protect the Main Branch

### Steps to Enable Branch Protection:

1. **Go to Repository Settings**
   - Navigate to: https://github.com/mystique4u/caller/settings/branches

2. **Add Branch Protection Rule**
   - Click **"Add rule"** or **"Add branch protection rule"**
   - In "Branch name pattern" enter: `main`

3. **Recommended Protection Settings:**

   #### ✅ **Basic Protection:**
   - [x] **Require a pull request before merging**
     - [x] Require approvals: 1 (if working with team)
     - [ ] Dismiss stale pull request approvals when new commits are pushed
   
   - [x] **Require status checks to pass before merging**
     - [x] Require branches to be up to date before merging
     - Select: `terraform / Terraform Plan & Apply`
   
   - [x] **Require conversation resolution before merging**
   
   - [ ] **Require signed commits** (optional but recommended)
   
   - [x] **Require linear history** (optional - keeps history clean)
   
   - [ ] **Require deployments to succeed before merging** (optional)

   #### ✅ **Advanced Protection:**
   - [x] **Do not allow bypassing the above settings**
   - [x] **Restrict who can push to matching branches**
     - Add yourself and trusted collaborators
   
   - [ ] **Allow force pushes** (keep UNCHECKED for main)
   - [ ] **Allow deletions** (keep UNCHECKED for main)

4. **Click "Create"** to save the protection rules

---

## 🎯 **Recommended Settings for Solo Developer:**

If you're working alone, use minimal protection:

```
✅ Require a pull request before merging (optional - can be skipped for solo work)
✅ Require status checks to pass before merging
   - Select the GitHub Actions workflow
✅ Do not allow force pushes
✅ Do not allow deletions
```

---

## 🚀 **Workflow with Branch Protection:**

### Development Workflow:
```bash
# 1. Create a feature branch
git checkout -b feature/update-config

# 2. Make your changes
vim terraform/main.tf

# 3. Commit changes
git add .
git commit -m "Update Terraform configuration"

# 4. Push to feature branch
git push origin feature/update-config

# 5. Create Pull Request on GitHub
# - Go to: https://github.com/mystique4u/caller/pulls
# - Click "New pull request"
# - Select: base: main <- compare: feature/update-config
# - Create pull request

# 6. Wait for GitHub Actions to pass
# - Terraform plan will run automatically
# - Review the plan output

# 7. Merge the PR
# - Click "Merge pull request" on GitHub
# - Or use: git checkout main && git merge feature/update-config

# 8. Cleanup
git branch -d feature/update-config
git push origin --delete feature/update-config
```

---

## 🔧 **For Solo Work (Simpler Approach):**

If you want to work directly on main but still have protection:

```bash
# Just ensure Actions pass before pushing
git add .
git commit -m "Update configuration"

# Actions will run on push
git push origin main

# If Actions fail, the merge can be blocked (if configured)
```

---

## 📋 **Quick Settings Summary:**

| Setting | Solo Developer | Team |
|---------|---------------|------|
| **Require PR** | Optional | ✅ Yes |
| **Require status checks** | ✅ Yes | ✅ Yes |
| **Require approvals** | ❌ No | ✅ Yes (1-2) |
| **Block force push** | ✅ Yes | ✅ Yes |
| **Block deletion** | ✅ Yes | ✅ Yes |
| **Require signed commits** | Optional | ✅ Yes |

---

## 🛡️ **Security Benefits:**

1. ✅ Prevents accidental deletion of main branch
2. ✅ Prevents force pushes that rewrite history
3. ✅ Ensures CI/CD tests pass before merge
4. ✅ Maintains clean, auditable history
5. ✅ Prevents direct commits to main (if PR required)

---

## 🔓 **Emergency Bypass (If Needed):**

If you need to bypass protections temporarily:

1. Go to: Settings → Branches → Edit rule
2. Uncheck "Do not allow bypassing the above settings"
3. Push your changes
4. Re-enable protection immediately

**Note:** Only do this in emergencies!

---

**Need help?** Check: https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches
