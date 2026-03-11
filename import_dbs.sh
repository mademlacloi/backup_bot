#!/bin/bash
set -e

echo "=== Import thoigianranh_db_main ==="
cat /tmp/th_main.sql | docker exec -i thoigianranh_db_main mariadb -u root -p'thoigianranh_R00t_M4in_2026!'
echo "Done th_main"

echo "=== Import thoigianranh_db_api ==="
cat /tmp/th_api.sql | docker exec -i thoigianranh_db_api mariadb -u root -p'thoigianranh_R00t_Ap1_2026!'
echo "Done th_api"

echo "=== Import vungvang_mariadb ==="
cat /tmp/vv.sql | docker exec -i vungvang_mariadb mariadb -u root -p'vungvang_root_2026_pass'
echo "Done vv"

echo "=== Import hongkong_mariadb ==="
cat /tmp/hk_maria.sql | docker exec -i hongkong_mariadb mariadb -u hongkong_wp_sql_user -p'hongkong_wp_db_paSS_2026' hongkong_wp_db
echo "Done hk_maria"

echo "=== Import hongkong_postgres ==="
cat /tmp/hk_pg.sql | docker exec -i hongkong_postgres psql -U crm_hongkong postgres
echo "Done hk_pg"

echo "ALL IMPORT DONE"
