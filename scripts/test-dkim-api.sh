#!/bin/bash
# Interactive script to test DKIM DNS update via Hetzner Cloud API

set -e

echo "============================================"
echo "DKIM DNS Update Test Script"
echo "============================================"
echo ""

# Function to split and quote DKIM TXT value for Hetzner API
split_and_quote_txt() {
    local input="$1"
    local chunk
    local result=""
    local len=${#input}
    local i=0
    while [ $i -lt $len ]; do
        chunk="${input:$i:255}"
        # Escape any embedded double quotes or backslashes
        chunk="${chunk//\\/\\\\}"
        chunk="${chunk//\"/\\\"}"
        if [ -n "$result" ]; then
            result+=" "
        fi
        result+="\"$chunk\""
        i=$((i+255))
    done
    echo "$result"
}

# Get inputs
read -p "Enter HCLOUD_TOKEN: " HCLOUD_TOKEN
read -p "Enter DOMAIN_NAME: " DOMAIN_NAME
echo ""
echo "Enter DKIM value (paste the full v=DKIM1... string):"
read -r DKIM_VALUE

# Prepare quoted DKIM value for Hetzner API
DKIM_VALUE_QUOTED=$(split_and_quote_txt "$DKIM_VALUE")
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
  "https://api.hetzner.cloud/v1/zones/$ZONE_ID/rrsets?name=mail._domainkey&type=TXT")

echo "$RECORDS_RESPONSE" | jq '.'
echo ""

# Check if DKIM record exists
DKIM_NAME="mail._domainkey"
DKIM_TYPE="TXT"
DKIM_RECORD_ID=$(echo "$RECORDS_RESPONSE" | jq -r '.rrsets[] | select(.name == "mail._domainkey" and .type == "TXT") | .id // empty')

if [ -n "$DKIM_RECORD_ID" ]; then
  echo "✅ Found existing DKIM record (ID: $DKIM_RECORD_ID)"
  echo ""
  echo "============================================"
  echo "Step 3: Update existing DKIM record"
  echo "============================================"
  # Use PUT to replace the entire RRSet with the new DKIM value
  # Escape DKIM value for TXT record (must be double quoted)
  DKIM_ESCAPED_VALUE=$(printf '%s' "$DKIM_VALUE" | sed 's/\\/\\\\/g; s/"/\\"/g')
  DKIM_API_VALUE="\"$DKIM_ESCAPED_VALUE\""
  UPDATE_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $HCLOUD_TOKEN" \
    -d "{\"ttl\":3600,\"records\":[{\"value\":$DKIM_API_VALUE,\"comment\":\"\"}]}" \
    "https://api.hetzner.cloud/v1/zones/$ZONE_ID/rrsets/$DKIM_NAME/$DKIM_TYPE/actions/add_records")
  
  echo "$UPDATE_RESPONSE" | jq '.'
  
  if echo "$UPDATE_RESPONSE" | jq -e '.rrset' > /dev/null 2>&1; then
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
  
  DKIM_CREATE_PAYLOAD=$(jq -n \
    --arg name "mail._domainkey" \
    --arg type "TXT" \
    --arg value "$DKIM_VALUE_QUOTED" \
    --arg comment "" \
    --argjson ttl 3600 \
    '{name: $name, type: $type, records: [{value: $value, comment: $comment}], ttl: $ttl}')
  echo -e "\n--- DEBUG: Payload to Hetzner ---"
  echo "$DKIM_CREATE_PAYLOAD"
  echo "--- END DEBUG ---\n"
  CREATE_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $HCLOUD_TOKEN" \
    -d "$DKIM_CREATE_PAYLOAD" \
    "https://api.hetzner.cloud/v1/zones/$ZONE_ID/rrsets")
  
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
