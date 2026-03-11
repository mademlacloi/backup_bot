import json
import os
import sys
import subprocess
import requests

CONFIG_PATH = "/opt/bot_manager.json"

def load_config():
    try:
        with open(CONFIG_PATH, 'r') as f:
            return json.load(f)
    except Exception as e:
        print(f"Error loading config: {e}")
        return None

def get_bot_for_domain(domain=None):
    config = load_config()
    if not config: return None, None, None
    
    bot_key = config["mappings"].get(domain, config["mappings"].get("default", "main"))
    bot_cfg = config["bots"].get(bot_key)
    return bot_cfg["token"], bot_cfg.get("channel_id"), config["admin_ids"][0]

def send_telegram(message, domain=None):
    token, _, admin_id = get_bot_for_domain(domain)
    if not token: return
    
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = {
        "chat_id": admin_id,
        "text": message,
        "parse_mode": "Markdown"
    }
    try:
        requests.post(url, json=payload, timeout=10)
    except Exception as e:
        print(f"Error sending telegram: {e}")

def send_telegram_file(file_path, caption="", domain=None):
    token, channel_id, admin_id = get_bot_for_domain(domain)
    if not token: 
        print("Error: No bot configured for this domain.")
        sys.exit(1)
        
    url = f"https://api.telegram.org/bot{token}/sendDocument"
    try:
        dest_id = channel_id if channel_id else admin_id
        with open(file_path, 'rb') as f:
            files = {'document': f}
            payload = {'chat_id': dest_id, 'caption': caption}
            r = requests.post(url, data=payload, files=files, timeout=60)
            r.raise_for_status()
            
            result = r.json()
            if not result.get("ok"):
                print(f"Telegram API Error: {result.get('description')}")
                sys.exit(1)
            
    except Exception as e:
        print(f"Error sending file to telegram: {e}")
        sys.exit(1)

def get_status_report():
    HP_IP = "your-vps-ip-or-ddns.com"
    HP_PORT = 22
    
    # Check HP (Cloud)
    hp_on = False
    try:
        import socket
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(2)
        hp_on = (sock.connect_ex((HP_IP, HP_PORT)) == 0)
        sock.close()
    except Exception:
        pass
        
    hp_emo = "✅ Online" if hp_on else "❌ Offline"
    
    projects = {
        "cloudflared": ("🌐 Cloudflare Tunnel", "cloudflared_nginx"),
    }
    
    # Nhận diện máy chủ hiện tại
    import os
    is_local_hp = os.path.exists('/etc/vps_hp_identity')

    msg = f"💻 **Máy chủ HP (Chính):** {hp_emo}\n"
    if hp_on:
        for s, (n, docker_name) in projects.items():
            if is_local_hp:
                st = subprocess.getoutput(f"systemctl is-active {s}").strip()
                dock_st = subprocess.getoutput(f"docker inspect -f '{{{{.State.Running}}}}' {docker_name} 2>/dev/null").strip()
            else:
                st = subprocess.getoutput(f"ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=3 -p {HP_PORT} root@{HP_IP} 'systemctl is-active {s}' 2>/dev/null").strip()
                try:
                    res = subprocess.run([
                        "ssh", "-q", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", 
                        "-o", "ConnectTimeout=3", "-p", str(HP_PORT), f"root@{HP_IP}",
                        f"docker inspect -f '{{{{.State.Running}}}}' {docker_name}"
                    ], capture_output=True, text=True)
                    dock_st = res.stdout.strip()
                except:
                    dock_st = ""
            
            is_active = 'active' in st.lower() and dock_st.lower() == 'true'
            msg += f"{n}: {'✅ Active' if is_active else '❌ Inactive'}\n"
            
    msg += "--------------------------------\n"
    msg += "🍓 **Máy chủ Dự phòng (Pi):**\n"
    
    for s, (n, docker_name) in projects.items():
        st = subprocess.getoutput(f"systemctl is-active {s}").strip()
        dock_st = subprocess.getoutput(f"docker inspect -f '{{{{.State.Running}}}}' {docker_name} 2>/dev/null").strip()
        is_active = 'active' in st.lower() and dock_st.lower() == 'true'
        msg += f"{n}: {'✅ Active' if is_active else '❌ Inactive'}\n"
    
    return msg


if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)

    if sys.argv[1] == "SEND_FILE":
        if len(sys.argv) < 3:
            print("Usage: python3 alert_bot.py SEND_FILE <file_path> [caption] [domain]")
            sys.exit(1)
        file_path = sys.argv[2]
        caption = sys.argv[3] if len(sys.argv) > 3 else f"Backup file: {os.path.basename(file_path)}"
        domain = sys.argv[4] if len(sys.argv) > 4 else None
        send_telegram_file(file_path, caption, domain)
        sys.exit(0)

    if len(sys.argv) < 4:
        print("Usage: python3 alert_bot.py <project_name> <status: FAIL/RECOVER> <server_name> [domain]")
        sys.exit(1)
        
    project = sys.argv[1]
    status = sys.argv[2]
    server_name = sys.argv[3]
    domain = sys.argv[4] if len(sys.argv) > 4 else None
    
    if status == "FAIL":
        alert_msg = f"🚨 **CẢNH BÁO KHẨN CẤP!**\n❌ Dự án **{project}** trên **{server_name}** vừa bị MẤT KẾT NỐI!\n🤖 *Hệ thống Watchdog đã tự động xử lý chuyển đổi Tunnels.*"
    else:
        alert_msg = f"🟢 **THÔNG BÁO PHỤC HỒI!**\n✅ Dự án **{project}** trên **{server_name}** vừa phản hồi SỐNG LẠI bình thường."
        
    alert_msg += "\n\n📊 **TRẠNG THÁI HỆ THỐNG HIỆN TẠI:**\n"
    alert_msg += get_status_report()
    
    send_telegram(alert_msg, domain)
