#!/bin/bash
# Lấy IP của container wg-easy
WG_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' wg-easy 2>/dev/null)
if [ -n "$WG_IP" ]; then
    # Thêm route tĩnh cho Pi (Host)
    ip route add 10.8.0.0/24 via $WG_IP 2>/dev/null
    
    # Thêm luật NAT MASQUERADE trong container
    docker exec wg-easy iptables -t nat -A POSTROUTING -o wg0 -j MASQUERADE 2>/dev/null
    echo "Đã cấp quyền route VPN (10.8.0.x -> $WG_IP) thành công!"
else
    echo "Không tìm thấy container wg-easy!"
fi
