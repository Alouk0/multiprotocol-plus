#!/bin/bash
# MultiPlus+ Enhanced — System Info
set -euo pipefail
red=$(tput setaf 1); green=$(tput setaf 2); yellow=$(tput setaf 3); cyan=$(tput setaf 6); reset=$(tput sgr0)

clear
HOST=$(hostname)
OS=$(lsb_release -d 2>/dev/null | cut -f2 || echo "$(grep PRETTY_NAME /etc/os-release | cut -d= -f2 | tr -d '"')")
KERNEL=$(uname -r)
IPV4=$(hostname -I | awk '{print $1}')
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(cut -d " " -f1-3 /proc/loadavg)
CPU=$(awk -F: '/model name/ {print $2; exit}' /proc/cpuinfo | sed 's/^[ \t]*//')
CPU_CORES=$(nproc)
MEM_USED=$(free -h | awk '/Mem:/ {print $3}')
MEM_TOTAL=$(free -h | awk '/Mem:/ {print $2}')
DISK_USED=$(df -h / | awk 'NR==2{print $3}')
DISK_TOTAL=$(df -h / | awk 'NR==2{print $2}')

echo -e "${cyan}╔══════════════════════════════════════════════════╗${reset}"
echo -e "${cyan}║${yellow}               SYSTEM INFORMATION                  ${cyan}║${reset}"
echo -e "${cyan}╚══════════════════════════════════════════════════╝${reset}\n"

printf "${green}Host:${reset}    %s\n" "$HOST"
printf "${green}OS:${reset}      %s\n" "$OS"
printf "${green}Kernel:${reset}  %s\n" "$KERNEL"
printf "${green}IP(v4):${reset}  %s\n" "$IPV4"
printf "${green}Uptime:${reset}  %s\n" "$UPTIME"
printf "${green}Load:${reset}    %s\n" "$LOAD"
printf "${green}CPU:${reset}     %s (%s cores)\n" "$CPU" "$CPU_CORES"
printf "${green}RAM:${reset}     %s / %s\n" "$MEM_USED" "$MEM_TOTAL"
printf "${green}Disk:${reset}    %s / %s (root)\n\n" "$DISK_USED" "$DISK_TOTAL"

echo -e "${yellow}Open TCP/UDP ports:${reset}"
ss -tulpen | awk 'NR==1 || /LISTEN|UNCONN/ {print}'
echo
read -rp "Press Enter to return..."
