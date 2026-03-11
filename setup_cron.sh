#!/bin/bash
# Script này được chạy trên VPS bản thân (VPS1 hoặc VPS2)

# 1. Cài đặt Watchdog cron (mỗi 1 phút)
(crontab -l 2>/dev/null | grep -v '/opt/watchdog.sh'; echo '* * * * * /opt/watchdog.sh >> /var/log/watchdog.log 2>&1') | crontab -

# 2. Cài đặt Sync-to-vps1 cron (mỗi 1 phút - chỉ dành cho VPS2)
if [ -f "/opt/sync-to-vps1.sh" ]; then
    (crontab -l 2>/dev/null | grep -v '/opt/sync-to-vps1.sh'; echo '* * * * * /opt/sync-to-vps1.sh >> /var/log/sync-to-vps1.log 2>&1') | crontab -
fi

echo "Crontab updated successfully."
