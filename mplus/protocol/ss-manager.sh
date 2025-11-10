#!/bin/bash
# ------------------------------------------------------------
# MultiPlus+ Enhanced - SHADOWSOCKS Manager
# Manage Shadowsocks-libev users
# Author: John Kennedy (Alouk0)
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

CONFIG_FILE="/etc/shadowsocks-libev/config.json"
USER_DIR="/etc/shadowsocks-libev/users"

green=$(tput setaf 2)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

mkdir -p "$USER_DIR"

menu() {
    clear
    echo -e "${cyan}╔═══════════════════════════════════════╗${reset}"
    echo -e "${cyan}║${yellow}      SHADOWSOCKS USER MANAGEMENT        ${cyan}║${reset}"
    echo -e "${cyan}╚═══════════════════════════════════════╝${reset}"
    echo
    echo "1) Add Shadowsocks User"
    echo "2) Delete User"
    echo "3) List Users"
    echo "4) Show Connection Links"
    echo "5) Restart Service"
    echo "0) Back to Main Menu"
    echo
    read -rp "Select option [0-5]: " opt
    case $opt in
        1) add_user ;;
        2) delete_user ;;
        3) list_users ;;
        4) show_links ;;
        5) systemctl restart shadowsocks-libev && echo "${green}Shadowsocks restarted.${reset}" ;;
        0) exit 0 ;;
        *) echo "${red}Invalid choice!${reset}" ;;
    esac
}

add_user() {
    read -rp "Enter username: " username
    PASSWORD=$(openssl rand -base64 8)
    METHOD="aes-256-gcm"
    PORT=$((RANDOM % 20000 + 10000))

    mkdir -p /etc/shadowsocks-libev/instances
    CONFIG_PATH="/etc/shadowsocks-libev/instances/${username}.json"

    cat >"$CONFIG_PATH" <<EOF
{
    "server":"0.0.0.0",
    "server_port":$PORT,
    "password":"$PASSWORD",
    "timeout":300,
    "method":"$METHOD",
    "fast_open":true
}
EOF

    systemctl stop shadowsocks-libev
    nohup ss-server -c "$CONFIG_PATH" -u >/dev/null 2>&1 &
    echo "$PORT $PASSWORD $METHOD" > "$USER_DIR/$username.info"

    SERVER_IP=$(hostname -I | awk '{print $1}')
    LINK="ss://$(echo -n "$METHOD:$PASSWORD" | base64 -w 0)@$SERVER_IP:$PORT#${username}"
    echo "$LINK" > "$USER_DIR/$username.link"

    echo -e "\n${green}User added successfully!${reset}"
    echo -e "SS Link: ${yellow}$LINK${reset}\n"
}

delete_user() {
    read -rp "Enter username to delete: " username
    CONFIG_PATH="/etc/shadowsocks-libev/instances/${username}.json"
    if [ -f "$CONFIG_PATH" ]; then
        rm -f "$CONFIG_PATH" "$USER_DIR/$username.info" "$USER_DIR/$username.link"
        pkill -f "$CONFIG_PATH" || true
        echo -e "${red}User '$username' removed.${reset}"
    else
        echo -e "${red}User not found.${reset}"
    fi
}

list_users() {
    echo -e "${cyan}Active Shadowsocks Users:${reset}"
    ls "$USER_DIR"/*.info 2>/dev/null | xargs -n1 basename | sed 's/.info//' || echo "No users found."
}

show_links() {
    echo -e "${yellow}Saved SS Links:${reset}"
    for file in "$USER_DIR"/*.link; do
        [ -e "$file" ] || { echo "No saved links."; return; }
        echo -e "\nUser: ${cyan}$(basename "$file" .link)${reset}"
        cat "$file"
        echo
    done
}

menu
