#!/bin/bash
# Watchdog Admin-Aware Smart Proactive Script

# Bổ sung thông tin định danh máy chủ
SERVER_NAME="Máy Pi Dự Phòng"

# Cấu hình ngưỡng quá tải
MAX_LOAD=4.0      # Ngưỡng CPU Load bình thường
MIN_FREE_RAM=100  # Ngưỡng RAM trống tối thiểu (MB)

# Các tiến trình bảo trì thường dùng
MAINTENANCE_PROC=("rsync" "mariadb-dump" "pg_dump" "tar" "zip" "unzip")

check_system_overload() {
    # 1. Kiểm tra xem có đang bảo trì không
    IS_MAINTENANCE=false
    for proc in "${MAINTENANCE_PROC[@]}"; do
        if pgrep -x "$proc" > /dev/null; then
            echo "[INFO] Admin Task Detected: $proc is running. Relaxing rules..."
            IS_MAINTENANCE=true
            break
        fi
    done

    # 2. Lấy thông số hệ thống
    LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d',' -f1 | xargs)
    FREE_RAM=$(free -m | grep "Mem:" | awk '{print $7}')
    
    echo "[INFO] Current Load: $LOAD, Free RAM: ${FREE_RAM}MB"
    
    # 3. Logic quyết định
    if [ "$IS_MAINTENANCE" = true ]; then
        # Nếu đang bảo trì, chỉ cảnh báo, không ép Failover trừ khi RAM cạn kiệt (< 50MB)
        if [ "$FREE_RAM" -lt 50 ]; then
            echo "[WARN] CRITICAL! RAM nearly exhausted even during maintenance!"
            return 1
        fi
        return 0 # Vẫn coi là Healthy để Admin làm việc tiếp
    else
        # Chế độ giám sát khách hàng bình thường
        if (( $(echo "$LOAD > $MAX_LOAD" | bc -l) )); then
            echo "[WARN] System Overloaded by Traffic! CPU Load ($LOAD) > $MAX_LOAD"
            return 1
        fi
        if [ "$FREE_RAM" -lt "$MIN_FREE_RAM" ]; then
            echo "[WARN] System Low Memory! Free RAM (${FREE_RAM}MB) < $MIN_FREE_RAM"
            return 1
        fi
    fi
    return 0
}

check_and_manage_project() {
    local project_name=$1
    local tunnel_service=$2
    local containers=($3)
    local port=$4
    local system_overloaded=$5
    
    local project_healthy=true
    
    # 1. Kiểm tra Containers
    for container in "${containers[@]}"; do
        if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            echo "[FAIL] [$project_name] Container $container is not running!"
            project_healthy=false
            break
        fi
    done
    
    # 2. Kiểm tra HTTP (Dù CPU cao nhưng nếu HTTP vẫn nhanh thì vẫn giữ Tunnel)
    if [ "$project_healthy" = true ]; then
        # Nếu hệ thống báo quá tải, giảm timeout xuống 5s để đẩy tải thật nhanh bảo vệ khách
        # Telegram Config
        TOKEN="8726045761:AAF2LpKjga6Oyw8mervBEa0_dBCtUCo6_xA"
        CHAT_ID="1257141148" 
        local timeout=15
        if [ "$system_overloaded" = true ]; then timeout=5; fi
        
        if ! curl -s --max-time $timeout --head --request GET "http://localhost:$port" > /dev/null; then
            echo "[FAIL] [$project_name] HTTP Port $port failed or too slow ($timeout s)!"
            project_healthy=false
        fi
    fi
    
    # 3. Điều khiển Tunnel
    if [ "$project_healthy" = true ]; then
        if ! systemctl is-active --quiet "$tunnel_service"; then
            echo "[PASS] [$project_name] System OK. Starting $tunnel_service..."
            python3 /opt/alert_bot.py "$project_name" "RECOVER" "$SERVER_NAME" &
            systemctl start "$tunnel_service"
        fi
    else
        if systemctl is-active --quiet "$tunnel_service"; then
            echo "[WARN] [$project_name] Triggering Failover! Stopping $tunnel_service..."
            python3 /opt/alert_bot.py "$project_name" "FAIL" "$SERVER_NAME" &
            systemctl stop "$tunnel_service"
        fi
    fi
}

echo "--- Admin-Aware Health Check: $(date) ---"

OVERLOADED=false
if ! check_system_overload; then
    OVERLOADED=true
fi

# Dự án 1: Vừng Vàng (Port 82)
check_and_manage_project "VungVang" "cloudflared-vungvang" "vungvang_mariadb vungvang_wordpress" "82" "$OVERLOADED"

# Dự án 2: Thời Gian Rảnh (Port 81)
check_and_manage_project "ThoiGianRanh" "cloudflared-thoigianranh" "thoigianranh_db_main thoigianranh_wp_main" "81" "$OVERLOADED"



echo "Check Completed."
