#!/bin/bash
# MultiPlus+ Enhanced — DNS Changer (systemd-resolved / resolv.conf aware)
set -euo pipefail
green=$(tput setaf 2); red=$(tput setaf 1); yellow=$(tput setaf 3); cyan=$(tput setaf 6); reset=$(tput sgr0)

apply_resolved() {
  local dns1="$1" dns2="$2"
  mkdir -p /etc/systemd/resolved.conf.d
  cat >/etc/systemd/resolved.conf <<EOF
[Resolve]
DNS=$dns1 $dns2
FallbackDNS=1.1.1.1 8.8.8.8
DNSStubListener=yes
EOF
  systemctl restart systemd-resolved || true
  ln -sf /run/systemd/resolve/resolv.conf /etc/resolv.conf || true
}

apply_resolvconf() {
  local dns1="$1" dns2="$2"
  cat >/etc/resolv.conf <<EOF
nameserver $dns1
nameserver $dns2
options edns0
EOF
}

menu() {
  clear
  echo -e "${cyan}╔═══════════════════════════════════════╗${reset}"
  echo -e "${cyan}║${yellow}             DNS CHANGER                ${cyan}║${reset}"
  echo -e "${cyan}╚═══════════════════════════════════════╝${reset}\n"
  cat <<EOF
1) Cloudflare      (1.1.1.1, 1.0.0.1)
2) Google          (8.8.8.8, 8.8.4.4)
3) Quad9           (9.9.9.9, 149.112.112.112)
4) AdGuard         (94.140.14.14, 94.140.15.15)
5) OpenDNS         (208.67.222.222, 208.67.220.220)
6) Custom
0) Back
EOF
  echo
  read -rp "Choose [0-6]: " opt
  case "$opt" in
    1) D1=1.1.1.1; D2=1.0.0.1 ;;
    2) D1=8.8.8.8; D2=8.8.4.4 ;;
    3) D1=9.9.9.9; D2=149.112.112.112 ;;
    4) D1=94.140.14.14; D2=94.140.15.15 ;;
    5) D1=208.67.222.222; D2=208.67.220.220 ;;
    6) read -rp "Primary DNS: " D1; read -rp "Secondary DNS: " D2 ;;
    0) exit 0 ;;
    *) echo -e "${red}Invalid.${reset}"; exit 1 ;;
  esac

  if systemctl is-active --quiet systemd-resolved; then
    apply_resolved "$D1" "$D2"
  else
    apply_resolvconf "$D1" "$D2"
  fi
  echo -e "${green}DNS updated to: $D1, $D2${reset}"
  echo "Testing..."
  if command -v dig >/dev/null 2>&1; then
    dig +short example.com @"$D1" || true
  else
    apt-get update -y && apt-get install -y dnsutils
    dig +short example.com @"$D1" || true
  fi
  read -rp "Press Enter to return..."
}

menu
