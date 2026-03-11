# 🤖 VPS Backup Bot System

Hệ thống quản trị dự án Docker và Sao lưu tự động qua Telegram dành cho VPS (đặc biệt tối ưu cho ARM/Pi).

## ✨ Tính năng nổi bật
- **Auto-Discovery**: Tự động nhận diện Website/Subdomain mới từ Docker-compose.
- **Multi-Bot**: Gán nhiều Bot Telegram khác nhau cho từng tên miền khác nhau.
- **Smart Backup**: Tách riêng DB, Theme, Plugin, Media; Chia nhỏ file tự động (bypass limit Telegram 2GB).
- **CPU Control**: Tự động giới hạn CPU khi nén file để không làm treo VPS (Nice/Cpulimit).
- **Terminal UI**: Bảng điều khiển trực quan bằng lệnh `backupbot`.

## 🚀 Cài đặt nhanh (1 chạm)
Sử dụng một dòng lệnh duy nhất để cài đặt toàn bộ hệ thống lên VPS mới:

```bash
curl -O https://raw.githubusercontent.com/mademlacloi/backup_bot/main/install_backup_bot.sh && chmod +x install_backup_bot.sh && ./install_backup_bot.sh
```
*(Lưu ý: Thay URL trên bằng URL Git thực tế của bạn sau khi push)*

## ⌨️ Các lệnh điều khiển
- `backupbot`: Mở bảng điều khiển giao diện Terminal.
- `/backup` (trên Telegram): Chạy sao lưu từ xa.
- `/status` (trên Telegram): Kiểm tra tình trạng các dự án.
- `/scan` (trên Telegram): Cập nhật danh sách website mới cài.

## 🗑️ Gỡ cài đặt
Nếu không muốn sử dụng nữa, hãy chạy:
```bash
bash /opt/uninstall_backup_bot.sh
```
