#!/bin/bash
# 🗑️ UNINSTALLER: VPS CONTROL PANEL & BACKUP SYSTEM
# Gỡ bỏ hoàn toàn hệ thống Backup Bot khỏi máy chủ

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

clear
echo -e "${RED}=================================================="
echo -e "       CẢNH BÁO: GỠ BỎ HỆ THỐNG BACKUP BOT"
echo -e "==================================================${NC}"
echo -e "Danh sách các thành phần sẽ bị gỡ bỏ khỏi VPS:"
echo -e " 1. 🤖 ${YELLOW}Service Systemd:${NC} ha_bot.service"
echo -e " 2. ⌨️ ${YELLOW}Alias Terminal:${NC} backupbot, bakupbot, backuppanel"
echo -e " 3. 📂 ${YELLOW}Script thực thi:${NC} /opt/*.sh, /opt/*.py"
echo -e " 4. ⚙️ ${YELLOW}Cấu hình JSON:${NC} projects.json, bot_manager.json"
echo -e " 5. 📦 ${YELLOW}Gói phụ thuộc:${NC} jq, cpulimit, python-telebot"
echo -e "--------------------------------------------------"

read -p "Bạn có chắc chắn muốn gỡ bỏ toàn bộ? (y/N): " confirm
if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${GREEN}>>> Đã hủy bỏ lệnh gỡ cài đặt.${NC}"
    exit 0
fi

echo -e "\n${CYAN}>>> Bắt đầu gỡ bỏ...${NC}"

# 1. Dừng và gỡ bỏ Service
echo -e "[-] Đang dừng Service Bot..."
systemctl stop ha_bot 2>/dev/null
systemctl disable ha_bot 2>/dev/null
rm -f /etc/systemd/system/ha_bot.service
systemctl daemon-reload

# 2. Xóa Alias
echo -e "[-] Đang xóa Alias trong .bashrc..."
sed -i '/alias backupbot/d' ~/.bashrc
sed -i '/alias bakupbot/d' ~/.bashrc
sed -i '/alias backuppanel/d' ~/.bashrc

# 3. Xóa các file script trong /opt
echo -e "[-] Đang xóa các tệp tin trong /opt/..."
FILES=(
    "advanced_backup.sh"
    "backup_panel.sh"
    "ha_bot_v2.py"
    "manage_bots.py"
    "alert_bot.py"
    "sync_projects.py"
    "projects.json"
    "bot_manager.json"
    "install_backup_bot.sh"
    "install.sh"
)
for file in "${FILES[@]}"; do
    [ -f "/opt/$file" ] && rm -f "/opt/$file" && echo "    + Đã xóa: $file"
done

# 4. Gỡ bỏ các gói phụ thuộc
echo -e "[-] Đang gỡ bỏ các gói phụ thuộc hệ thống..."
pip3 uninstall -y pyTelegramBotAPI requests 2>/dev/null
apt-get remove -y jq cpulimit 2>/dev/null
apt-get autoremove -y 2>/dev/null

echo -e "\n${GREEN}=================================================="
echo -e " ✅ ĐÃ GỠ BỎ TOÀN BỘ HỆ THỐNG THÀNH CÔNG!"
echo -e "=================================================="
echo -e " 👉 Hãy gõ lệnh: ${YELLOW}source ~/.bashrc${GREEN} để cập nhật."
echo -e "==================================================${NC}"

# Tự xóa tệp uninstall nếu đang chạy từ /opt
[ -f "/opt/uninstall_backup_bot.sh" ] && rm -f "/opt/uninstall_backup_bot.sh"
