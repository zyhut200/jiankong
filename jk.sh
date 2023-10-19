#!/bin/bash

# 获取服务器的公网IP地址
CLIENT_IP=$(curl -s https://api.ipify.org)

# 如果获取IP地址失败，就尝试用另一个API再获取一次
if [ -z "$CLIENT_IP" ]; then
    CLIENT_IP=$(curl -s https://ipinfo.io/ip)
fi

# 如果再次失败，就输出错误信息并退出脚本
if [ -z "$CLIENT_IP" ]; then
    echo "Error: Unable to get the public IP address of this server."
    exit 1
fi

# 将获取的IP地址赋值给 CLIENT_USER 变量
CLIENT_USER="$CLIENT_IP"

# 其他用户配置信息
CLIENT_SERVER="45.148.134.106"
CLIENT_PORT="51000"
CLIENT_PASSWORD="123456"

# 安装依赖
apt-get update
apt-get install -y python3 wget vnstat

# 下载客户端脚本
wget -N --no-check-certificate https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/clients/status-client.py -O /usr/local/status-client.py

# 如果文件下载失败，则输出错误信息并退出脚本
if [ ! -e '/usr/local/status-client.py' ]; then
    echo "Error: Failed to download client script."
    exit 1
fi

# 替换客户端脚本中的配置信息
sed -i "s/SERVER = .*/SERVER = \"$CLIENT_SERVER\"/" /usr/local/status-client.py
sed -i "s/PORT = .*/PORT = $CLIENT_PORT/" /usr/local/status-client.py
sed -i "s/USER = .*/USER = \"$CLIENT_USER\"/" /usr/local/status-client.py
sed -i "s/PASSWORD = .*/PASSWORD = \"$CLIENT_PASSWORD\"/" /usr/local/status-client.py

# 创建系统服务
cat > /etc/systemd/system/status-client.service << EOF
[Unit]
Description=ServerStatus client
After=network.target

[Service]
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/bin/python3 /usr/local/status-client.py

[Install]
WantedBy=multi-user.target
EOF

# 重载系统服务、启动客户端服务、设置开机启动
systemctl daemon-reload
systemctl start status-client
systemctl enable status-client

# 输出客户端信息
echo "————————————————————"
echo "  ServerStatus 客户端配置信息："
echo "  IP       : ${CLIENT_IP}"
echo "  端口     : ${CLIENT_PORT}"
echo "  用户名   : ${CLIENT_USER}"
echo "  密码     : ${CLIENT_PASSWORD}"
echo "————————————————————"

# 完成
echo "ServerStatus 客户端安装完成！"
