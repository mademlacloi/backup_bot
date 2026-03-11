#!/bin/bash
# BACKUP PANEL - Quản lý Sao lưu VPS Pi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Kiểm tra trạng thái thiết lập Bot
check_bot_setup() {
    if [ ! -f "/opt/ha_bot.py" ] || [ ! -f "/etc/systemd/system/ha_bot.service" ]; then
        return 1
    fi
    return 0
}

show_menu() {
    clear
    echo -e "${CYAN}${BOLD}=================================================="
    echo -e "                 BACKUP PANEL"
    echo -e "==================================================${NC}"
    echo -e "${YELLOW}1.${NC} 🤖 Quản lý Bot Telegram (Restart/Logs)"
    echo -e "${YELLOW}2.${NC} 📦 Sao lưu dự án (Backup)"
    echo -e "${YELLOW}3.${NC} ⚙️ Cấu hình Bot (Token/Gán Web)"
    echo -e "${YELLOW}4.${NC} 🔍 Quét & Tìm website mới (Auto-Discovery)"
    echo -e "${YELLOW}0.${NC} 🚪 Thoát"
    echo -e "${CYAN}==================================================${NC}"
    echo -n "Chọn một tùy chọn [0-4]: "
}

scan_projects() {
    echo -e "${YELLOW}🔍 Đang quét hệ thống Docker và tệp cấu hình...${NC}"
    python3 /opt/sync_projects.py
    echo -e "${GREEN}✅ Hoàn tất! Danh sách dự án đã được cập nhật.${NC}"
    sleep 2
}

config_bots() {
    while true; do
        clear
        echo -e "${BLUE}--- ⚙️ Cấu hình Đa Bot Telegram ---${NC}"
        echo "1. Xem danh sách Bot & Mapping"
        echo "2. Thêm/Cập nhật Bot mới"
        echo "3. Gán Bot cho Website"
        echo "4. Xóa Bot khỏi cấu hình"
        echo "0. Quay lại"
        read -p "Chọn: " cfg_opt
        case $cfg_opt in
            1) python3 /opt/manage_bots.py view; read -p "Bấm phím bất kỳ..." ;;
            2) 
                read -p "Tên gợi nhớ (vd: vungvang_bot): " bname
                read -p "Token: " btoken
                read -p "Channel ID (Để trống nếu dùng ID Admin): " bcid
                read -p "Mô tả ngắn: " bdesc
                python3 /opt/manage_bots.py add "$bname" "$btoken" "$bcid" "$bdesc"
                sleep 2
                ;;
            3)
                read -p "Tên miền (vd: vungvang.com): " bdom
                echo "Các bot đang có:"
                python3 /opt/manage_bots.py list
                read -p "Tên Bot muốn gán: " btarget
                python3 /opt/manage_bots.py map "$bdom" "$btarget"
                sleep 2
                ;;
            4)
                echo "Các bot đang có:"
                python3 /opt/manage_bots.py list
                read -p "Nhập chính xác tên Bot muốn xóa: " bdel
                python3 /opt/manage_bots.py remove "$bdel"
                sleep 2
                ;;
            0) break ;;
        esac
    done
}

manage_bot() {
    clear
    echo -e "${BLUE}--- Quản lý Bot Telegram ---${NC}"
    if ! check_bot_setup; then
        echo -e "${RED}Lỗi: Bot chưa được thiết lập trên hệ thống này!${NC}"
        echo "Vui lòng cài đặt ha_bot.py và ha_bot.service trước."
        sleep 3
        return
    fi
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
    echo -e "${BLUE}--- Sao lưu dự án ---${NC}"
    
    if ! check_bot_setup; then
        echo -e "${RED}Lỗi: Cần thiết lập Bot Telegram trước khi chạy Backup!${NC}"
        read -p "Bấm phím bất kỳ để quay lại..."
        return
    fi

    # 1. Lấy và chọn Dự án từ projects.json
    local projects=($(jq -r 'keys[]' /opt/projects.json 2>/dev/null))
    
    if [ ${#projects[@]} -eq 0 ]; then
        echo -e "${RED}Không tìm thấy dự án nào. Hãy chạy lệnh 'Quét dự án' trước.${NC}"
        read -p "Bấm phím bất kỳ..."
        return
    fi

    while true; do
        echo -e "\nDanh sách dự án khả dụng:"
        for i in "${!projects[@]}"; do
            echo -e "${YELLOW}$((i+1)).${NC} ${projects[$i]}"
        done
        read -p "Chọn dự án (nhập Số hoặc Tên): " proj_input
        
        selected_proj=""
        # Kiểm tra xem có phải là số không
        if [[ "$proj_input" =~ ^[0-9]+$ ]] && [ "$proj_input" -ge 1 ] && [ "$proj_input" -le "${#projects[@]}" ]; then
            selected_proj="${projects[$((proj_input-1))]}"
        else
            # Kiểm tra xem có phải là tên dự án không
            for p in "${projects[@]}"; do
                if [ "$proj_input" == "$p" ]; then
                    selected_proj="$p"
                    break
                fi
            done
        fi

        if [ -n "$selected_proj" ]; then break; fi
        echo -e "${RED}Lỗi: Lựa chọn '$proj_input' không hợp lệ. Vui lòng thử lại!${NC}"
    done

    # 2. Chọn Loại Backup
    local types=("db" "theme" "plugin" "media" "all")
    while true; do
        echo -e "\nLoại backup khả dụng cho ${BOLD}${selected_proj}${NC}:"
        for i in "${!types[@]}"; do
            echo -e "${YELLOW}$((i+1)).${NC} ${types[$i]}"
        done
        read -p "Chọn loại (nhập Số hoặc Tên): " type_input
        
        selected_type=""
        if [[ "$type_input" =~ ^[0-9]+$ ]] && [ "$type_input" -ge 1 ] && [ "$type_input" -le "${#types[@]}" ]; then
            selected_type="${types[$((type_input-1))]}"
        else
            for t in "${types[@]}"; do
                if [ "$type_input" == "$t" ]; then
                    selected_type="$t"
                    break
                fi
            done
        fi

        if [ -n "$selected_type" ]; then break; fi
        echo -e "${RED}Lỗi: Loại '$type_input' không hợp lệ. Vui lòng thử lại!${NC}"
    done
    
    echo -e "\n${YELLOW}>> Đang chạy backup ${BOLD}${selected_type}${NC} cho ${BOLD}${selected_proj}${NC}...${NC}"
    /opt/advanced_backup.sh "$selected_proj" "$selected_type"
    read -p "Hoàn tất. Bấm phím bất kỳ để tiếp tục..."
}

while true; do
    show_menu
    read opt
    case $opt in
        1) manage_bot ;;
        2) run_backup ;;
        3) config_bots ;;
        4) scan_projects ;;
        0) clear; exit 0 ;;
        *) echo -e "${RED}Tùy chọn không hợp lệ!${NC}"; sleep 1 ;;
    esac
done
