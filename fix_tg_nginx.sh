#!/bin/bash
cd /opt/thoigianranh-server

API_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' thoigianranh_wp_api)
MAIN_IP=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' thoigianranh_wp_main)

cat <<EOF > nginx/conf/thoigianranh.conf
server {
    listen 80;
    server_name api.thoigianranh.com;

    client_max_body_size 64M;

    location / {
        proxy_pass         http://${API_IP}:80;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto https;
    }
}
server {
    listen 80;
    server_name thoigianranh.com www.thoigianranh.com;

    client_max_body_size 64M;

    location / {
        proxy_pass         http://${MAIN_IP}:80;
        proxy_set_header   Host \$host;
        proxy_set_header   X-Real-IP \$remote_addr;
        proxy_set_header   X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto https;
    }
}
EOF

docker restart thoigianranh_nginx
