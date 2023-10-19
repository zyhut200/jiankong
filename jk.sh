#!/bin/bash

# 获取客户端服务器的公网IP
CLIENT_IP=$(curl -s https://api.ipify.org)
echo "Client IP: $CLIENT_IP"

# 客户端配置信息
CLIENT_USER="$CLIENT_IP"           # 用户名
CLIENT_PASSWORD="123456"           # 密码
CLIENT_SERVER="45.148.134.106"     # 服务端IP地址
CLIENT_SERVER_PORT="51000"         # 服务端监听的IP端口
CLIENT_VNSTAT="yes"                # 是否启用vnStat

# 检查操作系统
if [[ -e /etc/debian_version ]]; then
    OS='debian'
    INSTALLER='apt'
elif [[ -e /etc/redhat-release ]]; then
    OS='redhat'
    INSTALLER='yum'
else
    echo "Unsupported operating system."
    exit 1
fi

# 更新系统并安装必要的软件包
$INSTALLER update -y
$INSTALLER install -y python python-pip wget

# 检查vnStat是否安装
if ! command -v vnstat &> /dev/null
then
    echo "vnStat could not be found!"
    # Debian/Ubuntu安装vnStat
    if [[ $OS == 'debian' ]]; then
        $INSTALLER install -y vnstat
    # CentOS安装vnStat
    elif [[ $OS == 'redhat' ]]; then
        $INSTALLER install epel-release -y
        $INSTALLER install vnstat -y
    fi
fi

# 下载客户端文件
wget -O /usr/local/status-client.py https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/clients/status-client.py

# 配置客户端信息
sed -i "s/^SERVER =.*/SERVER = \"$CLIENT_SERVER\"/" /usr/local/status-client.py
sed -i "s/^PORT =.*/PORT = $CLIENT_SERVER_PORT/" /usr/local/status-client.py
sed -i "s/^USER =.*/USER = \"$CLIENT_USER\"/" /usr/local/status-client.py
sed -i "s/^PASSWORD =.*/PASSWORD = \"$CLIENT_PASSWORD\"/" /usr/local/status-client.py

# 如果启用了vnStat，配置vnStat
if [ "$CLIENT_VNSTAT" = "yes" ]; then
    INTERFACE=$(vnstat --iflist | grep -E -v "lo" | head -n 1)
    vnstat --create -i "$INTERFACE"
    systemctl enable vnstat
    systemctl start vnstat
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

echo "ServerStatus client installation completed!"
