#!/bin/bash
set -e

echo "=== Export thoigianranh_db_main ==="
docker exec -e MYSQL_PWD='thoigianranh_R00t_M4in_2026!' thoigianranh_db_main mariadb-dump -u root --all-databases --single-transaction 2>/dev/null > /tmp/th_main.sql
echo "done_main: $(du -sh /tmp/th_main.sql | cut -f1)"

echo "=== Export thoigianranh_db_api ==="
docker exec -e MYSQL_PWD='thoigianranh_R00t_Ap1_2026!' thoigianranh_db_api mariadb-dump -u root --all-databases --single-transaction 2>/dev/null > /tmp/th_api.sql
echo "done_api: $(du -sh /tmp/th_api.sql | cut -f1)"

echo "=== Export vungvang_mariadb ==="
docker exec -e MYSQL_PWD='vungvang_root_2026_pass' vungvang_mariadb mariadb-dump -u root --all-databases --single-transaction 2>/dev/null > /tmp/vv.sql
echo "done_vv: $(du -sh /tmp/vv.sql | cut -f1)"

echo "=== Export hongkong_mariadb ==="
docker exec -e MYSQL_PWD='hongkong_wp_db_paSS_2026' hongkong_mariadb mariadb-dump -u hongkong_wp_sql_user hongkong_wp_db --single-transaction 2>/dev/null > /tmp/hk_maria.sql
echo "done_hk_maria: $(du -sh /tmp/hk_maria.sql | cut -f1)"

echo "=== Export hongkong_postgres ==="
docker exec hongkong_postgres pg_dumpall -U crm_hongkong 2>/dev/null > /tmp/hk_pg.sql
echo "done_hk_pg: $(du -sh /tmp/hk_pg.sql | cut -f1)"

echo "ALL_DONE"
