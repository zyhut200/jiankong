#!/bin/bash
# Auto install the ServerStatus client
# Only for CentOS/Debian/Ubuntu

CLIENT_SERVER="45.148.134.106"
CLIENT_PORT="51000"
CLIENT_USER=$(curl -s icanhazip.com) # 自动获取服务器IP
CLIENT_PASSWORD="123456" # 密码
CLIENT_VNSTAT="yes" # 是否启用vnStat

# Check if user is root
[ $(id -u) != "0" ] && { echo "Error: You must be root to run this script"; exit 1; }

# Check OS type
if [ -e /etc/redhat-release ]; then
    OS='CentOS'
elif cat /etc/issue | grep -q -E -i "debian"; then
    OS='Debian'
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
    OS='Ubuntu'
else
    echo "Not support OS, Please reinstall OS and retry!"
    exit 1
fi

# Install dependencies
if [ ${OS} == 'CentOS' ]; then
    yum -y install python make wget
elif [ ${OS} == 'Debian' -o ${OS} == 'Ubuntu' ]; then
    apt-get -y install python make wget
fi

# Download ServerStatus client
cd /usr/local/
wget --no-check-certificate https://github.com/cppla/ServerStatus/raw/master/clients/client-linux.py -O status-client.py
[ ! -e "status-client.py" ] && { echo "Error: Download client failed."; exit 1; }

# Create config file
cat > /usr/local/status-client.conf << EOF
SERVER = "${CLIENT_SERVER}"
PORT = ${CLIENT_PORT}
USER = "${CLIENT_USER}"
PASSWORD = "${CLIENT_PASSWORD}"
EOF

# Create service
if [ ${OS} == 'CentOS' ]; then
    if [ ! -e /etc/init.d/status-client ]; then
        cat > /etc/init.d/status-client << EOF
#!/bin/sh
# chkconfig:   2345 50 50
# description:  Server Status client

### BEGIN INIT INFO
# Provides:          ServerStatus
# Required-Start:    \$local_fs \$remote_fs \$network
# Required-Stop:     \$local_fs \$remote_fs \$network
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

cd /usr/local
python /usr/local/status-client.py /usr/local/status-client.conf run
EOF
        chmod +x /etc/init.d/status-client
        chkconfig --add status-client
        chkconfig status-client on
    fi
elif [ ${OS} == 'Debian' -o ${OS} == 'Ubuntu' ]; then
    if [ ! -e /etc/systemd/system/status-client.service ]; then
        cat > /etc/systemd/system/status-client.service << EOF
[Unit]
Description=ServerStatus client
Documentation=https://github.com/cppla/ServerStatus
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/python /usr/local/status-client.py /usr/local/status-client.conf run
Restart=on-failure
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF
        systemctl enable status-client
    fi
fi

# Start service
if [ ${OS} == 'CentOS' ]; then
    service status-client start
elif [ ${OS} == 'Debian' -o ${OS} == 'Ubuntu' ]; then
    systemctl start status-client
fi

echo "ServerStatus client has been installed and started successfully!"
