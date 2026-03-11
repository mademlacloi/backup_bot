#!/bin/bash
# Backup ThoiGianRanh (Dump DB + Source + Split)

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/opt/backups/thoigianranh_$TIMESTAMP"
mkdir -p $BACKUP_DIR

# Xóa các bản backup cũ hơn 30 ngày
find /opt/backups -type d -mtime +30 -exec rm -rf {} +

echo "--- Bắt đầu Backup Thời Gian Rảnh tại $BACKUP_DIR ---"

# 1. Dump Database
docker exec thoigianranh_db_main mariadb-dump -u root -p'thoigianranh_R00t_M4in_2026!' --all-databases > $BACKUP_DIR/thoigianranh_main.sql 2>/dev/null
docker exec thoigianranh_db_api mariadb-dump -u root -p'thoigianranh_R00t_Ap1_2026!' --all-databases > $BACKUP_DIR/thoigianranh_api.sql 2>/dev/null

# 2. Nén Source Code
tar --exclude='venv' --exclude='node_modules' --exclude='.git' -czf $BACKUP_DIR/thoigianranh_source.tar.gz -C /opt thoigianranh-server

# 3. Gom và Chia nhỏ (15MB mỗi file)
cd $BACKUP_DIR
tar -cf - . | gzip | split -b 15M - "thoigianranh_full.tar.gz.part_"

echo "--- Backup Thời Gian Rảnh Hoàn Tất! ---"
echo "Đang gửi file lên Telegram..."
for file in thoigianranh_full.tar.gz.part_*; do
    echo "Gửi $file..."
    python3 /opt/alert_bot.py SEND_FILE "$file" "Thời Gian Rảnh Backup Part: $file"
done
