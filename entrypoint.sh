#!/bin/bash
set -eux

cd /tmp

openssl req \
  -x509 \
  -new \
  -nodes \
  -newkey ec:<(openssl ecparam -name prime256v1) \
  -keyout certkey \
  -out certcrt \
  -sha256 \
  -days 3650 \
  -subj "/CN=_" \
  -addext "subjectAltName = DNS:_"

mv certcrt cert.crt
mv certkey cert.key

mkdir -p /app/data

# -e传递nginx端口===========================
if [ -n "$HTTP_PORT" ] || [ -n "$HTTPS_PORT" ] || [ -n "$SERVER_NAME" ]; then
  echo "--> Modifying nginx.conf..."
  # 创建一个临时文件
  CONF_TMP=$(mktemp)
  
  # 使用 awk 替换端口和域名，支持 IPv4/IPv6 和各种参数
  awk -v http_port="$HTTP_PORT" -v https_port="$HTTPS_PORT" -v server_name="$SERVER_NAME" '
  {
    # 替换 HTTP 端口 (listen 80; 或 listen [::]:80;)
    if (http_port != "") {
      gsub(/listen\s+80\s*;/, "listen " http_port ";")
      gsub(/listen\s+\[::\]:80\s*;/, "listen [::]:" http_port ";")
      gsub(/listen\s+80\s+default_server\s*;/, "listen " http_port " default_server;")
      gsub(/listen\s+\[::\]:80\s+default_server\s*;/, "listen [::]:" http_port " default_server;")
    }
    
    # 替换 HTTPS 端口 (listen 443 ssl; 或 listen [::]:443 ssl;)
    if (https_port != "") {
      gsub(/listen\s+443\s+ssl\s*;/, "listen " https_port " ssl;")
      gsub(/listen\s+\[::\]:443\s+ssl\s*;/, "listen [::]:" https_port " ssl;")
      gsub(/listen\s+443\s+ssl\s+default_server\s*;/, "listen " https_port " ssl default_server;")
      gsub(/listen\s+\[::\]:443\s+ssl\s+default_server\s*;/, "listen [::]:" https_port " ssl default_server;")
    }
    
    # 替换 server_name 指令（只匹配行首的 server_name，避免替换 $server_name 变量）
    if (server_name != "") {
      gsub(/^\s*server_name\s+[^;]+;/, "server_name " server_name " ;")
    }
    
    print
  }' /app/conf/nginx.conf > "$CONF_TMP"
  
  # 将修改后的内容写回到配置文件，然后删除临时文件
  cat "$CONF_TMP" > /app/conf/nginx.conf && rm "$CONF_TMP"
  
  echo "--> HTTP_PORT: ${HTTP_PORT:-default}"
  echo "--> HTTPS_PORT: ${HTTPS_PORT:-default}"
  echo "--> SERVER_NAME: ${SERVER_NAME:-default}"
# else
#   echo "--> HTTP_PORT/HTTPS_PORT/SERVER_NAME not set, using default values from nginx.conf"
fi
# -e传递nginx端口============================

exec "$@"