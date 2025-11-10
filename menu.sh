#!/bin/bash
# ------------------------------------------------------------
# MultiPlus+ Enhanced
# Interactive Multi-Protocol Manager Dashboard
# Author: John Kennedy (Alouk0)
# Version: 2.0
# ------------------------------------------------------------

# --- Color Setup ---
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
bold=$(tput bold)
reset=$(tput sgr0)

clear
tput civis

# --- Header ---
echo -e "${cyan}╔══════════════════════════════════════════════════════════════╗${reset}"
echo -e "${cyan}║${yellow}${bold}                MULTIPLUS+ ENHANCED MANAGER                    ${cyan}║${reset}"
echo -e "${cyan}╚══════════════════════════════════════════════════════════════╝${reset}"
echo

# --- System Info ---
OS=$(lsb_release -d 2>/dev/null | cut -f2)
KERNEL=$(uname -r)
IP=$(hostname -I | awk '{print $1}')
UPTIME=$(uptime -p | sed 's/up //')

echo -e "${green}System Info${reset}"
echo -e "  OS       : ${yellow}${OS}${reset}"
echo -e "  Kernel   : ${yellow}${KERNEL}${reset}"
echo -e "  IP Addr  : ${yellow}${IP}${reset}"
echo -e "  Uptime   : ${yellow}${UPTIME}${reset}"
echo

# --- Protocol Status ---
printf "${cyan}╔══════════════════════════════════════════╗${reset}\n"
printf "${cyan}║${yellow}        INSTALLED PROTOCOL STATUS          ${cyan}║${reset}\n"
printf "${cyan}╚══════════════════════════════════════════╝${reset}\n"
printf "%-15s %-10s %-10s\n" "Service" "Status" "Port"
echo "-----------------------------------------------"

for svc in ssh xray trojan-go shadowsocks-libev openvpn; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        port=$(ss -tuln | grep "$svc" | awk '{print $5}' | cut -d: -f2 | head -n1)
        printf "%-15s ${green}%-10s${reset} %-10s\n" "$svc" "Running" "${port:-N/A}"
    else
        printf "%-15s ${red}%-10s${reset} %-10s\n" "$svc" "Stopped" "-"
    fi
done
echo

# --- Menu Options ---
cat <<EOF
${cyan}╔════════════════════════════════════════════════════════╗
║${yellow}                     MAIN MENU OPTIONS                   ${cyan}║
╚════════════════════════════════════════════════════════╝${reset}

 1. SSH / OVPN Manager          11. Change Domain
 2. VMESS Manager               12. Change Banner
 3. VLESS Manager               13. Restart Service
 4. TROJAN Manager              14. Restart Server
 5. SHDWKS Manager              15. DNS Changer
 6. RUNNING System Info         16. Netflix Checker
 7. BACKUP & Restore            17. XrayCore Updater
 8. PORT VPS Info               18. Install BBRPlus
 9. LOAD VPS Info               19. Install UDP Custom
10. SpeedTest                   20. Exit

${cyan}══════════════════════════════════════════════════════════${reset}
EOF

read -rp "Select from Options [1-20]: " opt
echo

# --- Dispatcher ---
case $opt in
  1) bash /usr/local/bin/mplus/protocol/ovpn-manager.sh ;;
  2) bash /usr/local/bin/mplus/protocol/vmess-manager.sh ;;
  3) bash /usr/local/bin/mplus/protocol/vless-manager.sh ;;
  4) bash /usr/local/bin/mplus/protocol/trojan-manager.sh ;;
  5) bash /usr/local/bin/mplus/protocol/ss-manager.sh ;;
  6) bash /usr/local/bin/mplus/utils/sysinfo.sh ;;
  7) bash /usr/local/bin/mplus/utils/backup.sh ;;
  8) bash /usr/local/bin/mplus/utils/sysinfo.sh ;;
  9) bash /usr/local/bin/mplus/utils/sysinfo.sh ;;
 10) speedtest || (apt install -y speedtest-cli && speedtest-cli) ;;
 11) bash /usr/local/bin/mplus/utils/domain.sh ;;
 12) nano /etc/mplus/banner.txt ;;
 13) systemctl restart xray trojan-go shadowsocks-libev openvpn ;;
 14) reboot ;;
 15) bash /usr/local/bin/mplus/utils/dnschanger.sh ;;
 16) bash /usr/local/bin/mplus/utils/netflix-checker.sh ;;
 17) bash /usr/local/bin/mplus/utils/xray-update.sh ;;
 18) bash /usr/local/bin/mplus/utils/bbrplus.sh ;;
 19) bash /usr/local/bin/mplus/protocol/udpcustom.sh ;;
 20) tput cnorm; clear; exit 0 ;;
  *) echo -e "${red}Invalid option!${reset}"; sleep 1 ;;
esac

tput cnorm
