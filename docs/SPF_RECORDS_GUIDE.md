# SPF Records Configuration Guide

## What is SPF?

SPF (Sender Policy Framework) is an email authentication method that prevents email spoofing by specifying which mail servers are authorized to send emails on behalf of your domain.

## Why You Need SPF

Without SPF records:
- Your emails may be marked as spam
- Email providers can't verify your emails are legitimate
- Spammers can impersonate your domain
- Poor email deliverability rates

With SPF records:
- ✅ Improved email deliverability
- ✅ Protection against email spoofing
- ✅ Better sender reputation
- ✅ Compliance with email standards

## SPF Record Format

Basic syntax:

```
v=spf1 [mechanisms] [qualifier]
```

### Components

1. **v=spf1** - Required, indicates SPF version 1
2. **Mechanisms** - Define which servers can send email
3. **Qualifier** - What to do with emails from non-authorized servers

## Common SPF Mechanisms

| Mechanism | Description | Example |
|-----------|-------------|---------|
| `a` | Allow servers in A record | `v=spf1 a ~all` |
| `mx` | Allow servers in MX records | `v=spf1 mx ~all` |
| `ip4` | Allow specific IPv4 address | `v=spf1 ip4:192.0.2.1 ~all` |
| `ip6` | Allow specific IPv6 address | `v=spf1 ip6:2001:db8::1 ~all` |
| `include` | Include another domain's SPF | `v=spf1 include:_spf.google.com ~all` |
| `all` | Match everything (must be last) | `v=spf1 -all` |

## Qualifiers

| Qualifier | Meaning | Action |
|-----------|---------|--------|
| `+` | Pass (default) | Accept email |
| `-` | Fail (hard fail) | Reject email |
| `~` | Soft fail | Accept but mark as suspicious |
| `?` | Neutral | No policy |

## Common SPF Configurations

### 1. Single Mail Server (Recommended for this setup)

```
v=spf1 mx ip4:YOUR_SERVER_IP ~all
```

**Use case:** You host your own mail server
- Allows MX records
- Allows your specific server IP
- Soft fails other servers

### 2. Strict Single Server

```
v=spf1 mx ip4:YOUR_SERVER_IP -all
```

**Use case:** Production with no third-party email services
- Hard fail ensures only your server can send
- Best for security after testing

### 3. With Google Workspace / Gmail

```
v=spf1 include:_spf.google.com mx ip4:YOUR_SERVER_IP ~all
```

**Use case:** Using both Google Workspace and your own server

### 4. With Multiple Email Services

```
v=spf1 include:_spf.google.com include:spf.protection.outlook.com mx ip4:YOUR_SERVER_IP ~all
```

**Use case:** Using Google, Microsoft, and your own server

### 5. With SendGrid / Mailgun

```
v=spf1 include:sendgrid.net mx ip4:YOUR_SERVER_IP ~all
```

or

```
v=spf1 include:mailgun.org mx ip4:YOUR_SERVER_IP ~all
```

**Use case:** Using transactional email services

## SPF Record for This Setup

For your mail server deployed with this stack:

### During Testing (Soft Fail)

```
Type: TXT
Host: @
or
Host: example.com
Value: v=spf1 mx ip4:YOUR_SERVER_IP ~all
```

### Production (Hard Fail)

After testing everything works:

```
Type: TXT
Host: @
or
Host: example.com
Value: v=spf1 mx ip4:YOUR_SERVER_IP -all
```

### With IPv6

If your server has IPv6:

```
v=spf1 mx ip4:YOUR_SERVER_IP ip6:YOUR_IPv6_ADDRESS ~all
```

## How to Add SPF Record

### DNS Provider Instructions

**Cloudflare:**
1. Go to DNS settings
2. Click "Add record"
3. Type: TXT
4. Name: @ (or your domain)
5. Content: `v=spf1 mx ip4:YOUR_SERVER_IP ~all`
6. TTL: Auto or 3600
7. Click Save

**Hetzner DNS:**
1. Go to DNS Console
2. Select your zone
3. Click "Add Record"
4. Type: TXT
5. Name: @ (leave empty for root)
6. Value: `v=spf1 mx ip4:YOUR_SERVER_IP ~all`
7. Save

**AWS Route 53:**
1. Go to Hosted Zones
2. Select your domain
3. Create Record
4. Record type: TXT
5. Name: (leave empty)
6. Value: `"v=spf1 mx ip4:YOUR_SERVER_IP ~all"`
7. Create records

**GoDaddy:**
1. DNS Management
2. Add → TXT
3. Host: @
4. TXT Value: `v=spf1 mx ip4:YOUR_SERVER_IP ~all`
5. TTL: 1 hour
6. Save

## Multiple SPF Records

**⚠️ IMPORTANT:** Only ONE SPF record per domain!

❌ **Wrong:**
```
v=spf1 mx ~all
v=spf1 ip4:192.0.2.1 ~all
```

✅ **Correct:**
```
v=spf1 mx ip4:192.0.2.1 ~all
```

## SPF Record Limits

- Maximum 10 DNS lookups (includes mechanisms)
- Maximum 255 characters per string
- Can use multiple strings: `"v=spf1 ..." "... ~all"`

### Too Many Lookups Example

❌ **Bad (11 lookups):**
```
v=spf1 include:spf1.domain.com include:spf2.domain.com 
include:spf3.domain.com include:spf4.domain.com 
include:spf5.domain.com mx a ~all
```

✅ **Good (combine or flatten):**
```
v=spf1 ip4:192.0.2.0/24 ip4:198.51.100.0/24 mx ~all
```

## Testing Your SPF Record

### Online Tools

1. **MXToolbox SPF Checker**
   - https://mxtoolbox.com/spf.aspx
   - Enter your domain
   - View SPF record and validation

2. **DMARC Analyzer**
   - https://www.dmarcanalyzer.com/spf/checker/
   - Comprehensive SPF checking

3. **Google Admin Toolbox**
   - https://toolbox.googleapps.com/apps/checkmx/
   - Check MX and SPF records

### Command Line

```bash
# Linux/Mac - check SPF record
dig TXT example.com +short | grep spf

# Or using nslookup
nslookup -type=TXT example.com

# Windows
nslookup -type=TXT example.com
```

### Test Email Delivery

Send a test email and check headers:

```bash
# Using swaks
swaks --to test@gmail.com \
      --from noreply@example.com \
      --server mail.example.com:587 \
      --auth LOGIN \
      --auth-user noreply@example.com \
      --auth-password PASSWORD \
      --tls

# Then check the email headers for:
# Received-SPF: pass
```

## Troubleshooting SPF

### SPF Record Not Found

**Cause:** DNS record not created or not propagated

**Solution:**
1. Verify record exists in DNS panel
2. Wait for DNS propagation (up to 48 hours)
3. Check with `dig TXT example.com +short`

### SPF: None

**Cause:** No SPF record found

**Solution:**
1. Add SPF TXT record to your domain
2. Wait for DNS propagation
3. Test again

### SPF: Soft Fail (~all)

**Cause:** Email sent from unauthorized server, but soft fail policy

**Solution:**
1. Verify email is sent from authorized server
2. If testing is complete, change `~all` to `-all`
3. Or add the sending server to SPF record

### SPF: Hard Fail (-all)

**Cause:** Email sent from unauthorized server with hard fail policy

**Solution:**
1. Email will be rejected
2. Add authorized server IP to SPF record
3. Or use `~all` during testing

### SPF: PermError (10 DNS lookups exceeded)

**Cause:** Too many DNS lookups in SPF record

**Solution:**
1. Flatten SPF record by replacing includes with IPs
2. Remove unnecessary mechanisms
3. Use SPF flattening services

## SPF Best Practices

1. ✅ **Start with soft fail** (`~all`) during testing
2. ✅ **Switch to hard fail** (`-all`) in production
3. ✅ **Keep it simple** - only include what you need
4. ✅ **Monitor email deliverability** after changes
5. ✅ **Combine SPF with DKIM and DMARC** for best results
6. ✅ **Document your SPF policy** for your team
7. ✅ **Regular testing** using online tools
8. ❌ **Don't exceed 10 DNS lookups**
9. ❌ **Don't have multiple SPF records**
10. ❌ **Don't forget to include all authorized servers**

## SPF + DKIM + DMARC = Email Authentication Trinity

For best email deliverability, implement all three:

### 1. SPF (Sender Policy Framework)
- Authorizes which servers can send email
- DNS TXT record: `v=spf1 mx ip4:YOUR_IP ~all`

### 2. DKIM (DomainKeys Identified Mail)
- Signs emails with cryptographic signature
- DNS TXT record: `mail._domainkey.example.com`
- Generated by mail server

### 3. DMARC (Domain-based Message Authentication)
- Tells receivers what to do with failed emails
- DNS TXT record: `v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com`

## Example Complete DNS Setup

```bash
# A Record - Mail server
mail.example.com.    IN A     192.0.2.1

# MX Record - Mail exchange
example.com.         IN MX    10 mail.example.com.

# SPF Record - Sender authorization
example.com.         IN TXT   "v=spf1 mx ip4:192.0.2.1 ~all"

# DKIM Record - Email signing (after generation)
mail._domainkey.example.com. IN TXT "v=DKIM1; k=rsa; p=MIGfMA0..."

# DMARC Record - Email policy
_dmarc.example.com.  IN TXT   "v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com"
```

## Quick Reference

### Minimal SPF (This Setup)
```
v=spf1 mx ip4:YOUR_SERVER_IP ~all
```

### Production SPF (This Setup)
```
v=spf1 mx ip4:YOUR_SERVER_IP -all
```

### Check SPF
```bash
dig TXT example.com +short | grep spf
```

### Test Email
```bash
swaks --to test@mail-tester.com --from noreply@example.com --server mail.example.com:587 --auth LOGIN --auth-user noreply@example.com --auth-password PASSWORD --tls
```

Then visit mail-tester.com to see your score.

## Resources

- [SPF RFC 7208](https://tools.ietf.org/html/rfc7208)
- [Open SPF Project](http://www.open-spf.org/)
- [MXToolbox SPF Guide](https://mxtoolbox.com/SPFRecordGenerator.aspx)
- [DMARC.org](https://dmarc.org/)

## Next Steps

1. ✅ Add SPF record to DNS
2. ✅ Generate and add DKIM record
3. ✅ Add DMARC record
4. ✅ Test with mail-tester.com
5. ✅ Monitor email deliverability
6. ✅ Adjust policies based on results

For complete setup instructions, see [SMTP_GUIDE.md](SMTP_GUIDE.md).
