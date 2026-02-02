# DK8sDDosFirewall
Protect your service from CC attacks, UDP attacks, and traffic flooding attacks.

[DK8s DDos Firewall Code Repository](https://github.com/yinyue123/DK8sDDosFirewall)

[DK8s DDos Firewall Docker Image](https://hub.docker.com/r/yinyue123/ddos-firewal)

`For more information, please visit `[https://www.dk8s.com](https://www.dk8s.com)


```
DIR=/data/dk8sfirewall
# GH=https://gitee.com/azhaoyang_admin/DK8sDDosFirewall/raw/main
GH=https://gitee.com/white-wolf-vvvk/DK8sDDosFirewall/raw/main

mkdir -p "$DIR"
cd "$DIR"

for f in nginx.conf env.conf cert.crt cert.key protect.lua record.lua stats.lua persistence.lua save_data.lua view_data.lua cdn_ips.conf; do
  curl -L --retry 3 -o "$DIR/$f" "$GH/$f"
done

docker run -d \
--name dk8s-ddos-fw \
--user=root \
--network host \
--cap-add=NET_ADMIN \
--cap-add=NET_RAW \
--cap-add=SYS_ADMIN \
-v "$DIR:/app:rw" \
bailangvvking/dk8sddosfirewall:latest

```


## 压测
go run stress.go https://blog.gov6g.cn 100 100s