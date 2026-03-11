#!/bin/bash
# Script bật/tắt vai trò phục vụ web của VPS thông qua Cloudflared Tunnels
echo "Chọn hành động cho VPS này:"
echo "1) Trở thành Node đang hoạt động (BẬT Tunnels)"
echo "2) Trở thành Node dự phòng / Bảo trì (TẮT Tunnels)"
read -p "Nhập lựa chọn (1/2): " choice

if [ "$choice" == "1" ]; then
    echo "Đang bật các dịch vụ Cloudflare Tunnel..."
    systemctl start cloudflared-thoigianranh cloudflared-vungvang
    echo "VPS đã sẵn sàng nhận traffic."
elif [ "$choice" == "2" ]; then
    echo "Đang tắt các dịch vụ Cloudflare Tunnel..."
    systemctl stop cloudflared-thoigianranh cloudflared-vungvang
    echo "Đã ngắt traffic khỏi VPS này. (Nhớ bật Node kia trước khi tắt để không gián đoạn)"
else
    echo "Lựa chọn không hợp lệ."
fi
