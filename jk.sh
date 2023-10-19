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
if [ -f /etc/os-release ]; then
    . /etc/os-release
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
elif [ -f /etc/redhat-release ]; then
    OS="Red Hat"
else
    OS=$(uname -s)
fi

case $OS in
    Ubuntu*|Debian*)
        apt-get update
        apt-get install -y python python-pip wget vnstat
        ;;
    CentOS*|Fedora*|Red*)
        yum update -y
        yum install -y python python-pip wget vnstat
        ;;
    *)
        echo "Unsupported operating system $OS"
        exit 1
        ;;
esac

# 下载客户端脚本并配置
wget -O /usr/local/status-client.py https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/clients/status-client.py
sed -i "s/SERVER = .*/SERVER = \"$CLIENT_SERVER\"/g" /usr/local/status-client.py
sed -i "s/PORT = .*/PORT = $CLIENT_SERVER_PORT/g" /usr/local/status-client.py
sed -i "s/USER = .*/USER = \"$CLIENT_USER\"/g" /usr/local/status-client.py
sed -i "s/PASSWORD = .*/PASSWORD = \"$CLIENT_PASSWORD\"/g" /usr/local/status-client.py

# 如果启用vnStat，检查版本并相应配置
if [ "$CLIENT_VNSTAT" = "yes" ]; then
    VNSTAT_VERSION=$(vnstat --version | head -1 | awk '{print $2}')
    if [[ $(echo -e "2.0\n$VNSTAT_VERSION" | sort -V | head -n1) = "2.0" ]]; then
        if ! grep -q "Database created" <<< $(vnstat --create -i eth0); then
            echo "Error creating vnStat database"
            exit 1
        fi
        systemctl restart vnstat
    fi

    systemctl enable vnstat
    systemctl start vnstat
fi

# 设置客户端脚本为开机启动
echo "@reboot root /usr/bin/python /usr/local/status-client.py run" >> /etc/crontab

# 运行客户端脚本
nohup python /usr/local/status-client.py run &

echo "Client setup complete!"
