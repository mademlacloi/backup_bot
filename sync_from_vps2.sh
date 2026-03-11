#!/bin/bash
# Kịch bản đồng bộ PULL: VPS2 -> VPS1 (Chạy trên VPS1)
set -e

REMOTE_IP="10.8.0.8"
REMOTE_PORT="22"
SSH_CMD="ssh -p $REMOTE_PORT"

echo "=== Pulling Source Files from VPS2: $(date) ==="
rsync -az --delete -e "$SSH_CMD" root@$REMOTE_IP:/opt/thoigianranh-server/ /opt/thoigianranh-server/
rsync -az --delete -e "$SSH_CMD" root@$REMOTE_IP:/opt/vungvang-server/ /opt/vungvang-server/

echo "=== Pulling Databases from VPS2 ==="

# 1. thoigianranh_db_main
$SSH_CMD root@$REMOTE_IP "docker exec -e MYSQL_PWD='thoigianranh_R00t_M4in_2026!' thoigianranh_db_main mariadb-dump -u root --all-databases --single-transaction" 2>/dev/null | docker exec -i thoigianranh_db_main mariadb -u root -p'thoigianranh_R00t_M4in_2026!'

# 2. thoigianranh_db_api
$SSH_CMD root@$REMOTE_IP "docker exec -e MYSQL_PWD='thoigianranh_R00t_Ap1_2026!' thoigianranh_db_api mariadb-dump -u root --all-databases --single-transaction" 2>/dev/null | docker exec -i thoigianranh_db_api mariadb -u root -p'thoigianranh_R00t_Ap1_2026!'

# 3. vungvang_mariadb
$SSH_CMD root@$REMOTE_IP "docker exec -e MYSQL_PWD='vungvang_root_2026_pass' vungvang_mariadb mariadb-dump -u root --all-databases --single-transaction" 2>/dev/null | docker exec -i vungvang_mariadb mariadb -u root -p'vungvang_root_2026_pass'

echo "Pull Sync Completed Successfully at $(date)"
