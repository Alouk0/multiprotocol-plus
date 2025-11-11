#!/bin/bash
set -euo pipefail

# Colour codes
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[1;33m'
cyan='\033[0;36m'
reset='\033[0m'

echo -e "${cyan}═══════════════════════════════════════════════════════${reset}"
echo -e "${yellow}   MultiPlus+ Enhanced - Developer Sanity Check Tool    ${reset}"
echo -e "${cyan}═══════════════════════════════════════════════════════${reset}\n"

TOTAL=0
OK=0
FAIL=0

for file in $(find . -type f -name "*.sh" | sort); do
  ((TOTAL++))
  short="${file#./}"
  if bash -n "$file" 2>/tmp/devcheck_err; then
    echo -e "OK: ${green}$short${reset}"
    ((OK++))
  else
    echo -e "ERROR: ${red}$short${reset}"
    sed 's/^/   > /' /tmp/devcheck_err
    ((FAIL++))
  fi
done

echo
echo -e "${cyan}═══════════════════════════════════════════════════════${reset}"
echo -e "${yellow}Files checked:${reset} $TOTAL"
echo -e "${green}Pass:${reset} $OK  ${red}Fail:${reset} $FAIL"
echo -e "${cyan}═══════════════════════════════════════════════════════${reset}"
