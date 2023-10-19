#!/bin/bash

# ServerStatus 配置文件路径
CONFIG_FILE="/usr/local/ServerStatus/server/config.json"

# 备份当前的配置文件
cp "$CONFIG_FILE" "$CONFIG_FILE.bak"

# 函数用于删除服务器状态节点
remove_server_status_node() {
    local name
    name="$1"
    
    # 使用 jq 工具从配置文件的 json 数组中删除特定的节点
    # 安装 jq 工具如果你的系统还没有安装
    # sudo apt install jq (Debian/Ubuntu)
    # sudo yum install jq (CentOS)

    jq ".servers |= map(select(.name != \"$name\"))" "$CONFIG_FILE" > "temp.json" && mv "temp.json" "$CONFIG_FILE"
}

echo "请输入要删除的节点名称（每行一个名称，Ctrl-D 结束输入）："

# 读取多行输入
while IFS= read -r name; do
    remove_server_status_node "$name"
    echo "节点 $name 已被删除。"
done

echo "所有指定节点已成功删除！"
