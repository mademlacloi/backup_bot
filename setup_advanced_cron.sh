#!/bin/bash
# Thiết lập lịch Backup Nâng cao (Crontab)

CRON_FILE="/tmp/backup_cron"
crontab -l > $CRON_FILE 2>/dev/null

# Xóa các dòng backup cũ (nếu có) để tránh lặp
sed -i '/advanced_backup.sh/d' $CRON_FILE

# 1. DATABASE: 1 lần/ngày (2:00 sáng) - Giữ nguyên để an toàn dữ liệu
echo "0 2 * * * /opt/advanced_backup.sh vungvang.com db > /dev/null 2>&1" >> $CRON_FILE
echo "5 2 * * * /opt/advanced_backup.sh thoigianranh.com db > /dev/null 2>&1" >> $CRON_FILE
echo "10 2 * * * /opt/advanced_backup.sh api.thoigianranh.com db > /dev/null 2>&1" >> $CRON_FILE

# 2. THEMES & PLUGINS & MEDIA (Full Code): 15 ngày 1 lần (Ngày 1 và 16 hàng tháng, lúc 3:00 sáng)
echo "0 3 1,16 * * /opt/advanced_backup.sh vungvang.com theme > /dev/null 2>&1" >> $CRON_FILE
echo "10 3 1,16 * * /opt/advanced_backup.sh vungvang.com plugin > /dev/null 2>&1" >> $CRON_FILE
echo "20 3 1,16 * * /opt/advanced_backup.sh vungvang.com media > /dev/null 2>&1" >> $CRON_FILE

echo "30 3 1,16 * * /opt/advanced_backup.sh thoigianranh.com theme > /dev/null 2>&1" >> $CRON_FILE
echo "40 3 1,16 * * /opt/advanced_backup.sh thoigianranh.com plugin > /dev/null 2>&1" >> $CRON_FILE
echo "50 3 1,16 * * /opt/advanced_backup.sh thoigianranh.com media > /dev/null 2>&1" >> $CRON_FILE

echo "0 4 1,16 * * /opt/advanced_backup.sh api.thoigianranh.com theme > /dev/null 2>&1" >> $CRON_FILE
echo "10 4 1,16 * * /opt/advanced_backup.sh api.thoigianranh.com plugin > /dev/null 2>&1" >> $CRON_FILE
echo "20 4 1,16 * * /opt/advanced_backup.sh api.thoigianranh.com media > /dev/null 2>&1" >> $CRON_FILE

# Cập nhật Crontab
crontab $CRON_FILE
rm $CRON_FILE
echo "--- Đã cập nhật lịch Cronjob Backup Nâng Cao thành công! ---"
crontab -l | grep "advanced_backup.sh"
