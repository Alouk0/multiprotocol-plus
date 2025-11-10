#!/bin/bash
# ------------------------------------------------------------
# MultiPlus+ Enhanced - OpenVPN Manager (with WS support)
# Manage OVPN users and configurations
# Author: John Kennedy (Alouk0)
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

OVPN_DIR="/etc/openvpn"
USER_DIR="/etc/openvpn/users"
SERVER_IP=$(hostname -I | awk '{print $1}')
PORT="1194"
WS_PORT="4400"

green=$(tput setaf 2)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

mkdir -p "$USER_DIR"

menu() {
    clear
    echo -e "${cyan}╔═══════════════════════════════════════╗${reset}"
    echo -e "${cyan}║${yellow}        OPENVPN USER MANAGEMENT         ${cyan}║${reset}"
    echo -e "${cyan}╚═══════════════════════════════════════╝${reset}"
    echo
    echo "1) Add OVPN User"
    echo "2) Delete OVPN User"
    echo "3) List Users"
    echo "4) Show Config Files"
    echo "5) Restart OpenVPN"
    echo "0) Back to Main Menu"
    echo
    read -rp "Select option [0-5]: " opt
    case $opt in
        1) add_user ;;
        2) delete_user ;;
        3) list_users ;;
        4) show_configs ;;
        5) systemctl restart openvpn@server && echo "${green}OpenVPN restarted.${reset}" ;;
        0) exit 0 ;;
        *) echo "${red}Invalid choice!${reset}" ;;
    esac
}

add_user() {
    read -rp "Enter username: " username
    CLIENT_DIR="$USER_DIR/$username"
    mkdir -p "$CLIENT_DIR"
    cd "$OVPN_DIR/easy-rsa"

    EASYRSA_BATCH=1 ./easyrsa build-client-full "$username" nopass >/dev/null 2>&1

    cat >"$CLIENT_DIR/$username.ovpn" <<EOF
client
dev tun
proto udp
remote $SERVER_IP $PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3
<ca>
$(cat $OVPN_DIR/ca.crt)
</ca>
<cert>
$(cat $OVPN_DIR/easy-rsa/pki/issued/$username.crt)
</cert>
<key>
$(cat $OVPN_DIR/easy-rsa/pki/private/$username.key)
</key>
<tls-crypt>
$(cat $OVPN_DIR/ta.key)
</tls-crypt>
EOF

    echo -e "\n${green}User added successfully!${reset}"
    echo -e "Config: ${yellow}$CLIENT_DIR/$username.ovpn${reset}"
}

delete_user() {
    read -rp "Enter username to delete: " username
    CLIENT_DIR="$USER_DIR/$username"
    if [ -d "$CLIENT_DIR" ]; then
        EASYRSA_BATCH=1 "$OVPN_DIR/easy-rsa/easyrsa" revoke "$username" >/dev/null 2>&1
        EASYRSA_BATCH=1 "$OVPN_DIR/easy-rsa/easyrsa" gen-crl >/dev/null 2>&1
        rm -rf "$CLIENT_DIR"
        echo -e "${red}User '$username' removed.${reset}"
    else
        echo -e "${red}User not found.${reset}"
    fi
}

list_users() {
    echo -e "${cyan}Current OpenVPN Users:${reset}"
    ls "$USER_DIR" | nl || echo "No users found."
}

show_configs() {
    echo -e "${yellow}Saved OVPN Configs:${reset}"
    find "$USER_DIR" -type f -name "*.ovpn" || echo "No configs available."
}

menu
