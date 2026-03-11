# HƯỚNG DẪN CÀI ĐẶT BACKUP BOT THỦ CÔNG (MANUAL INSTALL)

Tài liệu này hướng dẫn bạn cách thiết lập hệ thống Backup Bot hoàn toàn từ đầu trên một VPS mới, đảm bảo hoạt động chính xác như trên VPS Pi hiện tại.

---

## 1. Chuẩn bị môi trường hệ thống

Trước tiên, bạn cần cài đặt các công cụ bổ trợ để bot có thể nén file, xử lý JSON và giới hạn CPU khi backup.

Gõ lệnh sau:

```bash
sudo apt-get update && sudo apt-get install -y jq python3-pip cpulimit tar curl
```

Cài đặt thư viện Python cần thiết:

```bash
sudo pip3 install pyTelegramBotAPI requests --break-system-packages
```

---

## 2. Thiết lập cấu trúc thư mục

Hệ thống mặc định hoạt động trong thư mục `/opt`. Hãy tạo các thư mục cần thiết:

```bash
sudo mkdir -p /opt/backups
sudo mkdir -p /opt/restore_buffer
sudo chmod 777 /opt/backups /opt/restore_buffer
```

---

## 3. Các file mã nguồn (Scripts)

Bạn cần copy các file scripts sau vào thư mục `/opt/`. Đảm bảo nội dung file khớp với phiên bản bạn đang dùng:

1. `ha_bot_v2.py`: Bot điều khiển chính.
2. `advanced_backup.sh`: Script thực hiện backup DB/Web.
3. `sync_projects.py`: Quét Docker để cập nhật dự án.
4. `backup_panel.sh`: Giao diện dòng lệnh (Menu).
5. `alert_bot.py`: Công cụ gửi tin nhắn/file lên Telegram.
6. `restore_project.sh`: Script khôi phục dữ liệu.
7. `uninstall_backup_bot.sh`: Script gỡ cài đặt.

**Cấp quyền thực thi:**
```bash
sudo chmod +x /opt/*.sh
sudo chmod +x /opt/*.py
```

---

## 4. Cấu hình file JSON (Quan trọng)

Bạn cần tạo 2 file cấu hình tại `/opt/` để Bot nhận diện Admin và Dự án.

### File 1: `/opt/bot_manager.json`
Dùng để khai báo Token Bot và ID Admin.

```json
{
    "admin_ids": [123456789],
    "bots": {
        "main": {
            "token": "123456789:ABCDefghIJKLmnopQRSTuvwxYZ",
            "channel_id": -100123456789,
            "description": "Bot quản lý tổng và backup mặc định"
        }
    },
    "mappings": {
        "default": "main"
    }
}
```

### File 2: `/opt/projects.json`
Dùng để ánh xạ Domain với Container. (Bạn có thể để trống `{}` rồi chạy lệnh quét sau).

```json
{
    "example.com": {
        "wp_container": "tên_container_wordpress",
        "db_container": "tên_container_db",
        "db_name": "tên_database",
        "db_pass": "mật_khẩu_root_db"
    }
}
```

---

## 5. Thiết lập Service để Bot chạy ngầm

Tạo file service để Bot tự khởi động cùng VPS:

```bash
cat <<EOF | sudo tee /etc/systemd/system/ha_bot.service
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

# Kích hoạt service
sudo systemctl daemon-reload
sudo systemctl enable ha_bot
sudo systemctl start ha_bot
```

---

## 6. Tạo phím tắt quản lý (Alias)

Để gõ lệnh `backupbot` ra ngay menu quản lý, hãy thêm dòng sau vào cuối file `~/.bashrc`:

```bash
echo "alias backupbot='/opt/backup_panel.sh'" >> ~/.bashrc
source ~/.bashrc
```

---

## 8. Giải đáp các thắc mắc thường gặp (FAQ)

### 1. Cài đặt Bot trước khi triển khai Web có được không?
**Hoàn toàn được.** 
- Bạn có thể cài đặt Backup Bot bất cứ lúc nào. Khi bạn chưa có Web, file `projects.json` sẽ trống hoặc chỉ có dự án mẫu.
- Sau khi bạn triển khai Web mới (bằng Docker Compose) vào thư mục `/opt/`, bạn chỉ cần chạy lệnh sau để Bot tự cập nhật danh sách:
  ```bash
  sudo python3 /opt/sync_projects.py
  ```
  Hoặc gõ lệnh `/scan` trực tiếp trong chat với Bot Telegram. Node Bot sẽ tự động tìm thấy Web mới và hiển thị trong menu `/backup`.

### 2. Tại sao cấu hình sai mà vẫn báo "Bot is running"?
Hiện tại, log "Bot is running" chỉ thông báo là script Python đã chạy, nó không xác nhận Token của bạn có đúng hay không. 
- **Cách kiểm tra thủ công:** Sau khi chạy service, hãy kiểm tra log hệ thống bằng lệnh:
  ```bash
  sudo journalctl -u ha_bot -f
  ```
  Nếu Token sai, bạn sẽ thấy lỗi `api.telegram.org` hoặc `Unauthorized` liên tục trong log.

---

## 9. Mẹo kiểm tra Token Bot nhanh

Để đảm bảo Token Bot của bạn hoạt động trước khi cài làm Service, hãy chạy thử lệnh này:

```bash
sudo python3 -c "import telebot; b=telebot.TeleBot('TOKEN_CỦA_BẠN'); print(b.get_me())"
```
- Nếu hiện ra thông tin Bot (ID, Username) -> **Thành công.**
- Nếu báo lỗi `Unauthorized` hoặc `Invalid Token` -> **Bạn cần kiểm tra lại Token.**

> [!IMPORTANT]
> Luôn sử dụng lệnh `sudo journalctl -u ha_bot -n 50` để kiểm tra lỗi nếu thấy Bot không phản hồi trên Telegram.

---

## 10. Cấu hình Nâng cao: Multi-Bot & Bot Tổng

Hệ thống của bạn hỗ trợ hai chế độ quản lý thông báo và gửi file backup:

### CHẾ ĐỘ 1: Bot Tổng (Mặc định)
Tất cả các dự án đều gửi thông báo và file backup về cùng một Bot và một Kênh duy nhất.
- **Cách thiết lập**: Cấu hình Token và Channel ID trong mục `main` của file `bot_manager.json`. Phần `mappings` chỉ cần để `"default": "main"`.

### CHẾ ĐỘ 2: Multi-Bot (Mỗi dự án một Bot riêng)
Bạn muốn mỗi khách hàng hoặc mỗi website có một Bot riêng để bảo mật và tách biệt dữ liệu.

**Bước 1: Thêm Bot mới vào hệ thống**
Sử dụng script `manage_bots.py` để thêm (ví dụ đặt tên bot là `bot_vungvang`):
```bash
sudo python3 /opt/manage_bots.py add bot_vungvang "TOKEN_BOT_MOI" "-100xxxx_CHANNEL_ID" "Bot cho vungvang.com"
```

**Bước 2: Ánh xạ Website với Bot mới**
Gán domain `vungvang.com` sử dụng bot vừa thêm:
```bash
sudo python3 /opt/manage_bots.py map vungvang.com bot_vungvang
```

**Kiểm tra lại cấu hình:**
```bash
sudo python3 /opt/manage_bots.py view
```

### Tại sao cần Multi-Bot?
- **Phân quyền**: Bạn có thể cho khách hàng làm Admin của Bot riêng họ mà không thấy các dự án khác của bạn.
- **Tổ chức**: File backup của từng web sẽ được đẩy vào các Kênh (Channel) riêng biệt, dễ tìm kiếm hơn.

---

## 11. Các lệnh quản lý nhanh (Cheat Sheet)

| Lệnh | Chức năng |
| :--- | :--- |
| `backupbot` | Mở menu quản trị (Backup/Restore/Status). |
| `sudo python3 /opt/sync_projects.py` | Quét lại Docker để cập nhật website mới vào Bot. |
| `sudo python3 /opt/manage_bots.py list` | Xem danh sách các Bot đang có. |
| `sudo systemctl restart ha_bot` | Khởi động lại Bot (sau khi sửa config). |
| `sudo journalctl -u ha_bot -f` | Xem log trực tiếp của Bot để bắt lỗi. |
