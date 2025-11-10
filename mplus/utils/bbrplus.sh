#!/bin/bash
# MultiPlus+ Enhanced — Enable BBR / network tuning
set -euo pipefail
green=$(tput setaf 2); red=$(tput setaf 1); yellow=$(tput setaf 3); cyan=$(tput setaf 6); reset=$(tput sgr0)

echo -e "${cyan}Enabling BBR and tuning sysctl...${reset}"
cat >/etc/sysctl.d/99-mplus-bbr.conf <<'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
net.ipv4.ip_forward=1
fs.file-max=1000000
EOF
sysctl --system >/dev/null
echo -e "${green}Applied. Current CC:${reset} $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
