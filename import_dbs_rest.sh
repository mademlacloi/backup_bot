#!/bin/bash
set -e
sleep 10
echo "=== Import vungvang_mariadb ==="
cat /tmp/vv.sql | docker exec -i vungvang_mariadb mariadb -u root -p'vungvang_root_2026_pass'
echo "Done vv"

echo "=== Import hongkong_mariadb ==="
cat /tmp/hk_maria.sql | docker exec -i hongkong_mariadb mariadb -u hongkong_wp_sql_user -p'hongkong_wp_db_paSS_2026' hongkong_wp_db
echo "Done hk_maria"

echo "=== Import hongkong_postgres ==="
cat /tmp/hk_pg.sql | docker exec -i hongkong_postgres psql -U crm_hongkong postgres
echo "Done hk_pg"

echo "ALL IMPORT REST DONE"
