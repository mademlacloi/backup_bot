import json
import sys
import os
# --- Hệ thống quản lý cấu hình Multi-Bot ---

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
        with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception:
        return {"admin_ids": [], "bots": {}, "mappings": {}}

def save_config(config):
    with open(CONFIG_PATH, 'w', encoding='utf-8') as f:
        json.dump(config, f, indent=4, ensure_ascii=False)

def list_bots():
    config = load_config()
    bots = config.get("bots", {})
    if not isinstance(bots, dict):
        print("❌ Lỗi cấu hình: 'bots' không phải là dictionary.")
        return
        
    print(f"{'Tên Bot':<20} | {'Mô tả':<30} | {'Channel ID'}")
    print("-" * 70)
    for name, data in bots.items():
        desc = data.get('description', 'Không có mô tả')
        cid = data.get('channel_id', 'Admin ID')
        print(f"{name:<20} | {desc:<30} | {cid}")

def add_bot(name, token, channel_id, desc):
    config = load_config()
    if "bots" not in config: config["bots"] = {}
    
    config["bots"][name] = {
        "token": token,
        "channel_id": int(channel_id) if (channel_id and str(channel_id).strip()) else None,
        "description": desc
    }
    save_config(config)
    print(f"✅ Đã thêm/cập nhật Bot: {name}")

def map_bot(domain, bot_name):
    config = load_config()
    if "bots" not in config: config["bots"] = {}
    if "mappings" not in config: config["mappings"] = {}
    
    if bot_name not in config["bots"] and bot_name != "default":
        print(f"❌ Lỗi: Bot '{bot_name}' không tồn tại trong danh sách.")
        return
    config["mappings"][domain] = bot_name
    save_config(config)
    print(f"✅ Đã gán website {domain} sử dụng Bot: {bot_name}")

def remove_bot(name):
    config = load_config()
    if name == "main":
        print("❌ Lỗi: Không thể xóa Bot 'main' (Đây là Bot hệ thống bắt buộc).")
        return
    
    if "bots" in config and name in config["bots"]:
        del config["bots"][name]
        # Chuyển các website đang dùng bot này về bot main
        if "mappings" in config:
            keys_to_fix = [k for k, v in config["mappings"].items() if v == name]
            for k in keys_to_fix:
                config["mappings"][k] = "main"
        save_config(config)
        print(f"✅ Đã xóa Bot '{name}' và chuyển các website liên quan về Bot chính.")
    else:
        print(f"❌ Lỗi: Không tìm thấy Bot có tên '{name}'.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Sử dụng: python3 manage_bots.py <list|add|map|remove|view>")
        sys.exit(1)
        
    action = sys.argv[1]
    if action == "list":
        list_bots()
    elif action == "add":
        if len(sys.argv) < 6:
            print("Thiếu tham số cho lệnh add")
            sys.exit(1)
        add_bot(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5])
    elif action == "map":
        if len(sys.argv) < 3:
            print("Thiếu tham số cho lệnh map")
            sys.exit(1)
        map_bot(sys.argv[2], sys.argv[3])
    elif action == "remove":
        if len(sys.argv) < 3:
            print("Thiếu tham số cho lệnh remove")
            sys.exit(1)
        remove_bot(sys.argv[2])
    elif action == "view":
        print(json.dumps(load_config(), indent=4, ensure_ascii=False))
