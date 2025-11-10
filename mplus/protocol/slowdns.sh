#!/bin/bash
# ------------------------------------------------------------
# MultiPlus+ Enhanced - SlowDNS Manager
# Manage SlowDNS tunnel server
# Author: John Kennedy (Alouk0)
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

SLOWDNS_BIN="/usr/local/bin/slowdns"
SERVICE_FILE="/etc/systemd/system/slowdns.service"
PORT="5300"
USER_DIR="/etc/slowdns"

green=$(tput setaf 2)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

mkdir -p "$USER_DIR"

menu() {
    clear
    echo -e "${cyan}╔═══════════════════════════════════════╗${reset}"
    echo -e "${cyan}║${yellow}          SLOWDNS SERVER MANAGER        ${cyan}║${reset}"
    echo -e "${cyan}╚═══════════════════════════════════════╝${reset}"
    echo
    echo "1) Install / Start SlowDNS"
    echo "2) Stop SlowDNS"
    echo "3) View Logs"
    echo "4) Restart Service"
    echo "0) Back to Main Menu"
    echo
    read -rp "Select option [0-4]: " opt
    case $opt in
        1) install_slowdns ;;
        2) systemctl stop slowdns && echo "${red}SlowDNS stopped.${reset}" ;;
        3) journalctl -u slowdns -n 50 --no-pager ;;
        4) systemctl restart slowdns && echo "${green}SlowDNS restarted.${reset}" ;;
        0) exit 0 ;;
        *) echo "${red}Invalid choice!${reset}" ;;
    esac
}

install_slowdns() {
    log="${USER_DIR}/install.log"
    if [ ! -f "$SLOWDNS_BIN" ]; then
        echo -e "${cyan}Installing SlowDNS binary...${reset}"
        wget -q -O "$SLOWDNS_BIN" "https://github.com/andrivet/slowdns/releases/latest/download/slowdns-linux-amd64" || {
            echo "${red}Download failed. Please check link.${reset}"
            exit 1
        }
        chmod +x "$SLOWDNS_BIN"
    fi

    echo -e "${cyan}Configuring SlowDNS service...${reset}"
    PASSWORD=$(openssl rand -base64 12)
    echo "$PASSWORD" > "$USER_DIR/password.txt"

    cat >"$SERVICE_FILE" <<EOF
[Unit]
Description=SlowDNS Tunnel Server
After=network.target

[Service]
ExecStart=$SLOWDNS_BIN server -p $PORT -k $PASSWORD
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable slowdns
    systemctl start slowdns

    echo -e "\n${green}SlowDNS started successfully!${reset}"
    echo -e "Port: ${yellow}$PORT${reset}"
    echo -e "Password: ${yellow}$PASSWORD${reset}"
    echo -e "Binary: ${cyan}$SLOWDNS_BIN${reset}"
}

menu
