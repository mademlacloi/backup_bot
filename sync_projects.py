import os
import json
import subprocess
import re

PROJECTS_JSON = "/opt/projects.json"

def get_env_vars(env_path):
    vars = {}
    if not os.path.exists(env_path): return vars
    with open(env_path, 'r') as f:
        for line in f:
            if '=' in line and not line.startswith('#'):
                k, v = line.strip().split('=', 1)
                vars[k] = v
    return vars

def scan_projects():
    projects = {}
    # Load existing to preserve any manual edits if needed, or start fresh
    if os.path.exists(PROJECTS_JSON):
        with open(PROJECTS_JSON, 'r') as f:
            projects = json.load(f)
            
    # Scan /opt/ for project directories
    for folder in os.listdir('/opt'):
        path = os.path.join('/opt', folder)
        if not os.path.isdir(path): continue
        
        compose_path = os.path.join(path, 'docker-compose.yml')
        env_path = os.path.join(path, '.env')
        
        if os.path.exists(compose_path):
            env = get_env_vars(env_path)
            with open(compose_path, 'r') as f:
                content = f.read()
                
            # Logic tìm kiếm domain và container
            # Đây là logic heuristic dựa trên cấu trúc hiện tại của bạn
            # Tìm danh sách domain từ các tệp config nginx trong cùng thư mục dự án
            nginx_conf_dir = os.path.join(path, 'nginx/conf')
            domains_found = []
            if os.path.exists(nginx_conf_dir):
                for conf in os.listdir(nginx_conf_dir):
                    with open(os.path.join(nginx_conf_dir, conf), 'r') as nf:
                        for line in nf:
                            if 'server_name' in line:
                                d = line.replace('server_name', '').replace(';', '').strip().split()
                                domains_found.extend(d)
            
            # Làm sạch danh sách domain
            domains_found = [d for d in domains_found if '.' in d and d != 'localhost']
            
            # Tìm WP và DB container
            # Dùng docker ps để lấy tên chính xác của các container đang chạy
            ps_output = subprocess.getoutput("sudo docker ps --format '{{.Names}}'").splitlines()
            
            for dom in domains_found:
                # Tìm container liên quan
                prefix = dom.replace('.com', '').split('.')[0] # domain1, domain2
                wp_cont = ""
                db_cont = ""
                db_pass = ""
                
                # Ưu tiên các container có tên chứa domain prefix
                matching_conts = [c for c in ps_output if prefix in c]
                
                for c in matching_conts:
                    if 'wp' in c or 'wordpress' in c: wp_cont = c
                    if 'db' in c or 'mariadb' in c or 'mysql' in c: db_cont = c
                
                if not wp_cont or not db_cont: continue
                
                # Tìm mật khẩu root DB từ .env
                # Cố gắng tìm biến môi trường chứa root password
                for k, v in env.items():
                    if 'ROOT_PASSWORD' in k:
                        db_pass = v
                        break
                
                if not db_pass: db_pass = env.get('MYSQL_ROOT_PASSWORD', '')

                projects[dom] = {
                    "wp_container": wp_cont,
                    "db_container": db_cont,
                    "db_name": env.get('MYSQL_DATABASE', ''), # Heuristic
                    "db_pass": db_pass
                }
                
                # Ghi nhận db_name từ .env nếu có, nếu không để trống
                projects[dom]["db_name"] = env.get('MYSQL_DATABASE', env.get('DB_NAME', ''))

                # Gợi ý: Nếu một domain có nhiều database hoặc cấu hình đặc thù, 
                # hãy chỉnh sửa trực tiếp trong file /opt/projects.json trên VPS.
                    
    with open(PROJECTS_JSON, 'w', encoding='utf-8') as f:
        json.dump(projects, f, indent=4, ensure_ascii=False)
    print(f"✅ Đã quét và cập nhật {len(projects)} dự án vào projects.json")

if __name__ == "__main__":
    scan_projects()
