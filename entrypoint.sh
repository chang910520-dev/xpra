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
    # Generate Key and Cert separately to avoid overwriting issues
    openssl req -x509 -newkey rsa:4096 -nodes \
        -keyout "$CERT_DIR/key.temp" \
        -out "$CERT_DIR/cert.temp" \
        -days 3650 \
        -subj "/CN=xpra-chrome" \
        -sha256
    
    # Xpra expects Key + Cert in the same file for --ssl-cert
    cat "$CERT_DIR/key.temp" "$CERT_DIR/cert.temp" > "$CERT_DIR/server.pem"
    rm "$CERT_DIR/key.temp" "$CERT_DIR/cert.temp"
    
    chmod 600 "$CERT_DIR/server.pem"
fi

# 3. Cleanup previous locks (if container restarted improperly)
rm -rf /run/user/$(id -u)/xpra
mkdir -p /run/user/$(id -u)/xpra

# 4. Configurable Options
XPRA_HTML=${XPRA_HTML:-off}
XPRA_SSL=${XPRA_SSL:-on}

echo "================================================="
echo "🌐 HTML5 Mode: $XPRA_HTML"
echo "🔒 SSL Mode:   $XPRA_SSL"
echo "Running Xpra Version:"
xpra --version
echo "================================================="

# 5. Start Xpra (v6 Modern Syntax)
# We use --bind=TYPE://IP:PORT/ syntax which replaces the old --bind-tcp/udp flags.
# Note: When UDP is bound, Xpra automatically attempts to load the aioquic module.
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
    --bind=tcp://0.0.0.0:10000/ \
    --bind=udp://0.0.0.0:10000/ \
    --auth=file:filename="$PASS_FILE" \
    --ssl=$XPRA_SSL \
    --ssl-cert="$CERT_DIR/server.pem" \
    --html=$XPRA_HTML \
    --start="google-chrome --no-sandbox --disable-gpu --disable-dev-shm-usage --user-data-dir=$DATA_DIR/chrome-profile"
