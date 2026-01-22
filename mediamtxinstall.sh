#!/bin/bash
set -e

echo "==============================="
echo " MediaMTX Installation Script "
echo " Ubuntu 22.04 (Jammy)          "
echo "==============================="

# -------- VARIABLES --------
VERSION="v1.15.6"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/usr/local/etc"
SERVICE_FILE="/etc/systemd/system/mediamtx.service"

# -------- CHECK ROOT --------
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root: sudo ./installation.sh"
  exit 1
fi

# -------- ARCH DETECTION --------
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
  FILE="mediamtx_${VERSION}_linux_amd64.tar.gz"
elif [[ "$ARCH" == "aarch64" ]]; then
  FILE="mediamtx_${VERSION}_linux_arm64.tar.gz"
else
  echo "❌ Unsupported architecture: $ARCH"
  exit 1
fi

URL="https://github.com/bluenviron/mediamtx/releases/download/${VERSION}/${FILE}"

echo "➡ Architecture : $ARCH"
echo "➡ Downloading  : $URL"

# -------- DEPENDENCIES --------
apt update -y
apt install -y wget tar ufw

# -------- DOWNLOAD --------
cd /tmp
rm -f $FILE
wget $URL

# -------- EXTRACT --------
tar -xzf $FILE

# -------- INSTALL --------
mv mediamtx $INSTALL_DIR/
mkdir -p $CONFIG_DIR
mv mediamtx.yml $CONFIG_DIR/

chmod +x $INSTALL_DIR/mediamtx

# -------- SYSTEMD SERVICE --------
cat <<EOF > $SERVICE_FILE
[Unit]
Description=MediaMTX Media Server
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=$INSTALL_DIR/mediamtx $CONFIG_DIR/mediamtx.yml
Restart=always
User=root
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

# -------- ENABLE SERVICE --------
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable mediamtx
systemctl restart mediamtx

# -------- FIREWALL --------
ufw allow 8554/tcp   # RTSP
ufw allow 1935/tcp   # RTMP
ufw allow 8888/tcp   # HLS
ufw allow 8889/tcp   # WebRTC
ufw reload || true

# -------- STATUS --------
echo ""
echo "✅ MediaMTX Installed Successfully"
echo ""
mediamtx --version
echo ""
systemctl status mediamtx --no-pager
