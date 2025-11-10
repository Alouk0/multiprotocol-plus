#!/bin/bash
# ------------------------------------------------------------
# MultiPlus+ Enhanced - TROJAN Manager
# Manage Trojan-Go users
# Author: John Kennedy (Alouk0)
# ------------------------------------------------------------

set -euo pipefail
IFS=$'\n\t'

CONFIG_FILE="/etc/trojan-go/config.json"
USER_DIR="/etc/trojan-go/users"

green=$(tput setaf 2)
red=$(tput setaf 1)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

mkdir -p "$USER_DIR"

menu() {
    clear
    echo -e "${cyan}╔═══════════════════════════════════════╗${reset}"
    echo -e "${cyan}║${yellow}          TROJAN USER MANAGEMENT         ${cyan}║${reset}"
    echo -e "${cyan}╚═══════════════════════════════════════╝${reset}"
    echo
    echo "1) Add Trojan User"
    echo "2) Delete Trojan User"
    echo "3) List Users"
    echo "4) Show Connection Links"
    echo "5) Restart Trojan-Go"
    echo "0) Back to Main Menu"
    echo
    read -rp "Select option [0-5]: " opt
    case $opt in
        1) add_user ;;
        2) delete_user ;;
        3) list_users ;;
        4) show_links ;;
        5) systemctl restart trojan-go && echo "${green}Trojan-Go restarted.${reset}" ;;
        0) exit 0 ;;
        *) echo "${red}Invalid choice!${reset}" ;;
    esac
}

add_user() {
    read -rp "Enter username: " username
    PASSWORD=$(openssl rand -hex 8)
    DOMAIN=$(grep "cert" "$CONFIG_FILE" | head -n1 | awk -F'"' '{print $4}')
    DOMAIN=${DOMAIN:-"your-domain.com"}
    PORT=$(grep "local_port" "$CONFIG_FILE" | awk '{print $2}' | tr -d ',')
    [ -z "$PORT" ] && PORT=443

    # Add user to config
    jq --arg pw "$PASSWORD" --arg name "$username" \
      '.password += [$pw]' "$CONFIG_FILE" > /tmp/tmp.json
    mv /tmp/tmp.json "$CONFIG_FILE"

    LINK="trojan://${PASSWORD}@${DOMAIN}:${PORT}?security=tls&type=tcp#${username}"
    echo "$LINK" > "$USER_DIR/$username.link"

    echo -e "\n${green}User added successfully!${reset}"
    echo -e "Trojan Link: ${yellow}$LINK${reset}\n"
    systemctl restart trojan-go
}

delete_user() {
    read -rp "Enter username to remove: " username
    if [ -f "$USER_DIR/$username.link" ]; then
        PASSWORD=$(cat "$USER_DIR/$username.link" | cut -d'/' -f3 | cut -d'@' -f1)
        jq --arg pw "$PASSWORD" '.password -= [$pw]' "$CONFIG_FILE" > /tmp/tmp.json
        mv /tmp/tmp.json "$CONFIG_FILE"
        rm -f "$USER_DIR/$username.link"
        systemctl restart trojan-go
        echo -e "${red}User '$username' removed.${reset}"
    else
        echo -e "${red}User not found.${reset}"
    fi
}

list_users() {
    echo -e "${cyan}Active Trojan Users:${reset}"
    jq -r '.password[]' "$CONFIG_FILE" | nl || echo "No users found."
}

show_links() {
    echo -e "${yellow}Saved Trojan Links:${reset}"
    for file in "$USER_DIR"/*.link; do
        [ -e "$file" ] || { echo "No saved links."; return; }
        echo -e "\nUser: ${cyan}$(basename "$file" .link)${reset}"
        cat "$file"
        echo
    done
}

menu
