#!/bin/bash
# Script đồng bộ dữ liệu Docker Volumes từ VPS1 (Pi) sang VPS2
# Chạy script này trên VPS1 (Pi)

VPS2_IP="14.236.0.6"
VPS2_PORT="2332"

VOLUMES=(
    "hongkong-server_wordpress_data"
    "thoigianranh-server_thoigianranh_wp_main_data"
    "thoigianranh-server_thoigianranh_wp_api_data"
    "vungvang-server_vungvang_wp_data"
)

echo "=== Bắt đầu đồng bộ Docker Volumes từ VPS1 sang VPS2 ==="

for VOL in "${VOLUMES[@]}"; do
    echo "--- Đang đồng bộ volume: $VOL ---"
    # Đồng bộ nội dung thư mục _data
    rsync -avz -e "ssh -p $VPS2_PORT" \
        /var/lib/docker/volumes/$VOL/_data/ \
        root@$VPS2_IP:/var/lib/docker/volumes/$VOL/_data/
done

echo "=== Đồng bộ hoàn tất! ==="
