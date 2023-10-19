#!/bin/bash

# 自动获取本机公网IP
CLIENT_IP=$(curl -s https://api.ipify.org)

# 客户端设置
CLIENT_USER="$CLIENT_IP"                   # 用户名
CLIENT_PASSWORD="123456"                   # 密码
CLIENT_SERVER="45.148.134.106"             # 服务端IP地址
CLIENT_SERVER_PORT="51000"                 # 服务端监听的IP端口
CLIENT_VNSTAT="yes"                        # 是否启用vnStat

# 安装依赖
apt-get update
apt-get install -y python python-pip
pip install psutil

# 下载客户端脚本
cd /usr/local
wget https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/clients/status-client.py
chmod 755 status-client.py

# 创建客户端配置文件
cat > /usr/local/status-client.conf << EOF
# Config
SERVER = "$CLIENT_SERVER"
PORT = $CLIENT_SERVER_PORT
USER = "$CLIENT_USER"
PASSWORD = "$CLIENT_PASSWORD"
INTERVAL = 1
EOF

# 如果启用vnStat, 需要进行安装
if [ "$CLIENT_VNSTAT" = "yes" ]; then
    apt-get install -y vnstat
fi

# 创建系统服务
cat > /etc/systemd/system/status-client.service << EOF
[Unit]
Description=Server Status client

[Service]
WorkingDirectory=/usr/local
ExecStart=/usr/bin/python /usr/local/status-client.py /usr/local/status-client.conf run
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# 启动系统服务
systemctl enable status-client
systemctl start status-client
