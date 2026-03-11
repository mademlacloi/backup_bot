#!/bin/bash
# failback_to_vps2.sh (V2)
# Hỗ trợ tham số: all, hongkong, vungvang, thoigianranh

TARGET=$1
REMOTE_IP="14.236.0.6"
REMOTE_PORT="2332"

function recover_hongkong() {
    echo "--- Phục hồi Hongkong Luxury ---"
    rsync -avz -e "ssh -p $REMOTE_PORT" --delete "/opt/hongkong-server/" "root@$REMOTE_IP:/opt/hongkong-server/"
    docker exec hongkong_db_crm pg_dump -U crm_user crm_hongkong > /tmp/crm_dump.sql
    scp -P $REMOTE_PORT /tmp/crm_dump.sql root@$REMOTE_IP:/tmp/
    ssh -p $REMOTE_PORT root@$REMOTE_IP "docker exec -i hongkong_db_crm psql -U crm_user crm_hongkong < /tmp/crm_dump.sql"
}

function recover_vungvang() {
    echo "--- Phục hồi Vừng Vàng ---"
    rsync -avz -e "ssh -p $REMOTE_PORT" --delete "/opt/vungvang-server/" "root@$REMOTE_IP:/opt/vungvang-server/"
    docker exec vungvang_mariadb mysqldump -u root -p'vungvang123' vungvang_db > /tmp/vungvang_dump.sql
    scp -P $REMOTE_PORT /tmp/vungvang_dump.sql root@$REMOTE_IP:/tmp/
    ssh -p $REMOTE_PORT root@$REMOTE_IP "docker exec -i vungvang_mariadb mariadb -u root -p'vungvang123' vungvang_db < /tmp/vungvang_dump.sql"
}

function recover_thoigianranh() {
    echo "--- Phục hồi Thời Gian Rảnh ---"
    rsync -avz -e "ssh -p $REMOTE_PORT" --delete "/opt/thoigianranh-server/" "root@$REMOTE_IP:/opt/thoigianranh-server/"
    # Dump cả 2 database của TGR
    docker exec thoigianranh_db_main mysqldump -u root -p'vungvang123' thoigianranh_db > /tmp/tgr_main.sql
    docker exec thoigianranh_db_api mysqldump -u root -p'vungvang123' tgr_api_db > /tmp/tgr_api.sql
    scp -P $REMOTE_PORT /tmp/tgr_main.sql /tmp/tgr_api.sql root@$REMOTE_IP:/tmp/
    ssh -p $REMOTE_PORT root@$REMOTE_IP "docker exec -i thoigianranh_db_main mariadb -u root -p'vungvang123' thoigianranh_db < /tmp/tgr_main.sql; docker exec -i thoigianranh_db_api mariadb -u root -p'vungvang123' tgr_api_db < /tmp/tgr_api.sql"
}

case $TARGET in
    hongkong) recover_hongkong ;;
    vungvang) recover_vungvang ;;
    thoigianranh) recover_thoigianranh ;;
    all)
        recover_hongkong
        recover_vungvang
        recover_thoigianranh
        ;;
    *)
        echo "Vui lòng chọn: all, hongkong, vungvang, thoigianranh"
        ;;
esac
