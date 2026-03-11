#!/bin/bash
# Script Khôi phục Dự án từ các tệp chia nhỏ
# Cách dùng: ./restore_project.sh <domain> <path_to_backup_folder>

PROJECT=$1
BACKUP_PATH=$2

# Hàm tính toán giới hạn CPU động
get_cpu_limit() {
    IDLE=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | cut -d. -f1)
    [ -z "$IDLE" ] && IDLE=100
    USAGE=$((100 - IDLE))
    BUDGET=$((90 - USAGE))
    if [ "$BUDGET" -lt 15 ]; then echo 15; else echo "$BUDGET"; fi
}
LIMIT=$(get_cpu_limit)
echo "--- CPU Limit được áp dụng: ${LIMIT}% (Dựa trên tải hệ thống thực tế) ---"

if [ -z "$PROJECT" ] || [ -z "$BACKUP_PATH" ]; then
    echo "Lỗi: Thiếu tham số."
    exit 1
fi

if [ ! -d "$BACKUP_PATH" ]; then
    echo "Lỗi: Thư mục backup không tồn tại: $BACKUP_PATH"
    exit 1
fi

echo "--- Bắt đầu khôi phục $PROJECT từ $BACKUP_PATH ---"
cd "$BACKUP_PATH"

# 1. Tìm file backup theo domain (linh hoạt: hỗ trợ cả vungvang và vungvang.com)
echo "[1/3] Đang tìm kiếm và xử lý tệp backup cho $PROJECT..."

# Tìm file đơn: tên bắt đầu bằng domain-based prefix
BACKUP_FILE=$(ls "${PROJECT}"_*.tar.gz 2>/dev/null | head -n 1)
FILE_PART=$(ls "${PROJECT}"_*.tar.gz.part_aa 2>/dev/null | head -n 1)

# Nếu không tìm được, tìm theo substring
if [ -z "$BACKUP_FILE" ] && [ -z "$FILE_PART" ]; then
    BACKUP_FILE=$(ls *.tar.gz 2>/dev/null | grep "$PROJECT" | head -n 1)
    FILE_PART=$(ls *.tar.gz.part_aa 2>/dev/null | grep "$PROJECT" | head -n 1)
fi

if [ -f "$BACKUP_FILE" ]; then
    echo "Phát hiện tệp đơn: $BACKUP_FILE"
    EXTRACT_DIR="$BACKUP_PATH/extracted"
    mkdir -p "$EXTRACT_DIR"
    nice -n 19 ionice -c 3 cpulimit -l "$LIMIT" -- tar -xzf "$BACKUP_FILE" -C "$EXTRACT_DIR"
elif [ -f "$FILE_PART" ]; then
    echo "Phát hiện tệp chia nhỏ: $FILE_PART"
    PART_PREFIX=$(echo "$FILE_PART" | sed 's/aa$//')
    EXTRACT_DIR="$BACKUP_PATH/extracted"
    mkdir -p "$EXTRACT_DIR"
    nice -n 19 ionice -c 3 sh -c "cat ${PART_PREFIX}* | cpulimit -l $LIMIT -- tar -xzf - -C '$EXTRACT_DIR'"
else
    echo "Lỗi: Không tìm thấy tệp backup khớp với '$PROJECT' trong $BACKUP_PATH"
    ls -la
    exit 1
fi

# 2. Đọc thông tin dự án từ projects.json
PROJECTS_JSON="/opt/projects.json"
if [ ! -f "$PROJECTS_JSON" ]; then
    echo "Lỗi: Không tìm thấy /opt/projects.json"
    exit 1
fi

# Tìm domain trong projects.json
DOMAIN_KEY=""
for key in $(jq -r 'keys[]' "$PROJECTS_JSON"); do
    if echo "$key" | grep -q "$PROJECT"; then
        DOMAIN_KEY="$key"
        break
    fi
done

if [ -z "$DOMAIN_KEY" ]; then
    echo "Lỗi: Không tìm thấy cấu hình cho domain '$PROJECT' trong projects.json"
    exit 1
fi

WP_CONT=$(jq -r ".\"$DOMAIN_KEY\".wp_container" "$PROJECTS_JSON")
DB_CONT=$(jq -r ".\"$DOMAIN_KEY\".db_container" "$PROJECTS_JSON")
DB_PASS=$(jq -r ".\"$DOMAIN_KEY\".db_pass" "$PROJECTS_JSON")

echo "[2/3] Khôi phục Database..."
DUMP_FILE=$(find "$EXTRACT_DIR" -name "dump.sql" | head -n 1)
if [ -f "$DUMP_FILE" ]; then
    docker exec -i "$DB_CONT" mariadb -u root -p"$DB_PASS" < "$DUMP_FILE" 2>/dev/null || \
    docker exec -i "$DB_CONT" mysql -u root -p"$DB_PASS" < "$DUMP_FILE" 2>/dev/null
    echo " -> Đã import database vào $DB_CONT"
else
    echo " -> Không tìm thấy dump.sql, bỏ qua."
fi

echo "[3/3] Khôi phục mã nguồn Web..."
HTML_TAR=$(find "$EXTRACT_DIR" -name "html.tar.gz" | head -n 1)
if [ -f "$HTML_TAR" ]; then
    # Giải nén vào thư mục tạm rồi copy vào container
    STAGE_DIR="$BACKUP_PATH/stage"
    mkdir -p "$STAGE_DIR"
    tar -xzf "$HTML_TAR" -C "$STAGE_DIR"
    docker cp "$STAGE_DIR/html/." "$WP_CONT:/var/www/html/"
    rm -rf "$STAGE_DIR"
    echo " -> Đã khôi phục mã nguồn vào container $WP_CONT"
else
    echo " -> Không tìm thấy html.tar.gz, bỏ qua."
fi

rm -rf "$EXTRACT_DIR"
echo "--- Khôi phục $PROJECT Hoàn Tất! ---"
