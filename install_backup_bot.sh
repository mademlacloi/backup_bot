#!/bin/bash
# 🚀 ONE-CLICK INSTALLER: VPS CONTROL PANEL & BACKUP SYSTEM
# -------------------------------------------------------------------------
# CƠ CHẾ HOẠT ĐỘNG:
# 1. Quét Docker Compose và .env để tự động cấu hình dự án.
# 2. Thiết lập Bot quản trị qua Telegram (ha_bot_v2.py).
# 3. Tạo Alias 'backupbot' để truy cập menu quản trị nhanh.
# 4. Hỗ trợ backup tách lớp (DB, Plugins, Themes) & gửi Telegram.
# -------------------------------------------------------------------------

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}>>> Bắt đầu cài đặt Hệ thống Backup Bot...${NC}"

# 1. Cài đặt các gói phụ thuộc
echo "--- 📦 Cài đặt công cụ hỗ trợ (jq, python3, pip, cpulimit)... ---"
apt-get update && apt-get install -y jq python3-pip cpulimit tar 
pip3 install pyTelegramBotAPI requests --break-system-packages 2>/dev/null || pip3 install pyTelegramBotAPI requests

# 2. Tạo cấu trúc thư mục và tải script từ GitHub
echo "--- 📂 Đang tải bộ script từ GitHub... ---"
mkdir -p /opt/backups
GITHUB_RAW="https://raw.githubusercontent.com/mademlacloi/backup_bot/main"
SCRIPTS=(
    "advanced_backup.sh"
    "backup_panel.sh"
    "ha_bot_v2.py"
    "manage_bots.py"
    "alert_bot.py"
    "sync_projects.py"
    "uninstall_backup_bot.sh"
)

for script in "${SCRIPTS[@]}"; do
    echo "  + Tải: $script"
    curl -sLo "/opt/$script" "$GITHUB_RAW/$script"
done

# 3. Thiết lập Alias 'backupbot'
echo "--- ⌨️ Thiết lập lệnh gõ nhanh (Alias)... ---"
sed -i '/alias backuppanel/d' ~/.bashrc
sed -i '/alias bakupbot/d' ~/.bashrc
sed -i '/alias backupbot/d' ~/.bashrc
echo "alias backupbot='/opt/backup_panel.sh'" >> ~/.bashrc
source ~/.bashrc

# 4. Cấp quyền thực thi cho các script
echo "--- 🔑 Cấp quyền thực thi script... ---"
chmod +x /opt/*.sh
chmod +x /opt/*.py

# 5. Thiết lập Systemd Service cho Bot Telegram
echo "--- 🤖 Thiết lập Service cho Bot Telegram... ---"
cat <<EOF > /etc/systemd/system/ha_bot.service
[Unit]
Description=Telegram Control Bot
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/ha_bot_v2.py
WorkingDirectory=/opt
StandardOutput=inherit
StandardError=inherit
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ha_bot
systemctl restart ha_bot

# 6. Khởi tạo danh sách dự án lần đầu
echo "--- 🔍 Đang quét hệ thống Docker hiện có... ---"
if [ -f "/opt/sync_projects.py" ]; then
    python3 /opt/sync_projects.py
fi

echo -e "${GREEN}=================================================="
echo -e " ✅ CÀI ĐẶT HOÀN TẤT!"
echo -e "=================================================="
echo -e " 👉 Hãy gõ lệnh: ${RED}source ~/.bashrc${GREEN}"
echo -e " 👉 Sau đó gõ: ${RED}backupbot${GREEN} để bắt đầu.${NC}"
echo -e "==================================================${NC}"
