#!/bin/bash
# ------------------------------------------------------------
# MultiPlus+ Enhanced — Dev Testing Script
# Scans all .sh files for syntax, permissions, and consistency
# Author: John Kennedy (Alouk0)
# ------------------------------------------------------------

set -euo pipefail
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
cyan=$(tput setaf 6)
reset=$(tput sgr0)

ROOT_DIR="$(dirname "$(realpath "$0")")/../.."
echo -e "${cyan}═══════════════════════════════════════════════════════${reset}"
echo -e "${yellow}   MultiPlus+ Enhanced - Developer Sanity Check Tool    ${reset}"
echo -e "${cyan}═══════════════════════════════════════════════════════${reset}"
echo
cd "$ROOT_DIR"

TOTAL=0
OK=0
FAIL=0

find . -type f -name "*.sh" | while read -r file; do
    ((TOTAL++))
    short="${file#./}"

    # Check if file is empty
    if [ ! -s "$file" ]; then
        echo -e "❌ ${red}EMPTY FILE:${reset} $short"
        ((FAIL++))
        continue
    fi

    # Check shebang
    if ! head -n1 "$file" | grep -qE '^#! */bin/(bash|sh)'; then
        echo -e "⚠️  ${yellow}Missing shebang:${reset} $short"
    fi

    # Check syntax
    if ! bash -n "$file" 2>/tmp/devcheck_err; then
        echo -e "❌ ${red}Syntax error:${reset} $short"
        sed 's/^/   > /' /tmp/devcheck_err
        ((FAIL++))
        continue
    fi

    # Check executable bit
    if [ ! -x "$file" ]; then
        echo -e "⚠️  ${yellow}Not executable:${reset} $short (use chmod +x)"
    fi

    # Check for CRLF (Windows line endings)
    if file "$file" | grep -q "CRLF"; then
        echo -e "⚠️  ${yellow}Windows line endings detected:${reset} $short"
    fi

    echo -e "✅ ${green}OK:${reset} $short"
    ((OK++))
done

echo
echo -e "${cyan}═══════════════════════════════════════════════════════${reset}"
echo -e "${yellow}Files checked:${reset} $TOTAL"
echo -e "${green}Pass:${reset} $OK  ${red}Fail:${reset} $FAIL"
echo -e "${cyan}═══════════════════════════════════════════════════════${reset}"

if [ "$FAIL" -gt 0 ]; then
    echo -e "\n${red}Some files failed the checks! Fix them before committing.${reset}"
    exit 1
else
    echo -e "\n${green}All scripts look good. Safe to commit.${reset}"
fi
