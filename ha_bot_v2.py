import telebot
from telebot import types
import subprocess
import os
import json
import sys
import threading

download_lock = threading.Lock()

CONFIG_PATH = "/opt/bot_manager.json"

def load_config():
    if not os.path.exists(CONFIG_PATH):
        # Trả về cấu hình mặc định nếu file chưa tồn tại
        return {
            "admin_ids": [123456789],
            "bots": {
                "main": {
                    "token": "YOUR_BOT_TOKEN_HERE",
                    "channel_id": -100123456789,
                    "description": "Bot quản lý tổng và backup mặc định"
                }
            },
            "mappings": {
                "default": "main"
            }
        }
    try:
        with open(CONFIG_PATH, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading config: {e}")
        return None

config = load_config()

TOKEN = config["bots"]["main"]["token"]
ADMIN_IDS = config["admin_ids"]
CHANNEL_ID = config["bots"]["main"].get("channel_id")

bot = telebot.TeleBot(TOKEN)

# Ánh xạ tên thân thiện (Tùy chỉnh trong projects.json hoặc tại đây)
FRIENDLY_NAMES = {
    "example.com": "🌐 Dự án mẫu",
}

def is_admin(message):
    return message.chat.id in ADMIN_IDS

PROJECTS_DATA = "/opt/projects.json"

def get_pi_projects():
    """Lấy danh sách domain từ projects.json"""
    projects = {}
    try:
        if os.path.exists(PROJECTS_DATA):
            with open(PROJECTS_DATA, 'r') as f:
                data = json.load(f)
                for dom in data.keys():
                    display_name = FRIENDLY_NAMES.get(dom, f"🌐 {dom}")
                    projects[dom] = display_name
    except Exception as e:
        print(f"Error loading projects JSON: {e}")
    return projects

@bot.message_handler(commands=['scan'])
def manual_scan(message):
    if not is_admin(message): return
    bot.reply_to(message, "🔍 Đang quét hệ thống Docker để tìm website mới...")
    subprocess.run(["python3", "/opt/sync_projects.py"])
    bot.send_message(message.chat.id, "✅ Đã cập nhật danh sách dự án! Bạn có thể thử lệnh /backup ngay.")

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    if not is_admin(message):
        bot.reply_to(message, f"Xin chào! Chat ID của bạn là: {message.chat.id}. Hãy gửi ID này cho Admin chính để được cấp quyền.")
        return
    
    help_text = "📊 /status - Kiểm tra trạng thái các dự án trên Pi\n"
    help_text += "📦 /backup - **Sao lưu thủ công:** Chọn dự án và thành phần.\n"
    help_text += "🔄 /restore - **Khôi phục:** Chọn bản backup để ghi đè dữ liệu.\n"
    help_text += "🧹 /cleanup - **Dọn dẹp:** Xóa backup cũ > 60 ngày trên Pi.\n\n"
    help_text += "💡 *Mẹo: Forward tin nhắn từ Kênh vào đây để mình lấy ID Kênh.*"
    
    bot.reply_to(message, help_text, parse_mode='Markdown')

@bot.message_handler(func=lambda m: m.forward_from_chat is not None)
def handle_forwarded(message):
    if not is_admin(message): return
    chat_id = message.forward_from_chat.id
    chat_title = message.forward_from_chat.title
    bot.reply_to(message, f"📌 **Đã bắt được ID Kênh!**\n\n- Tên Kênh: `{chat_title}`\n- ID: `{chat_id}`\n\nBạn hãy copy ID này gửi cho mình để mình cấu hình nhé!", parse_mode='Markdown')

@bot.message_handler(commands=['status'])
def check_status(message):
    if not is_admin(message): return
    
    projects = get_pi_projects()
    
    response = "🍓 **Máy chủ Pi:**\n"
    response += "--------------------------------\n"
    
    if not projects:
        response += "Chưa phát hiện dự án nào đang chạy.\n"
    else:
        for domain, name in projects.items():
            # Ánh xạ ngược domain sang service cloudflared (chỉ để check status)
            # api.thoigianranh.com và thoigianranh.com dùng chung service cloudflared-thoigianranh
            service_key = domain.split('.')[-2] # Lấy "thoigianranh" hoặc "vungvang"
            service = f"cloudflared-{service_key}"
            
            state = subprocess.getoutput(f"systemctl is-active {service} 2>/dev/null")
            emoji = "✅ Active" if state == "active" else "❌ Inactive"
            response += f"{name}: {emoji}\n"
    
    bot.reply_to(message, response, parse_mode='Markdown')

@bot.message_handler(commands=['cleanup'])
def manual_cleanup(message):
    if not is_admin(message): return
    bot.reply_to(message, "⏳ Đang quét và dọn dẹp các bản backup cũ (> 60 ngày)...")
    
    cmd = "find /opt/backups -type d -mtime +60 -exec rm -rf {} + 2>&1"
    res = subprocess.getoutput(cmd)
    
    if not res:
        res = "Đã dọn dẹp xong! Không còn bản backup nào quá 60 ngày."
    
    bot.send_message(message.chat.id, f"🧹 **Kết quả dọn dẹp:**\n\n```\n{res}\n```", parse_mode='Markdown')

# --- BACKUP & RESTORE LOGIC ---

@bot.message_handler(commands=['backup'])
def manual_backup(message):
    if not is_admin(message): return
    markup = types.InlineKeyboardMarkup(row_width=1)
    
    projects = get_pi_projects()
    if not projects:
        bot.reply_to(message, "Không tìm thấy dự án nào để backup.")
        return
        
    for domain, name in projects.items():
        markup.add(types.InlineKeyboardButton(f"📦 Backup {name}", callback_data=f"bak_{domain}"))
        
    bot.send_message(message.chat.id, "Chọn dự án bạn muốn sao lưu ngay bây giờ:", reply_markup=markup)

@bot.callback_query_handler(func=lambda call: call.data.startswith("bak_"))
def handle_project_select(call):
    if not is_admin(call.message): return
    project = call.data.replace("bak_", "") # Đây là domain đầy đủ
    
    markup = types.InlineKeyboardMarkup(row_width=2)
    types_list = [
        ("🗄 DB", "type_db"),
        ("🎨 Theme", "type_theme"),
        ("🔌 Plugin", "type_plugin"),
        ("🖼 Media", "type_media"),
        ("📦 Full Backup", "type_all")
    ]
    btns = [types.InlineKeyboardButton(t[0], callback_data=f"{t[1]}_{project}") for t in types_list]
    markup.add(*btns)
    
    bot.edit_message_text(f"Dự án: **{project}**\nChọn loại dữ liệu cần sao lưu:", 
                          call.message.chat.id, call.message.message_id, reply_markup=markup, parse_mode='Markdown')

@bot.callback_query_handler(func=lambda call: call.data.startswith("type_"))
def handle_type_select(call):
    if not is_admin(call.message): return
    data = call.data.split("_")
    bak_type = data[1]
    project = data[2] # Full domain
    
    bot.answer_callback_query(call.id, f"Đang chạy backup {bak_type}...")
    bot.edit_message_text(f"⏳ Đang thực hiện sao lưu **{bak_type}** cho **{project}**...", 
                          call.message.chat.id, call.message.message_id, parse_mode='Markdown')
    
    if bak_type == "all":
        # Chạy lần lượt các thành phần: DB -> Theme -> Plugin -> Media
        res = ""
        components = [("🗄 DB", "db"), ("🎨 Theme", "theme"), ("🔌 Plugin", "plugin"), ("🖼 Media", "media")]
        for name, t in components:
            bot.edit_message_text(f"⏳ Đang thực hiện sao lưu **{name}** cho **{project}**...", 
                                  call.message.chat.id, call.message.message_id, parse_mode='Markdown')
            cmd = f"/opt/advanced_backup.sh {project} {t}"
            res += f"--- {name} ---\n" + subprocess.getoutput(cmd) + "\n\n"
    else:
        cmd = f"/opt/advanced_backup.sh {project} {bak_type}"
        res = subprocess.getoutput(cmd)
        
    bot.send_message(call.message.chat.id, f"✅ **Backup hoàn tất!**\nFile đã được đẩy lên Kênh VPS.\n\n```\n{res[-1000:]}\n```", parse_mode='Markdown')

@bot.message_handler(commands=['restore'])
def manual_restore(message):
    if not is_admin(message): return
    help_text = "🔄 **Hệ Thống Khôi Phục (Restore):**\n\n"
    help_text += "Vì lý do bảo mật và tiết kiệm bộ nhớ, VPS không lưu bản backup cũ sau khi đã gửi lên Telegram cho bạn.\n\n"
    help_text += "👉 **Cách khôi phục:**\n"
    help_text += "1. Tìm tệp backup trong **Kênh VPS**.\n"
    help_text += "2. **Forward (Chuyển tiếp)** tệp đó vào Bot này.\n"
    help_text += "3. Bot sẽ nhận tệp và hướng dẫn bạn khôi phục.\n\n"
    help_text += "💡 *Mẹo: Nếu file có nhiều phần (.part_aa, .part_ab...), hãy gửi lần lượt từng phần vào đây.*"
    bot.reply_to(message, help_text, parse_mode='Markdown')

@bot.message_handler(content_types=['document'])
def handle_docs(message):
    if not is_admin(message): return
    file_name = message.document.file_name
    
    # Chỉ nhận các định dạng nén của hệ thống
    if not (file_name.endswith('.tar.gz') or '.tar.gz.part_' in file_name):
        bot.reply_to(message, "❌ Định dạng tệp không hợp lệ. Vui lòng gửi tệp `.tar.gz` hoặc các phần `.part_xx` từ Kênh VPS.")
        return

    msg = bot.reply_to(message, f"⏳ Đang chờ lượt để tải tệp `{file_name}`...", parse_mode='Markdown')
    
    with download_lock:
        bot.edit_message_text(f"🚀 Đang tải tệp `{file_name}` về VPS...", message.chat.id, msg.message_id, parse_mode='Markdown')
        
        # Thư mục tạm để restore
        restore_base = "/opt/restore_buffer"
        os.makedirs(restore_base, exist_ok=True)
        
        try:
            file_info = bot.get_file(message.document.file_id)
            downloaded_file = bot.download_file(file_info.file_path)
            
            dest_path = os.path.join(restore_base, file_name)
            with open(dest_path, 'wb') as new_file:
                new_file.write(downloaded_file)
            
            # Lấy tên dự án từ tên file: vungvang.com_all_2026-03-11.tar.gz -> vungvang.com
            parts = file_name.split('_')
            project = parts[0] if parts else "default"
            
            markup = types.InlineKeyboardMarkup(row_width=2)
            # Rút gọn callback_data để tránh lỗi BUTTON_DATA_INVALID (max 64 bytes)
            btn_start = types.InlineKeyboardButton("🚀 Chạy Khôi Phục", callback_data=f"dr_{project}")
            btn_del = types.InlineKeyboardButton("🗑 Xóa file", callback_data=f"df_{file_name}")
            markup.add(btn_start, btn_del)
            
            bot.edit_message_text(f"✅ Đã nhận: `{file_name}`\nDự án dự kiến: **{project}**\n\nBạn muốn làm gì?", 
                                   message.chat.id, msg.message_id, reply_markup=markup, parse_mode='Markdown')
        except Exception as e:
            bot.edit_message_text(f"❌ Lỗi khi nhận file: {e}", message.chat.id, msg.message_id)

@bot.callback_query_handler(func=lambda call: call.data.startswith("df_"))
def handle_delete_file(call):
    filename = call.data.replace("df_", "")
    path = os.path.join("/opt/restore_buffer", filename)
    if os.path.exists(path):
        os.remove(path)
    bot.edit_message_text(f"🗑 Đã xóa tệp tạm `{filename}`.", call.message.chat.id, call.message.message_id)

@bot.callback_query_handler(func=lambda call: call.data.startswith("dr_"))
def handle_restore_execute(call):
    if not is_admin(call.message): return
    # Lấy project từ callback: dr_project_name
    project = call.data.split("_")[1]
    
    bot.edit_message_text(f"⏳ Đang khôi phục **{project}**... \n(Đã giới hạn CPU 90% để ưu tiên Web truy cập)", 
                          call.message.chat.id, call.message.message_id, parse_mode='Markdown')
    
    # Chạy script restore
    cmd = f"/opt/restore_project.sh {project} /opt/restore_buffer"
    res = subprocess.getoutput(cmd)
    
    # Dọn dẹp folder đệm sau khi xong
    subprocess.run("rm -rf /opt/restore_buffer/*", shell=True)
    
    bot.send_message(call.message.chat.id, f"🏁 **Kết quả khôi phục {project}:**\n\n```\n{res}\n```", parse_mode='Markdown')

print("Bot is running...")
bot.infinity_polling()
