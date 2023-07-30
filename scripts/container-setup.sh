#!/bin/sh

print_breaker() {
  echo "-----------------------------------------------"
}

# #####################################################################
# Step 1: Set up timezone
if [ -z "$TZ" ]; then
  echo "TZ environment variable not set. Using default: UTC"
else
  echo "Setting timezone to $TZ"
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ > /etc/timezone
fi

echo "Starting Dynv6 DDNS container: [$(date)]"
print_breaker
# #####################################################################
echo "Performing basic container parameter checks..."
# Step 2: Check API key
if [ -f "$API_KEY_FILE" ]; then
  API_KEY=$(cat "$API_KEY_FILE")
fi
if [ -z "$API_KEY" ]; then
  echo "Please enter valid API_KEY env variable or API_KEY_FILE secret"
  exit 1
fi
echo "API Key  ---  OK"
# #####################################################################
# Step 3. Check Zone/Domain/Subdomain
if [ -f "$ZONE_FILE" ]; then
  ZONE=$(cat "$ZONE_FILE")
fi
if [ -z "$ZONE" ]; then
  echo "Please enter valid ZONE env variable or add /secrets/zone file"
  exit 1
fi
echo "Zone: $ZONE  ---  OK"
# #####################################################################
# Step 4. Check record type
if [ "$RECORD_TYPE" == "A" ]; then
  echo "Record type to be updated: A (IPv4)"
elif [ "$RECORD_TYPE" == "AAAA" ]; then
  echo "Record type to be updated: AAAA (IPv6)"
else
  RECORD_TYPE="A"
  echo "Unknown record type, assuming A-record (IPv4)"
fi
# #####################################################################
# Step 5: Save to config file
touch /old_record_ip
echo "API_KEY=\"$API_KEY\"" > /config.sh
echo "ZONE=\"$ZONE\"" >> /config.sh
echo "RECORD_TYPE=\"$RECORD_TYPE\"" >> /config.sh
# #####################################################################
print_breaker
echo "Container setup complete, starting DDNS update loop..."
print_breaker
