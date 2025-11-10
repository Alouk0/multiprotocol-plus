#!/bin/bash
# -----------------------------------------------------------
# MultiPlus+ Enhanced Auto-Installer
# Author: John Kennedy (Alouk0)
# Repo: https://github.com/Alouk0/multiprotocol-plus
# Compatible: Ubuntu 20.04–24.04 / Debian 10–12
# -----------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

REPO_URL="https://raw.githubusercontent.com/Alouk0/multiprotocol-plus/main"
INSTALL_DIR="/usr/local/bin/mplus"
LOGFILE="/var/log/mplus-install.log"

# ----------- UTILITIES -----------
log() { echo -e "\e[1;32m[INFO]\e[0m $*"; echo "[INFO] $*" >>"$LOGFILE"; }
error_exit() { echo -e "\e[1;31m[ERROR]\e[0m $*" >&2; exit 1; }

# ----------- CHECKS --------------
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run as root (sudo bash install.sh)."
fi

log "Initializing MultiPlus+ Enhanced installation..."
sleep 1

# ----------- SYSTEM PREP ----------
log "Disabling IPv6 (for compatibility)..."
sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null
sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null

log "Updating system packages..."
apt update -y && apt upgrade -y
apt install -y curl wget jq unzip lsof net-tools ca-certificates apt-transport-https \
               software-properties-common screen ufw fail2ban git dialog whiptail

# ----------- DIRECTORY SETUP ------
log "Creating directory structure at $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"/{protocol,utils}
chmod -R 755 "$INSTALL_DIR"

# ----------- ACME + SSL ----------
if ! command -v acme.sh >/dev/null 2>&1; then
    log "Installing acme.sh for automatic SSL certificates..."
    curl https://get.acme.sh | sh
    export PATH="$HOME/.acme.sh:$PATH"
fi

# ----------- DOWNLOAD COMPONENTS ---
log "Fetching main components from GitHub..."
download_file() {
    local file="$1"
    local dest="$2"
    wget -q --show-progress -O "$dest" "$REPO_URL/$file" || error_exit "Failed to download $file"
    chmod +x "$dest"
}

download_file "mplus/menu.sh" "$INSTALL_DIR/menu.sh"
download_file "mplus/install-core.sh" "$INSTALL_DIR/install-core.sh"

# Subdirectories
for sub in vmess-manager.sh vless-manager.sh trojan-manager.sh ss-manager.sh \
            ovpn-manager.sh slowdns.sh udpcustom.sh; do
    download_file "mplus/protocol/$sub" "$INSTALL_DIR/protocol/$sub"
done

for util in dnschanger.sh xray-update.sh bbrplus.sh netflix-checker.sh backup.sh sysinfo.sh domain.sh; do
    download_file "mplus/utils/$util" "$INSTALL_DIR/utils/$util"
done

# ----------- SYSTEM LINK ----------
log "Linking command shortcut..."
ln -sf "$INSTALL_DIR/menu.sh" /usr/bin/mplus
chmod +x /usr/bin/mplus

# ----------- FIREWALL & SECURITY ---
log "Configuring basic firewall and Fail2Ban..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
systemctl enable fail2ban
systemctl start fail2ban

# ----------- VERIFY ---------------
if command -v mplus >/dev/null 2>&1; then
    log "Installation successful! Run 'mplus' to open the interface."
else
    error_exit "Installation incomplete. Check $LOGFILE for details."
fi

cat <<'EOF'

────────────────────────────────────────────
✅ MultiPlus+ Enhanced installed successfully!

Launch menu:
    mplus

Update in future:
    mplus update

Docs & Source:
    https://github.com/Alouk0/multiprotocol-plus
────────────────────────────────────────────
EOF
