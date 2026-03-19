#!/bin/bash
# Interactive script to test DKIM DNS update via Hetzner Cloud API

set -e

echo "============================================"
echo "DKIM DNS Update Test Script"
echo "============================================"
echo ""

# Get inputs
read -p "Enter HCLOUD_TOKEN: " HCLOUD_TOKEN
read -p "Enter DOMAIN_NAME: " DOMAIN_NAME
echo ""
echo "Enter DKIM value (paste the full v=DKIM1... string):"
read -r DKIM_VALUE
echo ""

echo "============================================"
echo "Step 1: List all zones"
echo "============================================"
ZONES_RESPONSE=$(curl -s -H "Authorization: Bearer $HCLOUD_TOKEN" \
  "https://api.hetzner.cloud/v1/zones")

echo "$ZONES_RESPONSE" | jq '.'
echo ""

# Extract zone ID
ZONE_ID=$(echo "$ZONES_RESPONSE" | jq -r ".zones[] | select(.name == \"$DOMAIN_NAME\") | .id // empty")

if [ -z "$ZONE_ID" ]; then
  echo "❌ Could not find zone for $DOMAIN_NAME"
  echo "Available zones:"
  echo "$ZONES_RESPONSE" | jq -r '.zones[] | .name'
  exit 1
fi

echo "✅ Found zone ID: $ZONE_ID"
echo ""

echo "============================================"
echo "Step 2: List existing records in zone"
echo "============================================"
RECORDS_RESPONSE=$(curl -s -H "Authorization: Bearer $HCLOUD_TOKEN" \
  "https://api.hetzner.cloud/v1/zones/$ZONE_ID/records")

echo "$RECORDS_RESPONSE" | jq '.'
echo ""

# Check if DKIM record exists
DKIM_RECORD_ID=$(echo "$RECORDS_RESPONSE" | jq -r '.records[] | select(.name == "mail._domainkey" and .type == "TXT") | .id // empty')

if [ -n "$DKIM_RECORD_ID" ]; then
  echo "✅ Found existing DKIM record (ID: $DKIM_RECORD_ID)"
  echo ""
  echo "============================================"
  echo "Step 3: Update existing DKIM record"
  echo "============================================"
  
  UPDATE_RESPONSE=$(curl -s -X PUT \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $HCLOUD_TOKEN" \
    -d "{\"name\":\"mail._domainkey\",\"type\":\"TXT\",\"value\":\"$DKIM_VALUE\",\"ttl\":3600,\"zone_id\":\"$ZONE_ID\"}" \
    "https://api.hetzner.cloud/v1/zones/$ZONE_ID/records/$DKIM_RECORD_ID")
  
  echo "$UPDATE_RESPONSE" | jq '.'
  
  if echo "$UPDATE_RESPONSE" | jq -e '.record' > /dev/null 2>&1; then
    echo ""
    echo "✅ DKIM record updated successfully!"
  else
    echo ""
    echo "❌ Failed to update DKIM record"
  fi
else
  echo "⚠️  No existing DKIM record found"
  echo ""
  echo "============================================"
  echo "Step 3: Create new DKIM record"
  echo "============================================"
  
  CREATE_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $HCLOUD_TOKEN" \
    -d "{\"name\":\"mail._domainkey\",\"type\":\"TXT\",\"value\":\"$DKIM_VALUE\",\"ttl\":3600,\"zone_id\":\"$ZONE_ID\"}" \
    "https://api.hetzner.cloud/v1/zones/$ZONE_ID/records")
  
  echo "$CREATE_RESPONSE" | jq '.'
  
  if echo "$CREATE_RESPONSE" | jq -e '.record' > /dev/null 2>&1; then
    echo ""
    echo "✅ DKIM record created successfully!"
  else
    echo ""
    echo "❌ Failed to create DKIM record"
  fi
fi

echo ""
echo "============================================"
echo "Step 4: Verify DKIM record in DNS"
echo "============================================"
sleep 2  # Wait for propagation
DKIM_CHECK=$(dig +short TXT "mail._domainkey.$DOMAIN_NAME")

if [ -n "$DKIM_CHECK" ]; then
  echo "✅ DKIM record found in DNS:"
  echo "$DKIM_CHECK"
else
  echo "⚠️  DKIM record not yet visible in DNS (may take a few minutes to propagate)"
fi

echo ""
echo "============================================"
echo "Test Complete"
echo "============================================"
