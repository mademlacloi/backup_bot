import os

def fix_yaml(file_path):
    if not os.path.exists(file_path):
        return
    with open(file_path, 'r') as f:
        content = f.read()

    # Dọn dẹp config thừa vì wp-config official đã có sẵn proxy logic
    content = content.replace("        if (strpos($$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false)\n", "")
    content = content.replace("            $$_SERVER['HTTPS']='on';\n", "")
    
    with open(file_path, 'w') as f:
        f.write(content)

fix_yaml('/opt/vungvang-server/docker-compose.yml')
fix_yaml('/opt/thoigianranh-server/docker-compose.yml')
fix_yaml('/opt/hongkong-server/docker-compose.yml')

os.system('cd /opt/vungvang-server && docker compose up -d wordpress')
os.system('cd /opt/thoigianranh-server && docker compose up -d wp_main wp_api')
os.system('cd /opt/hongkong-server && docker compose up -d wordpress')
