#!/bin/bash

neofetch

IFACE=$(ip route | awk '/default/ {print $5}')
SPEED=$(cat /sys/class/net/$IFACE/speed 2>/dev/null)

echo "Local IP: $(hostname -I | awk '{print $1}')"
echo "Public IP: $(curl -s ifconfig.me)"
echo "LAN Interface: $IFACE"
echo "LAN Speed: ${SPEED:-Unknown}M"

echo -e "\n\e[1;31m========================================================================\e[0m"
echo -e "\e[1;31m ⛔ CẢNH BÁO: ĐÂY LÀ MÁY PHỤ (PI BACKUP). MỌI THAY ĐỔI SẼ BỊ GHI ĐÈ TỪ GỐC! ⛔\e[0m"
echo -e "\e[1;31m========================================================================\e[0m\n"
