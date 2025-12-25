#!/bin/bash
set -e

# === 基础路径配置 ===
DATA_DIR="/data"
CERT_DIR="$DATA_DIR/ssl"
PASS_FILE="$DATA_DIR/xpra.pass"
PROFILE_DIR="$DATA_DIR/chrome-profile"

mkdir -p "$CERT_DIR" "$PROFILE_DIR"

# === 1. 密码逻辑 ===
XPRA_PASS=${XPRA_PASS:-123456}
echo "$XPRA_PASS" > "$PASS_FILE"
chmod 600 "$PASS_FILE"

echo "================================================="
echo "🔒 XPRA PASSWORD: $XPRA_PASS"
echo "================================================="

# === 2. SSL 证书逻辑 (修正了 openssl 拼写) ===
if [ ! -f "$CERT_DIR/server.pem" ]; then
    echo "🔑 Generating self-signed SSL certificate..."
    openssl req -x509 -newkey rsa:4096 -nodes \
        -keyout "$CERT_DIR/key.temp" \
        -out "$CERT_DIR/cert.temp" \
        -days 3650 \
        -subj "/CN=xpra-chrome" \
        -sha256
    
    cat "$CERT_DIR/key.temp" "$CERT_DIR/cert.temp" > "$CERT_DIR/server.pem"
    rm "$CERT_DIR/key.temp" "$CERT_DIR/cert.temp"
    chmod 600 "$CERT_DIR/server.pem"
fi

# === 3. 运行环境清理 ===
rm -rf /run/user/$(id -u)/xpra
mkdir -p /run/user/$(id -u)/xpra

# === 4. 强制配置校准 ===
XPRA_HTML="on"
XPRA_SSL="off"

echo "================================================="
echo "🌐 HTML5 (WebSocket) Mode: $XPRA_HTML"
echo "🔒 Internal SSL Mode:      $XPRA_SSL"
echo "Running Xpra Version:"
xpra --version
echo "================================================="

# === 5. 启动 Xpra ===
# 使用 --bind-tcp 这种最稳的语法
exec xpra start :100 \
    --daemon=no \
    --mdns=no \
    --webcam=no \
    --notifications=no \
    --system-tray=no \
    --bell=no \
    --audio=no \
    --printing=no \
    --file-transfer=no \
    --bind-tcp=0.0.0.0:10000 \
    --auth=file:filename="$PASS_FILE" \
    --ssl=$XPRA_SSL \
    --ssl-cert="$CERT_DIR/server.pem" \
    --html=$XPRA_HTML \
    --start="google-chrome --no-sandbox --disable-gpu --disable-dev-shm-usage --user-data-dir=$PROFILE_DIR"
