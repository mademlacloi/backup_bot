#!/bin/bash
# Backup VungVang (Dump DB + Source + Split)

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups/vungvang_$TIMESTAMP"
mkdir -p $BACKUP_DIR

# Xóa các bản backup cũ hơn 30 ngày
find /opt/backups -type d -name "vungvang_*" -mtime +30 -exec rm -rf {} +
find /opt/backups -type d -name "thoigianranh_*" -mtime +30 -exec rm -rf {} +

echo "--- Bắt đầu Backup Vừng Vàng tại $BACKUP_DIR ---"

# 1. Dump Database
docker exec vungvang_mariadb mariadb-dump -u root -p'vungvang_root_2026_pass' --all-databases > $BACKUP_DIR/vungvang_db.sql 2>/dev/null

# 2. Nén Source Code
tar --exclude='venv' --exclude='node_modules' --exclude='.git' -czf $BACKUP_DIR/vungvang_source.tar.gz -C /opt vungvang-server

# 3. Gom và Chia nhỏ (15MB mỗi file)
cd $BACKUP_DIR
tar -cf - . | gzip | split -b 15M - "vungvang_full.tar.gz.part_"

echo "--- Backup Vừng Vàng Hoàn Tất! ---"
echo "Đang gửi file lên Telegram..."
for file in vungvang_full.tar.gz.part_*; do
    echo "Gửi $file..."
    python3 /opt/alert_bot.py SEND_FILE "$file" "Vừng Vàng Backup Part: $file"
done
