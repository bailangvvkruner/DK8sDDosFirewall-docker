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
if [ -n "$HTTP_PORT" ] || [ -n "$HTTPS_PORT" ]; then
  echo "--> Modifying nginx.conf ports..."
  # 创建一个临时文件
  CONF_TMP=$(mktemp)
  
  # 使用 awk 替换端口，支持 IPv4/IPv6 和各种参数
  awk -v http_port="$HTTP_PORT" -v https_port="$HTTPS_PORT" '
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
    
    print
  }' /app/nginx.conf > "$CONF_TMP"
  
  # 将修改后的内容写回到配置文件，然后删除临时文件
  cat "$CONF_TMP" > /app/nginx.conf && rm "$CONF_TMP"
  
  echo "--> HTTP_PORT: ${HTTP_PORT:-default}"
  echo "--> HTTPS_PORT: ${HTTPS_PORT:-default}"
# else
#   echo "--> HTTP_PORT/HTTPS_PORT not set, using default ports from nginx.conf"
fi
# -e传递nginx端口============================

exec "$@"