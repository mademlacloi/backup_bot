import os

file_path = '/opt/vungvang-server/docker-compose.yml'
with open(file_path, 'r') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "WORDPRESS_DB_USER:" in line:
        lines[i] = "      WORDPRESS_DB_USER: ${MYSQL_USER}\n"
    elif "WORDPRESS_DB_PASSWORD:" in line:
        lines[i] = "      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD}\n"
    elif "WORDPRESS_DB_NAME:" in line:
        lines[i] = "      WORDPRESS_DB_NAME: ${MYSQL_DATABASE}\n"

with open(file_path, 'w') as f:
    f.writelines(lines)

os.system('cd /opt/vungvang-server && docker compose up -d wordpress')
