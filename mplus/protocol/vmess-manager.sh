#!/bin/bash
# ------------------------------------------------------------
# MultiPlus+ Enhanced - VMESS Manager
# Manage VMESS users on Xray-core
# Author: John Kennedy (Alouk0)
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

CONFIG_FILE="/etc/xray/config.json"
USER_DIR="/etc/xray/users"

green=$(tput setaf 2)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

mkdir -p "$USER_DIR"

menu() {
    clear
    echo -e "${cyan}╔═══════════════════════════════════════╗${reset}"
    echo -e "${cyan}║${yellow}        VMESS USER MANAGEMENT           ${cyan}║${reset}"
    echo -e "${cyan}╚═══════════════════════════════════════╝${reset}"
    echo
    echo "1) Add VMESS User"
    echo "2) Delete VMESS User"
    echo "3) List Users"
    echo "4) Show Config Link"
    echo "5) Restart Xray"
    echo "0) Back to Main Menu"
    echo
    read -rp "Select option [0-5]: " opt
    case $opt in
        1) add_user ;;
        2) delete_user ;;
        3) list_users ;;
        4) show_links ;;
        5) systemctl restart xray && echo "${green}Xray restarted.${reset}" ;;
        0) exit 0 ;;
        *) echo "${red}Invalid choice!${reset}" ;;
    esac
}

add_user() {
    read -rp "Enter username: " username
    UUID=$(cat /proc/sys/kernel/random/uuid)
    PORT=$(grep '"port"' "$CONFIG_FILE" | head -n1 | awk '{print $2}' | tr -d ',')
    DOMAIN=$(grep "server_name" /etc/xray/config.json 2>/dev/null | awk -F'"' '{print $4}')
    [ -z "$DOMAIN" ] && DOMAIN="your-domain.com"

    # Insert new user in config
    jq --arg name "$username" --arg uuid "$UUID" \
      '.inbounds[]?.settings.clients += [{"id": $uuid, "alterId": 0, "email": $name}]' "$CONFIG_FILE" > /tmp/tmp.json
    mv /tmp/tmp.json "$CONFIG_FILE"

    # Generate config link
    LINK="vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"$username\",\"add\":\"$DOMAIN\",\"port\":\"$PORT\",\"id\":\"$UUID\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/ws\",\"type\":\"none\",\"tls\":\"tls\"}" | base64 -w 0)"
    echo "$LINK" > "$USER_DIR/$username.link"

    echo -e "\n${green}User added successfully!${reset}"
    echo -e "VMESS Link: ${yellow}$LINK${reset}\n"
    systemctl restart xray
}

delete_user() {
    read -rp "Enter username to remove: " username
    jq --arg name "$username" \
      '(.inbounds[]?.settings.clients) |= map(select(.email != $name))' "$CONFIG_FILE" > /tmp/tmp.json
    mv /tmp/tmp.json "$CONFIG_FILE"

    rm -f "$USER_DIR/$username.link"
    systemctl restart xray
    echo -e "${red}User '$username' deleted.${reset}"
}

list_users() {
    echo -e "${cyan}Current VMESS Users:${reset}"
    jq -r '.inbounds[]?.settings.clients[].email' "$CONFIG_FILE" | nl || echo "No users found."
}

show_links() {
    echo -e "${yellow}Saved VMESS Links:${reset}"
    for file in "$USER_DIR"/*.link; do
        [ -e "$file" ] || { echo "No saved links."; return; }
        echo -e "\nUser: ${cyan}$(basename "$file" .link)${reset}"
        cat "$file"
        echo
    done
}

menu
