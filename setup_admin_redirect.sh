#!/bin/bash
# Script cấu hình Redirect Admin trên VPS1 (Pi)
# Mục đích: Nếu ai truy cập vào wp-admin/wp-login trên Pi, nó sẽ tự đá sang máy chủ VPS2 qua domain srv2.*

CONFIG_PATHS=("/opt/hongkong-server/nginx/conf/wordpress.conf" "/opt/vungvang-server/nginx/conf/vungvang.conf" "/opt/thoigianranh-server/nginx/conf/thoigianranh.conf" "/opt/thoigianranh-server/nginx/conf/main.conf")

MAP_DOMAINS=(
    "hongkongluxury.vn:srv2.hongkongluxury.vn"
    "vungvang.com:srv2.vungvang.com"
    "thoigianranh.com:srv2.thoigianranh.com"
)

for mapping in "${MAP_DOMAINS[@]}"; do
    ORIGIN="${mapping%%:*}"
    TARGET="${mapping##*:}"
    
    # Tìm file cấu hình của domain tương ứng
    for path in "${CONFIG_PATHS[@]}"; do
        if [ -f "$path" ] && grep -q "$ORIGIN" "$path"; then
            echo "Configuring Redirect for $ORIGIN -> $TARGET in $path"
            
            # Xóa cấu hình cũ nếu có
            sed -i '/location ~\* (wp-admin|wp-login)/,+4d' "$path"
            
            # Chèn block redirect vào sau dòng server_name
            sed -i "/server_name/a \
\n\
    # Tự động điều hướng Admin sang VPS2 (Máy Gốc)\n\
    location ~* (wp-admin|wp-login) {\n\
        proxy_set_header Host \$host;\n\
        # Nếu đang ở trên máy Pi, đá sang srv2.*\n\
        rewrite ^(.*)$ https://$TARGET\$1 permanent;\n\
    }" "$path"
        fi
    done
done

# Restart Nginx on Pi
docker restart hongkong_nginx vungvang_nginx thoigianranh_nginx
echo "Admin Redirect configured successfully on VPS1."
