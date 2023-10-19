#!/bin/bash

# 预设的参数
CLIENT_SERVER_IP="45.148.134.106"    # 服务器 IP 地址
CLIENT_PORT="51000"                  # 服务器端口号
CLIENT_USER="root"                   # 用户名
CLIENT_PASSWORD="@Zy123456789"       # 密码
CLIENT_VNSTAT="yes"                  # 是否启用 vnStat

# 检查是否为root用户
[ $(id -u) != "0" ] && {
    echo "错误: 你必须以root用户来执行此安装脚本"
    exit 1
}

# 安装依赖
if [[ ${release} == "centos" ]]; then
    yum update -y
    yum install -y python make wget
else
    apt-get update -y
    apt-get install -y python make wget
fi

# 下载客户端文件
wget --no-check-certificate -O client-linux.py "https://raw.githubusercontent.com/cppla/ServerStatus/master/clients/client-linux.py"

# 设置客户端配置
sed -i "s/SERVER = '127.0.0.1'/SERVER = '$CLIENT_SERVER_IP'/g" client-linux.py
sed -i "s/PORT = 35601/PORT = $CLIENT_PORT/g" client-linux.py
sed -i "s/USER = 'USER'/USER = '$CLIENT_USER'/g" client-linux.py
sed -i "s/PASSWORD = 'PASSWORD'/PASSWORD = '$CLIENT_PASSWORD'/g" client-linux.py

# 检查并安装vnStat
if [[ $CLIENT_VNSTAT == "yes" ]]; then
    if [[ ! -e '/usr/bin/vnstat' ]]; then
        if [[ ${release} == "centos" ]]; then
            yum install -y vnstat
        else
            apt-get install -y vnstat
        fi
    fi
    sed -i "s/vnstat_enabled = False/vnstat_enabled = True/g" client-linux.py
fi

# 设置开机自启
if [[ ${release} == "centos" ]]; then
    echo -e "\nnohup python $(pwd)/client-linux.py &" >> /etc/rc.d/rc.local
    chmod +x /etc/rc.d/rc.local
else
    echo -e "\nnohup python $(pwd)/client-linux.py &" >> /etc/rc.local
    chmod +x /etc/rc.local
fi

# 启动客户端
nohup python $(pwd)/client-linux.py &

echo "客户端安装并启动完成!"
