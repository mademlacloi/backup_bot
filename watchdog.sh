#!/bin/bash
# Watchdog Self-healing Script
# Kiểm tra Health Check và tự động Bật/Tắt Cloudflare Tunnel

# Danh sách các dự án cần kiểm tra
PROJECTS=("vungvang" "thoigianranh")
TUNNELS=("cloudflared-vungvang" "cloudflared-thoigianranh")

HEALTHY=true

echo "--- Health Check: $(date) ---"

# 1. Kiểm tra Docker Service tổng quát
if ! systemctl is-active --quiet docker; then
    echo "[FAIL] Docker service is down!"
    HEALTHY=false
fi

# 2. Kiểm tra các Container quan trọng (Database & WP)
# Chỉ cần 1 container quan trọng sập là coi như máy này "ốm"
CRITICAL_CONTAINERS=("vungvang_mariadb" "vungvang_wordpress" "thoigianranh_db_main" "thoigianranh_wp_main")

for container in "${CRITICAL_CONTAINERS[@]}"; do
    if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
        echo "[FAIL] Container $container is not running!"
        HEALTHY=false
        break
    fi
done

# 3. Kiểm tra phản hồi HTTP nội bộ (Cổng 80 - Nginx)
if [ "$HEALTHY" = true ]; then
    if ! curl -s --head  --request GET http://localhost | grep "200 OK" > /dev/null; then
        echo "[FAIL] Localhost HTTP check failed!"
        HEALTHY=false
    fi
fi

# 4. Điều khiển Cloudflare Tunnels
if [ "$HEALTHY" = true ]; then
    echo "[PASS] All systems healthy. Ensuring Tunnels are UP."
    for tunnel in "${TUNNELS[@]}"; do
        if ! systemctl is-active --quiet "$tunnel"; then
            echo "Starting $tunnel..."
            systemctl start "$tunnel"
        fi
    done
else
    echo "[WARN] System Unhealthy! Shutting down Tunnels to trigger Failover."
    for tunnel in "${TUNNELS[@]}"; do
        if systemctl is-active --quiet "$tunnel"; then
            echo "Stopping $tunnel..."
            systemctl stop "$tunnel"
        fi
    done
fi
