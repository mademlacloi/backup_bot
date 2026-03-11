#!/bin/bash
# Script Backup Nâng Cao (Phiên bản Tự Động Hóa - Data Driven)
# Sử dụng: ./advanced_backup.sh <domain> <type>

DOMAIN=$1
TYPE=$2
TIMESTAMP=$(date +%Y-%m-%d)
BACKUP_ROOT="/opt/backups"
ALERT_BOT="/opt/alert_bot.py"
PROJECTS_JSON="/opt/projects.json"
SPLIT_SIZE="18M"

# 1. Kiểm tra dự án trong JSON
if [ ! -f "$PROJECTS_JSON" ]; then
    echo "Lỗi: Không tìm thấy tệp cấu hình dự án ($PROJECTS_JSON)"
    exit 1
fi

DATA=$(jq -r ".[\"$DOMAIN\"]" "$PROJECTS_JSON")
if [ "$DATA" == "null" ]; then
    echo "Lỗi: Domain '$DOMAIN' chưa được cấu hình trong hệ thống."
    echo "Hãy chạy lệnh 'Quét dự án' trong Bảng điều khiển."
    exit 1
fi

WP_CONT=$(echo "$DATA" | jq -r ".wp_container")
DB_CONT=$(echo "$DATA" | jq -r ".db_container")
DB_NAME=$(echo "$DATA" | jq -r ".db_name")
DB_PASS=$(echo "$DATA" | jq -r ".db_pass")

# Hàm tính toán giới hạn CPU động
get_cpu_limit() {
    IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d. -f1)
    [ -z "$IDLE" ] && IDLE=100
    USAGE=$((100 - IDLE))
    BUDGET=$((90 - USAGE))
    if [ "$BUDGET" -lt 15 ]; then echo 15; else echo "$BUDGET"; fi
}
LIMIT=$(get_cpu_limit)
echo "--- CPU Limit: ${LIMIT}% | Domain: $DOMAIN ---"

TEMP_DIR="$BACKUP_ROOT/${DOMAIN}_${TYPE}_$TIMESTAMP"
mkdir -p "$TEMP_DIR"
FINAL_FILE="${DOMAIN}_${TYPE}_$TIMESTAMP.tar.gz"

case $TYPE in
    "db")
        nice -n 19 ionice -c 3 docker exec "$DB_CONT" mariadb-dump -u root -p"$DB_PASS" --all-databases > "$TEMP_DIR/dump.sql" 2>/dev/null
        (cd "$TEMP_DIR" && nice -n 19 ionice -c 3 cpulimit -l "$LIMIT" -- tar -czf "$FINAL_FILE" dump.sql)
        rm "$TEMP_DIR/dump.sql"
        ;;
    "theme")
        nice -n 19 ionice -c 3 cpulimit -l "$LIMIT" -- sh -c "docker exec $WP_CONT tar -czf - /var/www/html/wp-content/themes > $TEMP_DIR/$FINAL_FILE"
        ;;
    "plugin")
        nice -n 19 ionice -c 3 cpulimit -l "$LIMIT" -- sh -c "docker exec $WP_CONT tar -czf - /var/www/html/wp-content/plugins > $TEMP_DIR/$FINAL_FILE"
        ;;
    "media")
        nice -n 19 ionice -c 3 cpulimit -l "$LIMIT" -- sh -c "docker exec $WP_CONT tar -czf - /var/www/html/wp-content/uploads > $TEMP_DIR/$FINAL_FILE"
        ;;
    *)
        echo "Lỗi: Loại backup không hợp lệ ($TYPE)"
        exit 1
        ;;
esac

# Upload section
cd "$TEMP_DIR"
FILE_SIZE=$(stat -c%s "$FINAL_FILE" 2>/dev/null || echo 0)
MAX_SIZE=$((18 * 1024 * 1024))
UPLOAD_ERRORS=0

if [ "$FILE_SIZE" -gt "$MAX_SIZE" ]; then
    echo "File lớn ($((FILE_SIZE/1024/1024))MB), chia nhỏ..."
    split -b "$SPLIT_SIZE" "$FINAL_FILE" "${FINAL_FILE}.part_"
    rm "$FINAL_FILE"
    for part in ${FINAL_FILE}.part_*; do
        python3 "$ALERT_BOT" SEND_FILE "$TEMP_DIR/$part" "[$DOMAIN] $TYPE - Part: $part" "$DOMAIN"
        [ $? -ne 0 ] && UPLOAD_ERRORS=$((UPLOAD_ERRORS + 1))
    done
else
    python3 "$ALERT_BOT" SEND_FILE "$TEMP_DIR/$FINAL_FILE" "[$DOMAIN] $TYPE Backup ($TIMESTAMP)" "$DOMAIN"
    [ $? -ne 0 ] && UPLOAD_ERRORS=$((UPLOAD_ERRORS + 1))
fi

if [ $UPLOAD_ERRORS -eq 0 ]; then
    rm -rf "$TEMP_DIR"
    echo "--- Hoàn tất thành công ---"
else
    echo "--- LỖI: Upload thất bại, giữ lại file tại $TEMP_DIR ---"
fi
