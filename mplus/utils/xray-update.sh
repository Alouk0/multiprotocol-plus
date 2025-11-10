#!/bin/bash
# MultiPlus+ Enhanced — Xray Core Updater
set -euo pipefail
green=$(tput setaf 2); red=$(tput setaf 1); yellow=$(tput setaf 3); cyan=$(tput setaf 6); reset=$(tput sgr0)

TMP=/tmp/xray-update
mkdir -p "$TMP"

echo -e "${cyan}Checking and installing latest Xray core...${reset}"
systemctl stop xray || true
wget -q -O "$TMP/xray.zip" https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip || {
  echo -e "${red}Download failed.${reset}"; exit 1; }
unzip -oq "$TMP/xray.zip" -d "$TMP"
install -m 755 "$TMP/xray" /usr/local/bin/xray
systemctl daemon-reload
systemctl start xray
systemctl is-active --quiet xray && echo -e "${green}Xray updated & running.${reset}" || echo -e "${red}Xray failed to start.${reset}"
