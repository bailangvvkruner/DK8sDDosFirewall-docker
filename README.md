# DK8sDDosFirewall
Protect your service from CC attacks, UDP attacks, and traffic flooding attacks.

[DK8s DDos Firewall Code Repository](https://github.com/yinyue123/DK8sDDosFirewall)

[DK8s DDos Firewall Docker Image](https://hub.docker.com/r/yinyue123/ddos-firewal)

`For more information, please visit `[https://www.dk8s.com](https://www.dk8s.com)


```
DIR=/data/dk8sfirewall
# GH=https://gitee.com/azhaoyang_admin/DK8sDDosFirewall/raw/main
GH=https://gitee.com/white-wolf-vvvk/DK8sDDosFirewall/raw/main

mkdir -p "$DIR"/{conf,lua,data}
cd "$DIR"

# 下载配置文件到 conf 目录
for f in nginx.conf env.conf cdn_ips.conf; do
  curl -L --retry 3 -o "$DIR/conf/$f" "$GH/$f"
done

# 下载 lua 文件到 lua 目录
for f in protect.lua record.lua stats.lua persistence.lua save_data.lua view_data.lua; do
  curl -L --retry 3 -o "$DIR/lua/$f" "$GH/$f"
done

# 下载或生成 SSL 证书到 conf 目录
# curl -L --retry 3 -o "$DIR/conf/cert.crt" "$GH/cert.crt"
# curl -L --retry 3 -o "$DIR/conf/cert.key" "$GH/cert.key"

docker run -d \
--name dk8s-ddos-fw \
--user=root \
--network host \
--cap-add=NET_ADMIN \
--cap-add=NET_RAW \
--cap-add=SYS_ADMIN \
-v "$DIR/conf:/app/conf:rw" \
-v "$DIR/lua:/app/lua:rw" \
-v "$DIR/data:/app/data:rw" \
bailangvvking/dk8sddosfirewall:latest

```

## 环境变量

支持以下环境变量来自定义配置：

| 环境变量 | 说明 | 默认值 |
|---------|------|--------|
| HTTP_PORT | HTTP 端口 | 80 |
| HTTPS_PORT | HTTPS 端口 | 443 |
| SERVER_NAME | 域名（支持多个，用空格分隔）| www.dk8s.com |

### 使用示例

```bash
# 自定义端口和域名
docker run -d \
--name dk8s-ddos-fw \
--user=root \
--network host \
--cap-add=NET_ADMIN \
--cap-add=NET_RAW \
--cap-add=SYS_ADMIN \
-v "$DIR/conf:/app/conf:rw" \
-v "$DIR/lua:/app/lua:rw" \
-v "$DIR/data:/app/data:rw" \
-e HTTP_PORT=8080 \
-e HTTPS_PORT=8443 \
-e SERVER_NAME="blog.zipimg.cn blog.lovelyy.eu.org" \
bailangvvking/dk8sddosfirewall:latest
```

**注意**：使用特权端口（< 1024）时需要 `--user=root`

## 压测
go run stress.go https://blog.gov6g.cn 100 100s