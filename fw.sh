#!/bin/bash

# ServerStatus 配置文件路径
CONFIG_FILE="/usr/local/ServerStatus/server/config.json"

# 备份当前的配置文件
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# 函数用于添加服务器状态节点
add_server_status_node() {
    local username password name type location region
    IFS=',' read -r -a node_info <<< "$1"
    
    # 解析节点信息
    for info in "${node_info[@]}"; do
        case "$info" in
            username=*) username="${info#*=}" ;;
            password=*) password="${info#*=}" ;;
            name=*) name="${info#*=}" ;;
            type=*) type="${info#*=}" ;;
            location=*) location="${info#*=}" ;;
            region=*) region="${info#*=}" ;;
        esac
    done
    
    # 使用printf构建JSON格式的节点信息
    node_json=$(printf '{"username": "%s", "password": "%s", "name": "%s", "type": "%s", "host": "None", "location": "%s", "disabled": false, "region": "%s"}' \
        "$username" "$password" "$name" "$type" "$location" "$region")

    # 使用 jq 工具将新的节点信息添加到配置文件的 json 数组中
    # 安装 jq 工具如果你的系统还没有安装
    # sudo apt install jq (Debian/Ubuntu)
    # sudo yum install jq (CentOS)

    jq ".servers += [$node_json]" "$CONFIG_FILE" > "temp.json" && mv "temp.json" "$CONFIG_FILE"
}

echo "请按格式输入您的节点信息 (每行一个节点，Ctrl-D 结束输入)："
echo "格式：username=用户名,password=密码,name=名称,type=类型,location=位置,region=地区"

# 读取多行输入
while IFS= read -r line; do
    add_server_status_node "$line"
done

echo "节点已成功添加！"
