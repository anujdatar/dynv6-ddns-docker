#!/bin/sh

print_breaker() {
    echo "-----------------------------------------------"
}

echo "Container spun up at:  [$(date)]"
print_breaker
# #####################################################################
# Step 1: Check auth secrets and env variables
# 1. API key
echo "Performing basic container parameter checks..."
if [ -f "$API_KEY_FILE" ]; then
  API_KEY=$(cat "$API_KEY_FILE")
fi
if [ -z "$API_KEY" ]; then
  echo "Please enter valid API_KEY env variable or add /secrets/api_key file"
  exit 1
fi
echo "API Key  ---  OK"

# 2. Zone
if [ -f "$ZONE_FILE" ]; then
  ZONE=$(cat "$ZONE_FILE")
fi
if [ -z "$ZONE" ]; then
  echo "Please enter valid ZONE env variable or add /secrets/zone file"
  exit 1
fi
echo "Zone: $ZONE  ---  OK"
print_breaker

# 3. Record Type
if [ "$RECORD_TYPE" == "A" ]; then
    echo "Record type to be updated: A (IPv4)"
elif [ "$RECORD_TYPE" == "AAAA" ]; then
    echo "Record type to be updated: AAAA (IPv6)"
else
    RECORD_TYPE="A"
    echo "Unknown record type, assuming A-record (IPv4)"
fi

# #####################################################################
# Step 2: Get current public IP address
echo fetching record type $RECORD_TYPE

if [ "$RECORD_TYPE" == "A" ]; then
	CURRENT_IP=$(curl -s https://api.ipify.org || curl -s https://ipv4.icanhazip.com/)

	# check cloudflare's dns server if above method doesn't work
	if [ -z $CURRENT_IP ]; then
		echo using cloudflare whoami to find ip
    CURRENT_IP=$(dig txt ch +short whoami.cloudflare @1.1.1.1 | tr -d '"')
	fi
elif [ "$RECORD_TYPE" == "AAAA" ]; then
	CURRENT_IP=$(curl -s https://api6.ipify.org || curl -s https://ipv6.icanhazip.com/)

	# check cloudflare's dns server if above method doesn't work
	if [ -z $CURRENT_IP ]; then
		echo using cloudflare whoami to find ip
    CURRENT_IP=$(dig txt ch +short whoami.cloudflare @2606:4700:4700::1111 | tr -d '"')
	fi
fi

if [ -z $CURRENT_IP ]; then
    echo "No public IP found: check internet connection or network settings"
    exit 1
fi
echo "Current time: [$(date)]"
echo "Current Public IP: $CURRENT_IP"

# #####################################################################
# Step 3: Update ddns
# check registered ip against current public ip
OLD_IP=$(cat old_record_ip)
echo "Stored IP address $OLD_IP"
if [ "$OLD_IP" == "$CURRENT_IP" ]; then
    echo "IP address is unchanged. Update not required."
else
	echo "Updating dynv6 record with current public ip"
	update=$(curl -sSL "http://ipv6.dynv6.com/api/update?hostname=$ZONE&ipv6=$CURRENT_IP&token=$API_KEY")

	if [ "$update" == "addresses updated" ]; then
		echo "DNS Record $RECORD_NAME IP updated to $CURRENT_IP"
		echo "$CURRENT_IP" > old_record_ip
	else
		echo "Error updating dynv6 DNS record $RECORD_NAME"
		echo "$update"
	fi
fi
# #####################################################################

print_breaker
