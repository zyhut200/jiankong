#!/bin/bash

# 获取本机IP地址
CLIENT_IP=$(curl -s https://api.ipify.org)

# 定义服务器和客户端设置
SERVER="45.148.134.106"
SERVER_PORT=51000
CLIENT_USER="$CLIENT_IP"
CLIENT_PASSWORD="123456"
CLIENT_VNSTAT="yes" # 是否启用vnStat

# 检测操作系统并安装必要的软件包
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
elif [ -f /etc/debian_version ]; then
    OS=Debian
elif [ -f /etc/redhat-release ]; then
    OS=$(cat /etc/redhat-release | cut -f1 -d" ")
else
    OS=$(uname -s)
fi

# 安装依赖和客户端
case $OS in
    Ubuntu*|Debian*)
        apt-get update
        apt-get install -y python3 python3-pip vnstat wget
        ;;
    CentOS*|Fedora*|Red*)
        yum update -y
        yum install -y python3 python3-pip vnstat wget
        ;;
    *)
        echo "Unsupported operating system $OS"
        exit 1
        ;;
esac

# 下载并修改客户端配置文件
wget -O /usr/local/status-client.py https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/clients/status-client.py
wget -O /usr/local/status-client.conf https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/clients/status-client.conf

# 修改客户端配置文件
sed -i "s/SERVER = .*/SERVER = \"$SERVER\"/g" /usr/local/status-client.py
sed -i "s/PORT = .*/PORT = $SERVER_PORT/g" /usr/local/status-client.py
sed -i "s/USER = .*/USER = \"$CLIENT_USER\"/g" /usr/local/status-client.py
sed -i "s/PASSWORD = .*/PASSWORD = \"$CLIENT_PASSWORD\"/g" /usr/local/status-client.py

# 如果启用了vnStat，配置vnStat
if [ "$CLIENT_VNSTAT" = "yes" ]; then
    vnstat --create -i eth0
    systemctl enable vnstat
    systemctl start vnstat
fi

# 添加到开机启动
echo "@reboot root /usr/bin/python3 /usr/local/status-client.py /usr/local/status-client.conf run" >> /etc/crontab

# 运行客户端
python3 /usr/local/status-client.py /usr/local/status-client.conf run
