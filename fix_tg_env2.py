import os

file_path = '/opt/thoigianranh-server/docker-compose.yml'
with open(file_path, 'r') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    if "WORDPRESS_DB_USER:" in line:
        if "MAIN" in line:
            lines[i] = "      WORDPRESS_DB_USER: ${MYSQL_USER_MAIN}\n"
        elif "API" in line:
            lines[i] = "      WORDPRESS_DB_USER: ${MYSQL_USER_API}\n"
    elif "WORDPRESS_DB_PASSWORD:" in line:
         if "MAIN" in line:
            lines[i] = "      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD_MAIN}\n"
         elif "API" in line:
            lines[i] = "      WORDPRESS_DB_PASSWORD: ${MYSQL_PASSWORD_API}\n"
    elif "WORDPRESS_DB_NAME:" in line:
         if "MAIN" in line:
            lines[i] = "      WORDPRESS_DB_NAME: ${MYSQL_DATABASE_MAIN}\n"
         elif "API" in line:
            lines[i] = "      WORDPRESS_DB_NAME: ${MYSQL_DATABASE_API}\n"

with open(file_path, 'w') as f:
    f.writelines(lines)

os.system('cd /opt/thoigianranh-server && docker compose up -d wp_main wp_api')
