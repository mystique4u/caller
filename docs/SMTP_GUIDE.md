# SMTP Server Setup Guide

This guide explains how to configure and use the SMTP mail server for sending emails (e.g., password resets, notifications).

## Overview

The mail server is built using [docker-mailserver](https://docker-mailserver.github.io/docker-mailserver/), a production-ready mail server with:

- **Postfix** - SMTP server for sending emails
- **SPF** - Sender Policy Framework for email authentication
- **DKIM** - DomainKeys Identified Mail for email signing
- **DMARC** - Domain-based Message Authentication for email policy
- **Fail2ban** - Protection against brute force attacks
- **TLS/SSL** - Encrypted connections using Let's Encrypt certificates

## Prerequisites

- Domain name configured (e.g., `example.com`)
- Server IP address
- DNS access to create records
- Ansible deployment completed

## DNS Configuration

### 1. A Record (Mail Server)

Point your mail subdomain to your server:

```
Type: A
Host: mail.example.com
Value: YOUR_SERVER_IP
TTL: 3600
```

### 2. MX Record (Mail Exchange)

Tell email servers where to send mail for your domain:

```
Type: MX
Host: example.com
Priority: 10
Value: mail.example.com
TTL: 3600
```

### 3. SPF Record (Sender Policy Framework)

Add SPF record to authorize your server to send emails:

```
Type: TXT
Host: example.com
Value: v=spf1 mx ip4:YOUR_SERVER_IP ~all
TTL: 3600
```

**Explanation:**
- `v=spf1` - SPF version 1
- `mx` - Allow servers listed in MX records
- `ip4:YOUR_SERVER_IP` - Allow your specific server IP
- `~all` - Soft fail for other servers (recommended for testing)
- Use `v=spf1 mx ip4:YOUR_SERVER_IP -all` for strict policy (after testing)

### 4. DKIM Record (DomainKeys Identified Mail)

After deployment, generate DKIM keys and add the public key to DNS:

```bash
# SSH to your server
ssh root@YOUR_SERVER_IP

# Generate DKIM keys
/opt/services/mailserver/generate-dkim.sh
```

This will output a TXT record like:

```
Type: TXT
Host: mail._domainkey.example.com
Value: v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GN...
TTL: 3600
```

### 5. DMARC Record (Domain-based Message Authentication)

Add DMARC policy for email authentication reporting:

```
Type: TXT
Host: _dmarc.example.com
Value: v=DMARC1; p=quarantine; rua=mailto:postmaster@example.com; pct=100; adkim=s; aspf=s
TTL: 3600
```

**Policy options:**
- `p=none` - Monitor only (testing)
- `p=quarantine` - Mark suspicious emails as spam
- `p=reject` - Reject failing emails (strict)

### 6. PTR Record (Reverse DNS) - Optional but Recommended

Contact your hosting provider to set up reverse DNS:

```
YOUR_SERVER_IP → mail.example.com
```

This improves email deliverability.

## Email Account Management

### Create Email Account

```bash
# SSH to server
ssh root@YOUR_SERVER_IP

# Add noreply account
/opt/services/mailserver/setup-email.sh add noreply@example.com

# You'll be prompted for a password
```

### List Email Accounts

```bash
/opt/services/mailserver/setup-email.sh list
```

### Delete Email Account

```bash
/opt/services/mailserver/setup-email.sh del noreply@example.com
```

## SMTP Connection Details

Use these settings in your applications to send emails:

```
SMTP Host: mail.example.com
SMTP Port: 587 (STARTTLS - recommended)
           465 (SSL/TLS - alternative)
           25  (Plain SMTP - not recommended for external)

Authentication: Required
Username: noreply@example.com
Password: [password set during account creation]

Security: STARTTLS (port 587) or SSL/TLS (port 465)
```

## Testing Your SMTP Server

### 1. Test SMTP Connection

```bash
# Test SMTP is listening
telnet mail.example.com 587

# Expected output:
# 220 mail.example.com ESMTP Postfix
```

### 2. Send Test Email

```bash
# Using swaks (install if needed: apt install swaks)
swaks --to recipient@gmail.com \
      --from noreply@example.com \
      --server mail.example.com:587 \
      --auth LOGIN \
      --auth-user noreply@example.com \
      --auth-password YOUR_PASSWORD \
      --tls \
      --header "Subject: Test Email" \
      --body "This is a test email from your SMTP server"
```

### 3. Check SPF, DKIM, DMARC

Send a test email to:
- [mail-tester.com](https://www.mail-tester.com/)
- [mxtoolbox.com](https://mxtoolbox.com/EmailHealth.aspx)

These services will score your email authentication and deliverability.

## Application Integration Examples

### Node.js (using nodemailer)

```javascript
const nodemailer = require('nodemailer');

const transporter = nodemailer.createTransporter({
  host: 'mail.example.com',
  port: 587,
  secure: false, // use STARTTLS
  auth: {
    user: 'noreply@example.com',
    pass: 'your_password'
  }
});

await transporter.sendMail({
  from: '"MyApp" <noreply@example.com>',
  to: 'user@example.com',
  subject: 'Password Reset',
  text: 'Click here to reset your password...',
  html: '<p>Click here to reset your password...</p>'
});
```

### Python (using smtplib)

```python
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

# Create message
msg = MIMEMultipart()
msg['From'] = 'noreply@example.com'
msg['To'] = 'user@example.com'
msg['Subject'] = 'Password Reset'

body = 'Click here to reset your password...'
msg.attach(MIMEText(body, 'plain'))

# Send email
server = smtplib.SMTP('mail.example.com', 587)
server.starttls()
server.login('noreply@example.com', 'your_password')
server.send_message(msg)
server.quit()
```

### Environment Variables

Store credentials securely:

```bash
SMTP_HOST=mail.example.com
SMTP_PORT=587
SMTP_USER=noreply@example.com
SMTP_PASS=your_password
SMTP_FROM=noreply@example.com
SMTP_FROM_NAME=MyApp
```

## Monitoring and Logs

### View Mail Logs

```bash
# Real-time logs
docker logs -f mailserver

# Postfix logs
docker exec mailserver tail -f /var/log/mail/mail.log

# Failed delivery attempts
docker exec mailserver tail -f /var/log/mail/mail.err
```

### Check Mail Queue

```bash
# View queued emails
docker exec mailserver postqueue -p

# Flush mail queue (retry sending)
docker exec mailserver postqueue -f

# Delete all queued emails
docker exec mailserver postsuper -d ALL
```

## Security Best Practices

1. **Use Strong Passwords** - Generate secure passwords for email accounts
2. **Limit Email Accounts** - Only create accounts you need (e.g., noreply, support)
3. **Monitor Logs** - Regularly check for suspicious activity
4. **Rate Limiting** - Postfix includes built-in rate limiting
5. **Fail2ban** - Automatically enabled to block brute force attempts
6. **TLS Required** - Force encrypted connections only

## Troubleshooting

### Email Not Sending

1. **Check DNS records** - Verify A, MX, SPF, DKIM records are correct
2. **Check firewall** - Ensure ports 25, 587, 465 are open
3. **Check authentication** - Verify username/password
4. **Check logs** - `docker logs mailserver`

### Email Going to Spam

1. **Verify SPF** - Use online SPF checker
2. **Verify DKIM** - Check DKIM signatures
3. **Verify DMARC** - Ensure policy is set correctly
4. **Check PTR record** - Reverse DNS should match
5. **Warm up IP** - Send gradually increasing volumes
6. **Content** - Avoid spam trigger words

### Connection Refused

```bash
# Check if mailserver is running
docker ps | grep mailserver

# Restart mailserver
docker restart mailserver

# Check port binding
netstat -tulpn | grep -E ':(25|587|465)'
```

### Certificate Issues

```bash
# Check Let's Encrypt certificates
docker exec mailserver ls -la /etc/letsencrypt/

# Force certificate reload
docker restart mailserver
```

## Firewall Configuration

If you have a firewall, open these ports:

```bash
# Using UFW
ufw allow 25/tcp    # SMTP
ufw allow 587/tcp   # Submission (STARTTLS)
ufw allow 465/tcp   # SMTPS (SSL/TLS)

# Using iptables
iptables -A INPUT -p tcp --dport 25 -j ACCEPT
iptables -A INPUT -p tcp --dport 587 -j ACCEPT
iptables -A INPUT -p tcp --dport 465 -j ACCEPT
```

## Backup and Restore

### Backup Mail Data

```bash
# Backup mail accounts and configuration
tar -czf mailserver-backup-$(date +%Y%m%d).tar.gz \
  /opt/services/mailserver/config \
  /opt/services/mailserver/mail-data
```

### Restore Mail Data

```bash
# Stop mailserver
docker stop mailserver

# Restore from backup
tar -xzf mailserver-backup-YYYYMMDD.tar.gz -C /

# Start mailserver
docker start mailserver
```

## Advanced Configuration

### Custom Postfix Configuration

Edit `/opt/services/mailserver/config/postfix-main.cf` to add custom Postfix settings.

After changes, restart the mailserver:

```bash
docker restart mailserver
```

### Email Aliases

Create aliases file at `/opt/services/mailserver/config/postfix-aliases.cf`:

```
# Format: alias_address@domain.com target@domain.com
admin@example.com noreply@example.com
support@example.com noreply@example.com
```

Restart mailserver after changes.

### Rate Limiting

Postfix includes rate limiting. To customize, add to `postfix-main.cf`:

```
# Max 10 messages per minute from a client
anvil_rate_time_unit = 60s
smtpd_client_message_rate_limit = 10
```

## Resources

- [docker-mailserver Documentation](https://docker-mailserver.github.io/docker-mailserver/)
- [SPF Record Checker](https://mxtoolbox.com/spf.aspx)
- [DKIM Validator](https://mxtoolbox.com/dkim.aspx)
- [DMARC Checker](https://mxtoolbox.com/dmarc.aspx)
- [Email Deliverability Tester](https://www.mail-tester.com/)

## Support

For issues specific to your deployment:
1. Check `docker logs mailserver`
2. Check `/var/log/mail/mail.log` inside container
3. Verify DNS records propagation (can take up to 48 hours)
4. Test with mail-tester.com

For docker-mailserver issues:
- [GitHub Issues](https://github.com/docker-mailserver/docker-mailserver/issues)
- [Documentation](https://docker-mailserver.github.io/docker-mailserver/)
