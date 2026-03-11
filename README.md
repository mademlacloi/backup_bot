# 🚀 VPS Backup Bot System

Hệ thống quản lý VPS và sao lưu dữ liệu tự động qua Telegram, được tối ưu hóa cho các dự án chạy trên Docker.

## ✨ Tính năng chính

- **Quản lý tập trung**: Một Bot có thể quản lý nhiều website, hoặc mỗi website một Bot riêng (Multi-Bot).
- **Tự động quét dự án**: Heuristic tự động nhận diện Container WordPress, MariaDB và mã nguồn từ Docker Compose.
- **Backup tách lớp**: Hỗ trợ sao lưu riêng biệt Database, Themes, Plugins, Uploads hoặc Full Backup.
- **Gửi file lên Telegram**: Tự động chia nhỏ file lớn (>18MB) để vượt qua giới hạn của Telegram.
- **Khôi phục dễ dàng**: Forward file backup vào Bot để thực hiện Restore tự động.
- **Tối ưu hiệu năng**: Tự động giới hạn CPU khi nén file để không ảnh hưởng đến Website đang hoạt động.

## 🛠 Yêu cầu hệ thống

- HĐH: Linux (Ubuntu/Debian).
- Công cụ: `jq`, `python3`, `pip3`, `cpulimit`, `tar`, `curl`.
- Docker & Docker Compose (cho các website cần backup).

## 🚀 Cài đặt nhanh

Để cài đặt tự động từ GitHub, hãy chạy lệnh sau:

```bash
curl -sL https://raw.githubusercontent.com/mademlacloi/backup_bot/main/install_backup_bot.sh | bash
```

Sau khi cài đặt, hãy cấu hình Token tại `/opt/bot_manager.json` và gõ lệnh `backupbot` để bắt đầu.

## 📖 Hướng dẫn chi tiết

Vui lòng xem file [huong_dan_cai_dat.md](huong_dan_cai_dat.md) để biết cách cài đặt thủ công và các cấu hình nâng cao.

## 🛡 Bảo mật

- Không bao giờ chia sẻ file `bot_manager.json` hoặc `projects.json` công khai vì chúng chứa Token và mật khẩu Database của bạn.
- Hệ thống đi kèm file `.gitignore` để tránh đẩy nhầm các thông tin nhạy cảm này lên GitHub.

---
Phát triển bởi [mademlacloi](https://github.com/mademlacloi)
