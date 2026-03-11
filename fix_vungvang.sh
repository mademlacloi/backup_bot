#!/bin/bash
cd /opt/vungvang-server
docker compose stop mariadb wordpress
docker compose rm -f mariadb wordpress
docker volume rm vungvang-server_vungvang_db_data
sed -i 's/MYSQL_ROOT_PASSWORD.*/MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}/g' docker-compose.yml
sed -i 's/MYSQL_DATABASE.*/MYSQL_DATABASE: ${MYSQL_DATABASE}/g' docker-compose.yml
sed -i 's/MYSQL_USER.*/MYSQL_USER: ${MYSQL_USER}/g' docker-compose.yml
sed -i 's/MYSQL_PASSWORD.*/MYSQL_PASSWORD: ${MYSQL_PASSWORD}/g' docker-compose.yml
docker compose up -d
