#!/bin/bash

# ServerStatus配置文件路径
CONFIG_FILE="/usr/local/ServerStatus/server/config.json"

# 备份当前的配置文件
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# 函数用于添加服务器状态节点
add_server_status_node() {
    local username password name virtualization location region
    IFS=',' read -r -a node_info <<< "$1"
    
    # 解析节点信息
    for info in "${node_info[@]}"; do
        case "$info" in
            username=*) username="${info#*=}" ;;
            password=*) password="${info#*=}" ;;
            name=*) name="${info#*=}" ;;
            virtualization=*) virtualization="${info#*=}" ;;
            location=*) location="${info#*=}" ;;
            region=*) region="${info#*=}" ;;
        esac
    done
    
    # 构建JSON格式的节点信息并添加到配置文件
    node_json="{
        \"username\": \"$username\",
        \"password\": \"$password\",
        \"name\": \"$name\",
        \"type\": \"$virtualization\",
        \"location\": \"$location\",
        \"region\": \"$region\"
    }"

    # 使用jq工具将新的节点信息添加到配置文件的json数组中
    # 安装jq工具如果你的系统还没有安装
    # sudo apt install jq (Debian/Ubuntu)
    # sudo yum install jq (CentOS)

    jq ".servers += [$node_json]" "$CONFIG_FILE" > "temp.json" && mv "temp.json" "$CONFIG_FILE"
}

echo "Please enter your nodes' information (each line for a node, Ctrl-D to end):"

# 读取多行输入
while IFS= read -r line; do
    add_server_status_node "$line"
done

echo "Nodes have been added successfully!"
