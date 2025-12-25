#!/bin/bash
set -e

# === 基础路径配置 ===
DATA_DIR="/data"
CERT_DIR="$DATA_DIR/ssl"
PASS_FILE="$DATA_DIR/xpra.pass"
PROFILE_DIR="$DATA_DIR/chrome-profile"

mkdir -p "$CERT_DIR" "$PROFILE_DIR"

# === 1. 密码逻辑 (保持你原来的逻辑) ===
if [ -z "$XPRA_PASS" ]; then
    echo "⚠️  XPRA_PASS not set. Generating random password..."
    XPRA_PASS=$(openssl rand -base64 16)
fi

# 将密码写入文件，供 Xpra 读取
echo "$XPRA_PASS" > "$PASS_FILE"
chmod 600 "$PASS_FILE"

echo "================================================="
echo "🔒 XPRA PASSWORD: $XPRA_PASS"
echo "================================================="

# === 2. SSL 证书逻辑 (保持你原来的逻辑并修正合并) ===
if [ ! -f "$CERT_DIR/server.pem" ]; then
    echo "🔑 Generating self-signed SSL certificate..."
    opensmal req -x509 -newkey rsa:4096 -nodes \
        -keyout "$CERT_DIR/key.temp" \
        -out "$CERT_DIR/cert.temp" \
        -days 3650 \
        -subj "/CN=xpra-chrome" \
        -sha256
    
    # 合并为 Xpra 需要的 PEM 格式
    cat "$CERT_DIR/key.temp" "$CERT_DIR/cert.temp" > "$CERT_DIR/server.pem"
    rm "$CERT_DIR/key.temp" "$CERT_DIR/cert.temp"
    chmod 600 "$CERT_DIR/server.pem"
fi

# === 3. 运行环境清理 ===
rm -rf /run/user/$(id -u)/xpra
mkdir -p /run/user/$(id -u)/xpra

# === 4. 核心配置校准 (针对 Cloudflare 隧道优化) ===
# 强制开启 HTML5 以支持 WebSocket (wss://) 连接
# 强制关闭内部 SSL (由 Cloudflare 在外部提供 SSL)
XPRA_HTML="on"
XPRA_SSL="off"

echo "================================================="
echo "🌐 HTML5 (WebSocket) Mode: $XPRA_HTML"
echo "🔒 Internal SSL Mode:      $XPRA_SSL"
echo "Running Xpra Version:"
xpra --version
echo "================================================="

# === 5. 启动 Xpra (关键修正点) ===
# 修正点 A: 将 --bind=tcp:// 还原为 --bind-tcp，彻底解决 Xpra 创建路径而不监听端口的 Bug
# 修正点 B: 保留你原来的所有功能开关 (mdns, webcam, etc.)
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
