import os

file_path = '/opt/vungvang-server/docker-compose.yml'
with open(file_path, 'r') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "'HTTP_X_FORWARDED_PROTO'" in line:
        lines[i] = "        if (strpos($$_SERVER['HTTP_X_FORWARDED_PROTO'], 'https') !== false)\n"
    elif "'HTTPS'" in line:
        lines[i] = "            $$_SERVER['HTTPS']='on';\n"

with open(file_path, 'w') as f:
    f.writelines(lines)

os.system('cd /opt/vungvang-server && docker compose up -d wordpress')
