#!/bin/bash
# ------------------------------------------------------------
# MultiPlus+ Enhanced - UDPCustom Manager
# Manage udp2raw and UDPspeeder tunneling
# Author: John Kennedy (Alouk0)
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

BASE_DIR="/etc/udpcustom"
UDP2RAW_BIN="/usr/local/bin/udp2raw"
UDPSPEEDER_BIN="/usr/local/bin/speederv2"
SERVICE_FILE="/etc/systemd/system/udpcustom.service"

green=$(tput setaf 2)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

mkdir -p "$BASE_DIR"

menu() {
    clear
    echo -e "${cyan}╔═══════════════════════════════════════════╗${reset}"
    echo -e "${cyan}║${yellow}          UDPCUSTOM TUNNEL MANAGER          ${cyan}║${reset}"
    echo -e "${cyan}╚═══════════════════════════════════════════╝${reset}"
    echo
    echo "1) Install UDPCustom (udp2raw + UDPspeeder)"
    echo "2) Start Tunnel"
    echo "3) Stop Tunnel"
    echo "4) View Logs"
    echo "5) Restart Service"
    echo "0) Back to Main Menu"
    echo
    read -rp "Select option [0-5]: " opt
    case $opt in
        1) install_udpcustom ;;
        2) start_tunnel ;;
        3) stop_tunnel ;;
        4) tail -f /var/log/udpcustom.log ;;
        5) systemctl restart udpcustom && echo "${green}UDPCustom restarted.${reset}" ;;
        0) exit 0 ;;
        *) echo "${red}Invalid choice!${reset}" ;;
    esac
}

install_udpcustom() {
    log_file="/var/log/udpcustom.log"
    echo -e "${cyan}Installing udp2raw and UDPspeeder...${reset}"

    # --- udp2raw installation ---
    if [ ! -f "$UDP2RAW_BIN" ]; then
        wget -q -O /tmp/udp2raw.tar.gz https://github.com/wangyu-/udp2raw-tunnel/releases/latest/download/udp2raw_binaries.tar.gz
        tar -xzf /tmp/udp2raw.tar.gz -C /tmp
        cp /tmp/udp2raw_*_amd64/udp2raw_amd64 "$UDP2RAW_BIN"
        chmod +x "$UDP2RAW_BIN"
    fi

    # --- UDPspeeder installation ---
    if [ ! -f "$UDPSPEEDER_BIN" ]; then
        wget -q -O /tmp/speederv2.tar.gz https://github.com/wangyu-/UDPspeeder/releases/latest/download/speederv2_binaries.tar.gz
        tar -xzf /tmp/speederv2.tar.gz -C /tmp
        cp /tmp/speederv2_*_amd64/speederv2_amd64 "$UDPSPEEDER_BIN"
        chmod +x "$UDPSPEEDER_BIN"
    fi

    echo -e "${green}UDP2Raw and UDPspeeder installed successfully.${reset}"

    # --- Create default config ---
    cat >"$BASE_DIR/config.conf" <<EOF
# UDPCustom default config
# Modify manually or via the menu
UDPSPEEDER_PORT=4096
UDP2RAW_PORT=4000
UDPSPEEDER_KEY=$(openssl rand -base64 8)
UDP2RAW_KEY=$(openssl rand -base64 8)
UDPSPEEDER_MODE=0
EOF

    echo -e "${green}Configuration file created at $BASE_DIR/config.conf${reset}"
}

start_tunnel() {
    if [ ! -f "$BASE_DIR/config.conf" ]; then
        echo -e "${red}No configuration file found. Please install first.${reset}"
        return
    fi

    source "$BASE_DIR/config.conf"
    echo -e "${cyan}Starting UDPspeeder and udp2raw...${reset}"

    # Stop previous instances
    pkill -f udp2raw || true
    pkill -f speederv2 || true

    # Start services
    nohup "$UDPSPEEDER_BIN" -s -l0.0.0.0:$UDPSPEEDER_PORT -r127.0.0.1:7777 -k "$UDPSPEEDER_KEY" -f20:10 --mode "$UDPSPEEDER_MODE" >/var/log/udpcustom.log 2>&1 &
    nohup "$UDP2RAW_BIN" -s -l0.0.0.0:$UDP2RAW_PORT -r127.0.0.1:$UDPSPEEDER_PORT -k "$UDP2RAW_KEY" --raw-mode faketcp >/var/log/udpcustom.log 2>&1 &

    cat >"$SERVICE_FILE" <<EOF
[Unit]
Description=UDPCustom Tunnel
After=network.target

[Service]
ExecStart=/bin/bash -c '$UDPSPEEDER_BIN -s -l0.0.0.0:$UDPSPEEDER_PORT -r127.0.0.1:7777 -k $UDPSPEEDER_KEY -f20:10 --mode $UDPSPEEDER_MODE &
                         $UDP2RAW_BIN -s -l0.0.0.0:$UDP2RAW_PORT -r127.0.0.1:$UDPSPEEDER_PORT -k $UDP2RAW_KEY --raw-mode faketcp'
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable udpcustom
    systemctl restart udpcustom

    echo -e "\n${green}UDPCustom started successfully!${reset}"
    echo -e "UDPspeeder Port: ${yellow}$UDPSPEEDER_PORT${reset}"
    echo -e "udp2raw Port: ${yellow}$UDP2RAW_PORT${reset}"
    echo -e "Keys: ${cyan}$UDPSPEEDER_KEY / $UDP2RAW_KEY${reset}"
}

stop_tunnel() {
    pkill -f udp2raw || true
    pkill -f speederv2 || true
    systemctl stop udpcustom || true
    echo -e "${red}UDPCustom tunnel stopped.${reset}"
}

menu
