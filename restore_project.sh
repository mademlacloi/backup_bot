#!/bin/bash
# Script Khôi phục Dự án từ các tệp chia nhỏ
# Cách dùng: ./restore_project.sh <vungvang|thoigianranh> <path_to_backup_folder>

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
    echo "Lỗi: Thiếu tham số. Cách dùng: ./restore_project.sh <vungvang|thoigianranh> /opt/backups/folder_name"
    exit 1
fi

if [ ! -d "$BACKUP_PATH" ]; then
    echo "Lỗi: Thư mục backup không tồn tại: $BACKUP_PATH"
    exit 1
fi

echo "--- Bắt đầu khôi phục $PROJECT từ $BACKUP_PATH ---"
cd $BACKUP_PATH

# 1. Ghép nối và giải nén (Tìm tệp linh hoạt)
echo "[1/3] Đang tìm kiếm và xử lý tệp backup cho $PROJECT..."

# Tìm tệp nén (có thể có timestamp)
BACKUP_FILE=$(ls ${PROJECT}*.tar.gz 2>/dev/null | head -n 1)
FILE_PART=$(ls ${PROJECT}*.tar.gz.part_aa 2>/dev/null | head -n 1)

if [ -f "$BACKUP_FILE" ]; then
    echo "Phát hiện tệp đơn: $BACKUP_FILE"
    nice -n 19 ionice -c 3 cpulimit -l "$LIMIT" -- tar -xzf "$BACKUP_FILE"
elif [ -f "$FILE_PART" ]; then
    echo "Phát hiện tệp chia nhỏ khởi đầu bằng: $FILE_PART"
    # Lấy tiền tố chung của các phần (ví dụ: vungvang.com_db_2026-03-11.tar.gz.part_)
    PART_PREFIX=$(echo "$FILE_PART" | sed 's/aa$//')
    nice -n 19 ionice -c 3 sh -c "cat ${PART_PREFIX}* | cpulimit -l $LIMIT -- tar -xzf -"
else
    echo "Lỗi: Không tìm thấy tệp backup (.tar.gz hoặc .part_aa) khớp với '$PROJECT' trong $BACKUP_PATH"
    ls -la # Hiển thị danh sách file để debug
    exit 1
fi

# 2. Khôi phục Source Code
echo "[2/3] Ghi đè source code vào /opt..."
if [ "$PROJECT" == "vungvang" ] && [ -f vungvang_source.tar.gz ]; then
   nice -n 19 ionice -c 3 cpulimit -l "$LIMIT" -- tar -xzf vungvang_source.tar.gz -C /opt
elif [ "$PROJECT" == "thoigianranh" ] && [ -f thoigianranh_source.tar.gz ]; then
   nice -n 19 ionice -c 3 cpulimit -l "$LIMIT" -- tar -xzf thoigianranh_source.tar.gz -C /opt
fi

# 3. Khôi phục Database
echo "[3/3] Đang Import Database vào Docker..."
if [ "$PROJECT" == "vungvang" ] && [ -f vungvang_db.sql ]; then
    nice -n 19 ionice -c 3 docker exec -i vungvang_mariadb mariadb -u root -p'vungvang_root_2026_pass' < vungvang_db.sql
elif [ "$PROJECT" == "thoigianranh" ]; then
    [ -f thoigianranh_main.sql ] && nice -n 19 ionice -c 3 docker exec -i thoigianranh_db_main mariadb -u root -p'thoigianranh_R00t_M4in_2026!' < thoigianranh_main.sql
    [ -f thoigianranh_api.sql ] && nice -n 19 ionice -c 3 docker exec -i thoigianranh_db_api mariadb -u root -p'thoigianranh_R00t_Ap1_2026!' < thoigianranh_api.sql
fi

echo "--- Khôi phục $PROJECT Hoàn Tất! ---"
