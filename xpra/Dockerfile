FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV XPRA_PORT=10000
ENV DISPLAY=:100

# 1. Install Basic Tools & Keys
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    gnupg \
    ca-certificates \
    software-properties-common \
    apt-transport-https \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 2. Add Xpra Official Repository (Winswitch)
# Providing much better performance and UDP support than Ubuntu default
RUN wget -q https://xpra.org/gpg.asc -O- | gpg --dearmor > /usr/share/keyrings/xpra.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/xpra.gpg] https://xpra.org/ jammy main" > /etc/apt/sources.list.d/xpra.list

# 3. Add Google Chrome Repository
RUN wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /usr/share/keyrings/google-chrome.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" \
    > /etc/apt/sources.list.d/google-chrome.list

# 4. Install Xpra and Chrome
RUN apt-get update && apt-get install -y \
    xpra \
    xvfb \
    dbus-x11 \
    google-chrome-stable \
    ffmpeg \
    libvpx7 \
    libwebp7 \
    && rm -rf /var/lib/apt/lists/*

# 5. Setup User
# Running as root is dangerous for Chrome. We create a dedicated user.
RUN useradd -m -u 1000 -s /bin/bash xpra && \
    mkdir -p /data /run/user/1000/xpra && \
    chown -R xpra:xpra /data /run/user/1000

# 6. Final Config
VOLUME ["/data"]
WORKDIR /data

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Switch to non-root user
USER xpra
ENV XDG_RUNTIME_DIR=/run/user/1000

EXPOSE 10000

ENTRYPOINT ["/entrypoint.sh"]