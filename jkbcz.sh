#!/bin/bash

# 获取客户端服务器的公网IP
CLIENT_IP=$(curl -s https://api.ipify.org)
echo "Client IP: $CLIENT_IP"

# 客户端配置信息
CLIENT_USER="$CLIENT_IP"           # 用户名
CLIENT_PASSWORD="123456"           # 密码
CLIENT_SERVER="45.148.134.106"     # 服务端IP地址
CLIENT_SERVER_PORT="51000"         # 服务端监听的端口
CLIENT_VNSTAT="yes"                # 是否启用vnStat

# 检查操作系统并安装必要软件
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
elif [[ -f /etc/redhat-release ]]; then
    OS="redhat"
else
    OS=$(uname -s)
fi

echo "Detected operating system: $OS"

case $OS in
    ubuntu|debian)
        apt update
        apt install -y python python-pip wget vnstat
        ;;
    centos|redhat|fedora)
        yum update -y
        yum install -y python python-pip wget vnstat
        ;;
    *)
        echo "Unsupported operating system $OS"
        exit 1
        ;;
esac

# 安装并配置vnStat
if [[ "$CLIENT_VNSTAT" == "yes" ]]; then
    # vnStat 安装
    case $OS in
        ubuntu|debian)
            apt install -y vnstat
            ;;
        centos|redhat|fedora)
            yum install -y vnstat
            ;;
    esac
    
    # 初始化 vnStat
    vnstat -u -i eth0

    # 启动 vnStat 服务
    case $OS in
        ubuntu|debian|centos|redhat)
            systemctl enable vnstat
            systemctl start vnstat
            ;;
    esac
fi

# 下载客户端文件
wget -O /usr/local/status-client.py https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/clients/status-client.py

# 添加 vnStat 支持的代码到 status-client.py 文件
echo "
import os
import json

def get_vnstat_data():
    try:
        vnstat_output = os.popen('vnstat --json').read()
        vnstat_data = json.loads(vnstat_output)
        return vnstat_data
    except Exception as e:
        print('Error getting vnStat data:', e)
        return None
" >> /usr/local/status-client.py

# 修改 status-client.py 文件，添加从 vnStat 获取流量数据的代码
sed -i "/        load = 'load average:/i \
        vnstat_data = get_vnstat_data()\n\
        if vnstat_data:\n\
            rx = vnstat_data['interfaces'][0]['traffic']['total']['rx']\n\
            tx = vnstat_data['interfaces'][0]['traffic']['total']['tx']\n\
        else:\n\
            rx = 0\n\
            tx = 0\n" /usr/local/status-client.py

# 修改 status-client.py 文件中的 username, password, server 和 port
sed -i "s/^SERVER =.*/SERVER = \"$CLIENT_SERVER\"/" /usr/local/status-client.py
sed -i "s/^PORT =.*/PORT = $CLIENT_SERVER_PORT/" /usr/local/status-client.py
sed -i "s/^USER =.*/USER = \"$CLIENT_USER\"/" /usr/local/status-client.py
sed -i "s/^PASSWORD =.*/PASSWORD = \"$CLIENT_PASSWORD\"/" /usr/local/status-client.py

# 设置 Systemd 服务单元文件
cat <<EOL > /etc/systemd/system/status-client.service
[Unit]
Description=Server Status Client
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=/usr/bin/python /usr/local/status-client.py run

[Install]
WantedBy=multi-user.target
EOL

# 启动并设置开机自启
systemctl daemon-reload
systemctl start status-client
systemctl enable status-client

echo "Client setup completed!"
