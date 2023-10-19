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
        apt install -y wget make gcc
        ;;
    centos|redhat|fedora)
        yum update -y
        yum install -y wget make gcc
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

# 安装并配置vnStat
if [[ "$CLIENT_VNSTAT" == "yes" ]]; then
    # 下载，编译和安装vnStat
    wget -O vnstat.tar.gz https://humdi.net/vnstat/vnstat-latest.tar.gz
    tar -zxvf vnstat.tar.gz
    cd vnstat-* || exit 1
    
    if [ -f "Makefile" ]; then
        make && sudo make install
    else
        echo "Makefile not found. Exiting."
        exit 1
    fi

    cd .. || exit 1

    # 检查vnstat命令是否可用
    if ! command -v vnstat &> /dev/null; then
        echo "vnStat could not be installed correctly"
        exit 1
    fi

    # 初始化 vnStat 和启动服务
    vnstat --create -i eth0
    systemctl enable vnstat
    systemctl start vnstat
    
    # 设置cron job每30天重置vnStat数据
    (crontab -l 2>/dev/null; echo "0 0 */30 * * vnstat --delete --force") | crontab -
fi

# 创建Systemd服务单元文件
PYTHON_COMMAND=$(command -v python3 || command -v python)
cat <<EOL > /etc/systemd/system/status-client.service
[Unit]
Description=Server Status Client
After=network.target

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
ExecStart=$PYTHON_COMMAND /usr/local/status-client.py run

[Install]
WantedBy=multi-user.target
EOL

# 重新加载Systemd守护进程，启动服务并使其在开机时自启
systemctl daemon-reload
systemctl start status-client
systemctl enable status-client

echo "Client setup completed!"
