#!/bin/bash

neofetch

IFACE=$(ip route | awk '/default/ {print $5}')
SPEED=$(cat /sys/class/net/$IFACE/speed 2>/dev/null)

echo "Local IP: $(hostname -I | awk '{print $1}')"
echo "Public IP: $(curl -s ifconfig.me)"
echo "LAN Interface: $IFACE"
echo "LAN Speed: ${SPEED:-Unknown}M"

echo -e "\n\e[1;31m========================================================================\e[0m"
echo -e "\e[1;31m ⚠️ CHÚ Ý: ĐÂY LÀ MÁY GỐC (HP CHÍNH). HÃY CẨN THẬN KHI THAO TÁC! ⚠️\e[0m"
echo -e "\e[1;31m========================================================================\e[0m\n"
