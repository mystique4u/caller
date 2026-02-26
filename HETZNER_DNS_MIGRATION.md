# Hetzner DNS Migration - Changes Summary

## 🔄 What Changed

Hetzner has migrated DNS from the old DNS Console API to the new unified Cloud API. We've updated the entire project to use the new API.

---

## ✅ Changes Made

### 1. Terraform Configuration (`terraform/main.tf`)

**Removed**:

- `hetznerdns` provider (timohirt/hetznerdns)
- `hetznerdns_zone` resources
- `hetznerdns_record` resources
- `hetzner_dns_token` variable

**Added**:

- Using existing `hcloud` provider for DNS
- `hcloud_dns_zone` resources
- `hcloud_dns_record` resources
- DNS managed by same `HCLOUD_TOKEN`

### 2. GitHub Actions Workflows

**Removed** from both `deploy.yml` and `destroy-and-redeploy.yml`:

- `TF_VAR_hetzner_dns_token` environment variable

**Kept**:

- All other environment variables unchanged

### 3. Documentation Updates

**Files updated**:

- `docs/GITHUB_SECRETS.md` - Removed `HETZNER_DNS_TOKEN` section
- `docs/DOMAIN_SETUP.md` - Removed DNS token setup steps
- `DOMAIN_QUICKSTART.md` - Simplified from 5 steps to 3 steps
- `DOMAIN_SETUP_CHECKLIST.md` - Removed DNS token checklist items
- `README.md` - Updated secrets table

---

## 🎯 Key Benefits

✅ **Simpler Setup** - One token manages everything  
✅ **Fewer Secrets** - No separate DNS token needed  
✅ **Future-Proof** - Uses the new official Hetzner Cloud API  
✅ **Less Complexity** - One provider instead of two

---

## 📋 What You Need to Do

### For Existing Deployments

If you already have DNS zones in the old DNS Console, you have two options:

**Option A: Fresh Start (Recommended)**

1. Remove the old `HETZNER_DNS_TOKEN` from GitHub Secrets
2. Run "Destroy and Redeploy" workflow
3. New DNS zones will be created automatically in Hetzner Console

**Option B: Migrate Existing Zones**

1. Log into https://dns.hetzner.com/
2. Click "Migrate to Hetzner Console" for each zone
3. Wait for migration to complete
4. Remove the old `HETZNER_DNS_TOKEN` from GitHub Secrets
5. Deploy as normal

### For New Deployments

Nothing special needed! Just:

1. Add `DOMAIN_NAME` and `EMAIL_ADDRESS` secrets
2. Deploy normally
3. DNS is automatically managed by your existing `HCLOUD_TOKEN`

---

## 🔍 Technical Details

### Old DNS API

- **Endpoint**: `dns.hetzner.com`
- **Provider**: `timohirt/hetznerdns`
- **Token**: Separate `HETZNER_DNS_TOKEN`
- **Status**: Being phased out (brownouts scheduled)

### New Cloud API

- **Endpoint**: Hetzner Cloud API
- **Provider**: `hetznercloud/hcloud`
- **Token**: Same as server management (`HCLOUD_TOKEN`)
- **Status**: Active and maintained

### Migration Path

- Old DNS zones can be migrated via DNS Console UI
- New zones are created directly in Hetzner Console
- DNS records remain unchanged during migration
- No downtime during migration

---

## ⚙️ GitHub Secrets Comparison

### Before (7-8 secrets)

```
TF_API_TOKEN          ✓
HCLOUD_TOKEN          ✓
HETZNER_DNS_TOKEN     ✓ (separate DNS token)
FIREWALL_NAME         ✓
SSH_KEY_IDS           ✓
SSH_PRIVATE_KEY       ✓
DOMAIN_NAME           ✓ (optional)
EMAIL_ADDRESS         ✓ (optional)
```

### After (6-7 secrets)

```
TF_API_TOKEN          ✓
HCLOUD_TOKEN          ✓ (manages servers AND DNS)
FIREWALL_NAME         ✓
SSH_KEY_IDS           ✓
SSH_PRIVATE_KEY       ✓
DOMAIN_NAME           ✓ (optional)
EMAIL_ADDRESS         ✓ (optional)
```

**Result**: One less token to manage!

---

## 🚀 Deployment Impact

### No Domain Configured

- **Impact**: None
- **Action**: Nothing required
- Works exactly the same with IP-only access

### Domain Configured

- **Impact**: Minor
- **Action**: Remove old `HETZNER_DNS_TOKEN` from GitHub Secrets
- DNS will be managed by `HCLOUD_TOKEN` automatically

---

## 📚 Updated Documentation

All documentation has been updated to reflect the new API:

- ✅ GitHub Secrets guide simplified
- ✅ Domain setup guide now 2 steps shorter
- ✅ Quick start guide updated (5 min → 3 min)
- ✅ Checklist simplified
- ✅ README updated with new requirements
- ✅ All references to old DNS API removed

---

## ⚠️ Important Notes

1. **Old DNS Console will be deprecated** - Brownouts are scheduled
2. **No separate DNS token needed** - Use your existing `HCLOUD_TOKEN`
3. **DNS zones created in new location** - Check Hetzner Console instead of DNS Console
4. **All features work the same** - No functionality changes
5. **Terraform state will change** - Resources will be recreated on first apply

---

## 🔧 Troubleshooting

### "hetznerdns" provider not found

**Cause**: Terraform is trying to use old provider  
**Fix**: Run `terraform init -upgrade` to update providers

### DNS zones not appearing in DNS Console

**Expected**: DNS zones now appear in **Hetzner Console** → **DNS** tab  
**Note**: They won't appear in old dns.hetzner.com anymore

### "hetzner_dns_token" variable error

**Cause**: Terraform trying to use removed variable  
**Fix**: Variable has been removed, use `HCLOUD_TOKEN` only

---

## 📞 Support

- **Hetzner DNS Migration FAQ**: https://docs.hetzner.com/networking/dns/faq/beta
- **Cloud API Documentation**: https://docs.hetzner.cloud/reference/cloud#tag/zones
- **Migration Process Guide**: https://docs.hetzner.com/networking/dns/migration-to-hetzner-console/process

---

## ✨ Next Steps

1. Review this summary
2. Remove old `HETZNER_DNS_TOKEN` from GitHub Secrets (if exists)
3. Commit and push changes
4. Deploy as normal
5. Verify DNS zones appear in Hetzner Console

All done! Your setup is now using the modern, unified Hetzner Cloud API. 🎉
