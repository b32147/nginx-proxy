#!/bin/bash

# Update certificates
/usr/local/bin/dehydrated --cron

# Reload nginx if running
if [ -e /var/run/nginx.pid ]; then nginx -s reload; else echo "nginx not running, not restarting..."; fi