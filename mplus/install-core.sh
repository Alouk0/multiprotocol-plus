#!/bin/bash
# ------------------------------------------------------------
# MultiPlus+ Enhanced - Core Installer
# Handles dependency setup, SSL, and base service installation
# Author: John Kennedy (Alouk0)
# Version: 2.0
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

# --- Color setup ---
green=$(tput setaf 2)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

log() { echo -e "${green}[INFO]${reset} $*"; }
error_exit() { echo -e "${red}[ERROR]${reset} $*" >&2; exit 1; }

# --- Root check ---
if [[ $EUID -ne 0 ]]; then
  error_exit "Run this script as root (sudo bash install-core.sh)."
fi

clear
echo -e "${cyan}══════════════════════════════════════════════════════════════${reset}"
echo -e "${yellow}              MultiPlus+ Enhanced Core Setup                   ${reset}"
echo -e "${cyan}══════════════════════════════════════════════════════════════${reset}"
sleep 1

# --- Update system ---
log "Updating packages..."
apt update -y && apt upgrade -y && apt autoremove -y

# --- Disable IPv6 for stability ---
log "Disabling IPv6..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p >/dev/null

# --- Install dependencies ---
log "Installing required packages..."
apt install -y curl wget jq unzip tar screen ufw fail2ban ca-certificates \
               gnupg lsb-release net-tools lsof dnsutils openssl socat git

# --- Install acme.sh (for SSL certificates) ---
if ! command -v acme.sh >/dev/null 2>&1; then
  log "Installing acme.sh (Let's Encrypt client)..."
  curl https://get.acme.sh | sh
  export PATH="$HOME/.acme.sh:$PATH"
fi

# --- Install Firewall and basic security ---
log "Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

systemctl enable fail2ban
systemctl start fail2ban
log "Firewall and Fail2Ban are active."

# --- Install Xray-core ---
log "Installing Xray-core (for VLESS/VMESS)..."
mkdir -p /usr/local/xray
cd /usr/local/xray
wget -q https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -O xray.zip
unzip -oq xray.zip && rm -f xray.zip
install -m 755 xray /usr/local/bin/xray

cat >/etc/systemd/system/xray.service <<'EOF'
[Unit]
Description=Xray Service
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
ExecStart=/usr/local/bin/xray -config /etc/xray/config.json
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/xray /var/log/xray
cat >/etc/xray/config.json <<'EOF'
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "warning"
  },
  "inbounds": [],
  "outbounds": [
    { "protocol": "freedom", "settings": {} }
  ]
}
EOF

systemctl daemon-reload
systemctl enable xray
systemctl start xray
log "Xray-core installed and running."

# --- Install Trojan-Go ---
log "Installing Trojan-Go..."
cd /usr/local
wget -q https://github.com/p4gefau1t/trojan-go/releases/latest/download/trojan-go-linux-amd64.zip -O trojan-go.zip
unzip -oq trojan-go.zip && rm -f trojan-go.zip
mv trojan-go /usr/local/bin/trojan-go
chmod +x /usr/local/bin/trojan-go

cat >/etc/systemd/system/trojan-go.service <<'EOF'
[Unit]
Description=Trojan-Go Service
After=network.target

[Service]
ExecStart=/usr/local/bin/trojan-go -config /etc/trojan-go/config.json
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /etc/trojan-go /var/log/trojan-go
log "Trojan-Go installed."

# --- Install Shadowsocks-libev ---
log "Installing Shadowsocks-libev..."
apt install -y shadowsocks-libev
systemctl enable shadowsocks-libev
systemctl start shadowsocks-libev
log "Shadowsocks-libev installed and active."

# --- Install OpenVPN ---
log "Installing OpenVPN..."
apt install -y openvpn easy-rsa
make-cadir /etc/openvpn/easy-rsa
log "OpenVPN base installed."

# --- Install UDP/SlowDNS helpers ---
log "Preparing UDP and SlowDNS components..."
apt install -y python3 python3-pip
pip3 install websockify >/dev/null 2>&1 || true

# --- Enable BBR & Performance tuning ---
log "Enabling BBR and network performance tuning..."
cat >/etc/sysctl.d/99-bbrplus.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_forward=1
fs.file-max=1000000
EOF
sysctl --system >/dev/null

# --- Completion ---
log "Base system and dependencies installed successfully!"
echo -e "${yellow}Next steps:${reset}"
echo "  → Run 'mplus' to open the MultiPlus+ dashboard."
echo "  → Use the menu to configure protocols, SSL, and more."
echo
