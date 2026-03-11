import os

file_path = '/opt/vungvang-server/docker-compose.yml'
with open(file_path, 'r') as f:
    content = f.read()

content = content.replace(r'\$[\'HTTP_X_FORWARDED_PROTO\']', '$_SERVER[\'HTTP_X_FORWARDED_PROTO\']')
content = content.replace(r'\$[\'HTTPS\']', '$_SERVER[\'HTTPS\']')

with open(file_path, 'w') as f:
    f.write(content)

os.system('cd /opt/vungvang-server && docker compose up -d wordpress')
