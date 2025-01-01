#!/bin/bash

# 检查是否以 root 用户运行
if [[ $EUID -ne 0 ]]; then
  echo "请以 root 用户运行此脚本"
  exit 1
fi

# 定义默认值
DEFAULT_DOMAIN="example.com"
DEFAULT_UPSTREAM="127.0.0.1"
DEFAULT_UPSTREAM_PORT="8080"
DEFAULT_CONFIG_DIR="/etc/nginx/conf.d"

# 获取域名
read -r -p "请输入要配置的域名 (默认为: $DEFAULT_DOMAIN): " DOMAIN
DOMAIN="${DOMAIN:-$DEFAULT_DOMAIN}"

# 获取上游服务器 IP 地址
read -r -p "请输入上游服务器的 IP 地址 (默认为: $DEFAULT_UPSTREAM): " UPSTREAM
UPSTREAM="${UPSTREAM:-$DEFAULT_UPSTREAM}"

# 获取上游服务器端口
read -r -p "请输入上游服务器的端口 (默认为: $DEFAULT_UPSTREAM_PORT): " UPSTREAM_PORT
UPSTREAM_PORT="${UPSTREAM_PORT:-$DEFAULT_UPSTREAM_PORT}"

# 获取 Nginx 配置文件目录
read -r -p "请输入 Nginx 配置文件目录 (默认为: $DEFAULT_CONFIG_DIR): " CONFIG_DIR
CONFIG_DIR="${CONFIG_DIR:-$DEFAULT_CONFIG_DIR}"


# 生成 Nginx 配置文件内容
CONFIG_FILE="$CONFIG_DIR/${DOMAIN}.conf"

CONFIG_CONTENT="server {
    listen 80;
    server_name ${DOMAIN};

    location / {
        proxy_pass http://${UPSTREAM}:${UPSTREAM_PORT};
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
"

# 输出要创建的文件和内容
echo "创建配置文件: $CONFIG_FILE"
echo "$CONFIG_CONTENT"

# 写入配置文件
echo "$CONFIG_CONTENT" > "$CONFIG_FILE"

if [[ $? -ne 0 ]]; then
  echo "写入配置文件失败"
  exit 1
fi

# 检查 nginx 配置语法
nginx -t

if [[ $? -ne 0 ]]; then
  echo "Nginx 配置检查失败，请检查配置文件: $CONFIG_FILE"
  exit 1
fi

# 重启 Nginx 服务
systemctl restart nginx

if [[ $? -ne 0 ]]; then
  echo "重启 Nginx 服务失败"
  exit 1
fi

echo "Nginx 反向代理配置完成！"
echo "请检查：$CONFIG_FILE 确保配置正确。"