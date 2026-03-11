#!/bin/bash
# Script Phục hồi dữ liệu (Failback) từ Pi về VPS2
# Dùng để đẩy ngược dữ liệu mới nhất từ dự phòng lên máy chính

REMOTE_IP="14.236.0.6"
REMOTE_PORT="2332"
PROJECTS=("/opt/vungvang-server" "/opt/thoigianranh-server")

echo "--- BẮT ĐẦU QUY TRÌNH PHỤC HỒI (PI -> VPS2) ---"

# 1. Đồng bộ File mã nguồn (Tất cả dự án)
for DIR in "${PROJECTS[@]}"; do
    echo "Đang đẩy file: $DIR..."
    rsync -avz -e "ssh -p $REMOTE_PORT" --delete "$DIR/" "root@$REMOTE_IP:$DIR/"
done

# 2. Đồng bộ Database (Ví dụ Vừng Vàng)
echo "Đang dump và đẩy Database Vừng Vàng..."
docker exec vungvang_mariadb mysqldump -u root -p'vungvang123' vungvang_db > /tmp/vungvang_dump.sql
scp -P $REMOTE_PORT /tmp/vungvang_dump.sql root@$REMOTE_IP:/tmp/
ssh -p $REMOTE_PORT root@$REMOTE_IP "docker exec -i vungvang_mariadb mariadb -u root -p'vungvang123' vungvang_db < /tmp/vungvang_dump.sql"

echo "--- PHỤC HỒI HOÀN TẤT ---"
