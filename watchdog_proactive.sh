#!/bin/bash
# Watchdog Smart Proactive Script
# Kiểm tra Health Check + Timeout 15s + CPU Load Monitoring

# Cấu hình ngưỡng quá tải
MAX_LOAD=4.0      # Ngưỡng CPU Load (Cho Pi 4 nhân)
MIN_FREE_RAM=100  # Ngưỡng RAM trống tối thiểu (MB)

check_system_overload() {
    # Lấy Load Average 1 phút
    LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d',' -f1 | xargs)
    # Lấy RAM trống (Available) tính bằng MB
    FREE_RAM=$(free -m | grep "Mem:" | awk '{print $7}')
    
    echo "[INFO] Current Load: $LOAD, Free RAM: ${FREE_RAM}MB"
    
    # So sánh Load (dùng bc để so sánh số thập phân)
    if (( $(echo "$LOAD > $MAX_LOAD" | bc -l) )); then
        echo "[WARN] System Overloaded! CPU Load ($LOAD) > $MAX_LOAD"
        return 1
    fi
    
    if [ "$FREE_RAM" -lt "$MIN_FREE_RAM" ]; then
        echo "[WARN] System Low Memory! Free RAM (${FREE_RAM}MB) < $MIN_FREE_RAM"
        return 1
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
    
    # Nếu hệ thống quá tải -> Coi như project không khỏe để đẩy tải đi
    if [ "$system_overloaded" = true ]; then
        project_healthy=false
    else
        # 1. Kiểm tra Containers
        for container in "${containers[@]}"; do
            if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
                echo "[FAIL] [$project_name] Container $container is not running!"
                project_healthy=false
                break
            fi
        done
        
        # 2. Kiểm tra HTTP Timeout 15s
        if [ "$project_healthy" = true ]; then
            if ! curl -s --max-time 15 --head --request GET "http://localhost:$port" > /dev/null; then
                echo "[FAIL] [$project_name] HTTP Port $port failed or too slow (15s)!"
                project_healthy=false
            fi
        fi
    fi
    
    # 3. Điều khiển Tunnel
    if [ "$project_healthy" = true ]; then
        if ! systemctl is-active --quiet "$tunnel_service"; then
            echo "[PASS] [$project_name] System Healthy. Starting $tunnel_service..."
            systemctl start "$tunnel_service"
        fi
    else
        if systemctl is-active --quiet "$tunnel_service"; then
            echo "[WARN] [$project_name] Triggering Failover! Stopping $tunnel_service..."
            systemctl stop "$tunnel_service"
        fi
    fi
}

echo "--- Smart Health Check: $(date) ---"

OVERLOADED=false
if ! check_system_overload; then
    OVERLOADED=true
fi

# Dự án 1: Vừng Vàng (Port 82)
check_and_manage_project "VungVang" "cloudflared-vungvang" "vungvang_mariadb vungvang_wordpress" "82" "$OVERLOADED"

# Dự án 2: Thời Gian Rảnh (Port 81)
check_and_manage_project "ThoiGianRanh" "cloudflared-thoigianranh" "thoigianranh_db_main thoigianranh_wp_main" "81" "$OVERLOADED"

# Dự án 3: Hongkong Luxury (Port 80)
check_and_manage_project "Hongkong" "cloudflared" "hongkong_mariadb hongkong_wordpress" "80" "$OVERLOADED"

echo "Check Completed."
