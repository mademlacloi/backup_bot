import telebot
from telebot import types
import subprocess
import os
import socket

TOKEN = "8726045761:AAF2LpKjga6Oyw8mervBEa0_dBCtUCo6_xA"
ADMIN_IDS = [1257141148] 
HP_IP = "hongkongwedding.duckdns.org"
HP_PORT = 2332

bot = telebot.TeleBot(TOKEN)

def is_admin(message):
    return message.chat.id in ADMIN_IDS

def check_remote_port(ip, port):
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        result = sock.connect_ex((ip, port))
        sock.close()
        return result == 0
    except:
        return False

@bot.message_handler(commands=['start', 'help'])
def send_welcome(message):
    if message.chat.id not in ADMIN_IDS:
        bot.reply_to(message, f"Xin chào! Chat ID của bạn là: {message.chat.id}. Hãy gửi ID này cho Admin chính để được cấp quyền.")
        return
    bot.reply_to(message, "🏰 **Hệ Thống HA Control (HP & Pi)** sẵn sàng.\n\n/status - Kiểm tra trạng thái HP & Pi\n/recover - Phục hồi dữ liệu về HP")

@bot.message_handler(commands=['status'])
def check_status(message):
    if not is_admin(message): return
    
    # Check HP (Cloud)
    hp_online = check_remote_port(HP_IP, HP_PORT)
    hp_emoji = "✅ Online" if hp_online else "❌ Offline"
    
    # Projects mapping (Tuples of Name and Docker container name)
    projects = {
        "cloudflared": ("🏰 Hongkong", "hongkong_nginx"),
        "cloudflared-vungvang": ("🌾 Vừng Vàng", "vungvang_nginx"),
        "cloudflared-thoigianranh": ("☕ Thời Gian Rảnh", "thoigianranh_nginx")
    }
    
    response = f"💻 **Máy chủ HP (Chính):** {hp_emoji}\n"
    if hp_online:
        for service, (name, dname) in projects.items():
            state = subprocess.getoutput(f"ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=3 -p {HP_PORT} root@{HP_IP} 'systemctl is-active {service}' 2>/dev/null").strip()
            try:
                res = subprocess.run([
                    "ssh", "-q", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-o", "ConnectTimeout=3", "-p", str(HP_PORT), f"root@{HP_IP}",
                    f"docker inspect -f '{{{{.State.Running}}}}' {dname}"
                ], capture_output=True, text=True)
                d_state = res.stdout.strip()
            except:
                d_state = ""
                
            is_active = state == "active" and d_state.lower() == "true"
            emoji = "✅ Active" if is_active else "❌ Inactive"
            response += f"{name}: {emoji}\n"
            
    response += "--------------------------------\n"
    response += "🍓 **Máy chủ Dự phòng (Pi):**\n"
    
    for service, (name, dname) in projects.items():
        state = subprocess.getoutput(f"systemctl is-active {service}").strip()
        d_state = subprocess.getoutput(f"docker inspect -f '{{{{.State.Running}}}}' {dname} 2>/dev/null").strip()
        is_active = state == "active" and d_state.lower() == "true"
        emoji = "✅ Active" if is_active else "❌ Inactive"
        response += f"{name}: {emoji}\n"
    
    bot.reply_to(message, response, parse_mode='Markdown')

@bot.message_handler(commands=['recover'])
def recover_options(message):
    if not is_admin(message): return
    markup = types.InlineKeyboardMarkup(row_width=1)
    btn_all = types.InlineKeyboardButton("🚀 Phục hồi TOÀN BỘ", callback_data="rec_all")
    btn_hk = types.InlineKeyboardButton("🏰 Phục hồi Hongkong", callback_data="rec_hongkong")
    btn_vv = types.InlineKeyboardButton("🌾 Phục hồi Vừng Vàng", callback_data="rec_vungvang")
    btn_tgr = types.InlineKeyboardButton("☕ Phục hồi Thời Gian Rảnh", callback_data="rec_thoigianranh")
    markup.add(btn_all, btn_hk, btn_vv, btn_tgr)
    
    bot.send_message(message.chat.id, "Chọn dự án bạn muốn phục hồi (Push-back) về HP:", reply_markup=markup)

@bot.callback_query_handler(func=lambda call: call.data.startswith("rec_"))
def handle_recover(call):
    if call.message.chat.id not in ADMIN_IDS: return
    
    project = call.data.replace("rec_", "")
    bot.answer_callback_query(call.id, f"Đang khởi động phục hồi {project}...")
    bot.edit_message_text(f"⏳ Đang thực hiện phục hồi: **{project}**... Vui lòng đợi.", call.message.chat.id, call.message.message_id, parse_mode='Markdown')
    
    # Thực hiện lệnh phục hồi với tham số
    cmd = f"/opt/failback_to_vps2.sh {project}"
    res = subprocess.getoutput(cmd)
    
    bot.send_message(call.message.chat.id, f"✅ **Kết quả phục hồi {project}:**\n\n```\n{res}\n```", parse_mode='Markdown')

print("Bot is running...")
bot.infinity_polling()
