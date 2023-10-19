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

# 下载客户端文件
wget -O /usr/local/status-client.py https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/clients/status-client.py

# 配置客户端信息
sed -i "s/^SERVER =.*/SERVER = \"$CLIENT_SERVER\"/" /usr/local/status-client.py
sed -i "s/^PORT =.*/PORT = $CLIENT_SERVER_PORT/" /usr/local/status-client.py
sed -i "s/^USER =.*/USER = \"$CLIENT_USER\"/" /usr/local/status-client.py
sed -i "s/^PASSWORD =.*/PASSWORD = \"$CLIENT_PASSWORD\"/" /usr/local/status-client.py

# 如果启用了vnStat，配置vnStat
if [[ "$CLIENT_VNSTAT" == "yes" ]]; then
    if ! command -v vnstat &> /dev/null; then
        echo "vnStat could not be found!"
        exit
    fi

    VNSTAT_VERSION=$(vnstat --version | head -n 1 | awk '{print $2}')
    echo "Detected vnStat version: $VNSTAT_VERSION"

    case "$VNSTAT_VERSION" in 
        1.*)
            # 检查并启动vnStat服务 (for version 1.x)
            service vnstat start
            ;;
        2.*)
            # 检查并启动vnStat服务 (for version 2.x)
            systemctl enable vnstat
            systemctl start vnstat
            ;;
        *)
            echo "Unsupported vnStat version"
            exit 1
            ;;
    esac

    # 设置cron job在每月1号重置流量
    # Note: For vnStat 1.x, you may need to handle the database reset manually or upgrade to 2.x
    (crontab -l 2>/dev/null; echo "0 0 1 * * vnstat --delete --force") | crontab -
fi

# 创建Systemd服务单元文件
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

# 重新加载Systemd守护进程，启动服务并使其在开机时自启
systemctl daemon-reload
systemctl start status-client
systemctl enable status-client

echo "Client setup completed!"
