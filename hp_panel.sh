#!/bin/bash
# HP Control Panel - Giao diện quản lý VPS Pi chuyên nghiệp

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

show_menu() {
    clear
    echo -e "${CYAN}${BOLD}=================================================="
    echo -e "   🏰 HỆ THỐNG QUẢN TRỊ VPS PI - HA CONTROL PANEL"
    echo -e "==================================================${NC}"
    echo -e "${YELLOW}1.${NC} 🤖 Quản lý Bot Telegram (Restart/Logs)"
    echo -e "${YELLOW}2.${NC} 📦 Sao lưu dự án (Backup)"
    echo -e "${YELLOW}3.${NC} 🔄 Khôi phục dữ liệu (Restore)"
    echo -e "${YELLOW}4.${NC} 📊 Kiểm tra trạng thái hệ thống"
    echo -e "${YELLOW}5.${NC} 🧹 Dọn dẹp bản backup cũ"
    echo -e "${YELLOW}0.${NC} 🚪 Thoát"
    echo -e "${CYAN}==================================================${NC}"
    echo -n "Chọn một tùy chọn [0-5]: "
}

manage_bot() {
    clear
    echo -e "${BLUE}--- Quản lý Bot Telegram ---${NC}"
    echo "1. Restart Bot (Cập nhật cấu hình)"
    echo "2. Xem Logs trực tiếp (Theo dõi hành động)"
    echo "0. Quay lại"
    read -p "Chọn: " bot_opt
    case $bot_opt in
        1) systemctl restart ha_bot && echo -e "${GREEN}Đã restart Bot thành công!${NC}" ;;
        2) journalctl -u ha_bot -f ;;
    esac
    sleep 2
}

run_backup() {
    clear
    echo -e "${BLUE}--- Sao lưu thủ công ---${NC}"
    echo "Danh sách dự án khả dụng:"
    # Tự động lấy danh sách dự án từ service
    ls /etc/systemd/system/cloudflared-*.service | xargs -n 1 basename | sed 's/cloudflared-//' | sed 's/.service//' | grep -v "update"
    
    read -p "Nhập tên dự án (ví dụ: vungvang): " proj
    echo -e "Loại backup: ${CYAN}db, theme, plugin, media, all${NC}"
    read -p "Chọn loại: " type
    
    echo -e "${YELLOW}Đang chạy backup... Vui lòng không tắt terminal.${NC}"
    /opt/advanced_backup.sh ${proj}.com $type
    read -p "Bấm phím bất kỳ để tiếp tục..."
}

run_restore() {
    clear
    echo -e "${RED}--- KHÔI PHỤC DỮ LIỆU ---${NC}"
    echo "Lưu ý: Bạn cần Forward file từ Telegram vào Bot trước để tải về VPS."
    read -p "Dự án cần khôi phục (vungvang/thoigianranh): " proj
    
    if [ -d "/opt/restore_buffer" ]; then
        echo "Dữ liệu tìm thấy trong vùng đệm:"
        ls -lh /opt/restore_buffer
    fi
    
    read -p "Xác nhận chạy khôi phục dự án $proj? (y/n): " confirm
    if [ "$confirm" == "y" ]; then
        /opt/restore_project.sh $proj /opt/restore_buffer
    fi
    read -p "Bấm phím bất kỳ để tiếp tục..."
}

# Main Loop
while true; do
    show_menu
    read opt
    case $opt in
        1) manage_bot ;;
        2) run_backup ;;
        3) run_restore ;;
        4) /opt/alert_bot.py SEND_MSG "Checking..." # Sửa lại để chỉ in ra terminal
           /opt/alert_bot.py | head -n 20
           read -p "Bấm phím bất kỳ để tiếp tục..." ;;
        5) /opt/ha_bot_v2.py cleanup_trigger ;; # Hoặc chạy lệnh find trực tiếp
        0) clear; exit 0 ;;
        *) echo -e "${RED}Tùy chọn không hợp lệ!${NC}"; sleep 1 ;;
    esac
done
