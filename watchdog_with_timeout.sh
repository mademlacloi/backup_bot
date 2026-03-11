#!/bin/bash
# Watchdog Self-healing Script (Kịch bản Lỗi Cục bộ - Isolated Mode)
# Kiểm tra Health Check và tự động Bật/Tắt Cloudflare Tunnel theo từng dự án

# Hàm kiểm tra và xử lý cho từng dự án
check_and_manage_project() {
    local project_name=$1
    local tunnel_service=$2
    local containers=($3) # Danh sách container quan trọng của project
    local port=$4
    
    local project_healthy=true
    
    # 1. Kiểm tra các Container
    for container in "${containers[@]}"; do
        if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
            echo "[FAIL] [$project_name] Container $container is not running!"
            project_healthy=false
            break
        fi
    done
    
    # 2. Kiểm tra HTTP nội bộ qua Port cụ thể (nếu container đang chạy)
    # Thêm --max-time 15 để Failover nếu web bị treo quá 15 giây
    if [ "$project_healthy" = true ]; then
        if ! curl -s --max-time 15 --head --request GET "http://localhost:$port" > /dev/null; then
            echo "[FAIL] [$project_name] HTTP Port $port check failed or timed out (15s)!"
            project_healthy=false
        fi
    fi
    
    # 3. Điều khiển Tunnel của dự án này
    if [ "$project_healthy" = true ]; then
        if ! systemctl is-active --quiet "$tunnel_service"; then
            echo "[PASS] [$project_name] Recovered. Starting $tunnel_service..."
            systemctl start "$tunnel_service"
        fi
    else
        if systemctl is-active --quiet "$tunnel_service"; then
            echo "[WARN] [$project_name] Unhealthy or Slow! Stopping $tunnel_service..."
            systemctl stop "$tunnel_service"
        fi
    fi
}

echo "--- Health Check: $(date) ---"

# Dự án 1: Vừng Vàng (Port 82)
check_and_manage_project "VungVang" "cloudflared-vungvang" "vungvang_mariadb vungvang_wordpress" "82"

# Dự án 2: Thời Gian Rảnh (Port 81)
check_and_manage_project "ThoiGianRanh" "cloudflared-thoigianranh" "thoigianranh_db_main thoigianranh_wp_main" "81"

# Dự án 3: Hongkong Luxury (Port 80)
check_and_manage_project "Hongkong" "cloudflared" "hongkong_mariadb hongkong_wordpress" "80"

echo "Check Completed."
