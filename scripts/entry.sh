#!/bin/sh

. /ddns-update.sh

# add cloudflare-ddns start script to crontab
echo "*/${FREQUENCY} * * * * /ddns-update.sh" > /crontab.txt
/usr/bin/crontab /crontab.txt


# start cron
/usr/sbin/crond -f -l 8
