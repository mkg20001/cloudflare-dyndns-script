#!/bin/bash

echo "Installing cloudflare dyndns as /usr/bin/cf-dd and adding cronjob..."
sudo cp dyndns.sh /usr/bin/cf-dd
cron=$(crontab -l)
cron="$cron
@reboot screen -dmS cf sh -c \"sleep 1m && cf-dd && while true; do sleep 10m && cf-dd; done\""
echo "$cron" | crontab -
