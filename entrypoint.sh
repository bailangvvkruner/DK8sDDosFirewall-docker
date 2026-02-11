#!/bin/bash
set -eux

cd /app

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

mkdir -p data

exec "$@"