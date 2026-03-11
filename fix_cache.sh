#!/bin/bash
# Script thêm cấu hình No-Cache để hỗ trợ Failover tức thì
# Áp dụng cho hongkong-server, thoigianranh-server, vungvang-server

PROJECTS=("/opt/hongkong-server/nginx/conf" "/opt/thoigianranh-server/nginx/conf" "/opt/vungvang-server/nginx/conf")

for dir in "${PROJECTS[@]}"; do
    if [ -d "$dir" ]; then
        echo "Processing $dir..."
        for file in "$dir"/*.conf; do
            [ -e "$file" ] || continue
            # Thêm Header No-Cache nếu chưa có
            if ! grep -q "add_header Cache-Control" "$file"; then
                # Chèn vào trước dòng proxy_pass hoặc sau server_name
                sed -i '/proxy_pass/i \        add_header Cache-Control "no-store, no-cache, must-revalidate, proxy-revalidate, max-age=0";' "$file"
                echo "  Updated $file"
            fi
        done
    fi
done

# Restart Nginx containers
docker restart hongkong_nginx thoigianranh_nginx vungvang_nginx
