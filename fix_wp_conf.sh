#!/bin/bash
cd /opt/vungvang-server
sed -i "s/\\\\$\\\\$/\$_SERVER/g" docker-compose.yml
docker compose up -d wordpress
