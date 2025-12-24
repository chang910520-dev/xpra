# Xpra Chrome Docker (UDP + TLS + Persistent)
 
A highly optimized Docker container for running Google Chrome remotely using Xpra with TLS encryption and UDP acceleration.
 
## ✨ Features
- **Official Xpra Repo**: Uses the latest Xpra version (better than Ubuntu default).
- **Security**: Runs as non-root user (`xpra`), Enforced TLS (Self-signed).
- **Performance**: UDP/QUIC enabled by default.
- **Persistence**: Chrome profile and SSL certs persist in `/data`.

## 🚀 Quick Start

### 1. Run the Container
