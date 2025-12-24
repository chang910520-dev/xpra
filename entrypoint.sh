#!/bin/bash
set -e
  
# Configuration
DATA_DIR="/data"
CERT_DIR="$DATA_DIR/ssl"
PASS_FILE="$DATA_DIR/xpra.pass"
XPRA_LOG="$DATA_DIR/xpra.log"

# Ensure directories exist (Volume might be empty on first run)
mkdir -p "$CERT_DIR"

# 1. Setup Password
if [ -z "$XPRA_PASS" ]; then
    echo "⚠️  XPRA_PASS not set. Generating random password..."
    XPRA_PASS=$(openssl rand -base64 16)
fi

# Write password to file for Xpra auth module
echo "$XPRA_PASS" > "$PASS_FILE"
chmod 600 "$PASS_FILE"

echo "================================================="
echo "🔒 XPRA PASSWORD: $XPRA_PASS"
echo "================================================="

# 2. Setup TLS (Self-Signed)
if [ ! -f "$CERT_DIR/server.pem" ]; then
    echo "🔑 Generating self-signed SSL certificate..."
    openssl req -x509 -newkey rsa:4096 -nodes \
        -keyout "$CERT_DIR/server.pem" \
        -out "$CERT_DIR/server.pem" \
        -days 3650 \
        -subj "/CN=xpra-chrome" \
        -sha256
    chmod 600 "$CERT_DIR/server.pem"
fi

# 3. Cleanup previous locks (if container restarted improperly)
rm -rf /run/user/$(id -u)/xpra
mkdir -p /run/user/$(id -u)/xpra

# 4. Start Xpra
# --bind-tcp: Listen on TCP 10000
# --bind-udp: Listen on UDP 10000 (QUIC/UDP)
# --auth: Use the password file we just created
# --ssl-cert: Use our generated cert
# --start: Launch Chrome
# --daemon=no: Keep in foreground for Docker
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
    --bind-udp=0.0.0.0:10000 \
    --auth=file:filename="$PASS_FILE" \
    --ssl=on \
    --ssl-cert="$CERT_DIR/server.pem" \
    --start="google-chrome --no-sandbox --disable-gpu --disable-dev-shm-usage --user-data-dir=$DATA_DIR/chrome-profile"
