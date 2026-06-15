#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'
HEADER_LINE="${GRAY}────────────────────────────────────────────────────────────${NC}"

echo -e "${GOLD}"
cat << "EOF"
   ____  _                    ____    _
  |  _ \| |_ ___ _ __ ___   / ___|  / \
  | |_) | __/ _ \ '__/ _ \ | |     / _ \
  |  __/| ||  __/ | | (_) || |___ / ___ \
  |_|    \__\___|_|  \___/  \____/_/   \_\
EOF
echo -e "${NC}"
echo -e "           ${WHITE}PTEROCA INSTALLER${NC}"
echo -e "${HEADER_LINE}"

echo -e "\n  ${GOLD}PteroCA uses its own comprehensive auto-installer.${NC}"
echo -e "  ${GOLD}This will download and run the official installer from pteroca.com${NC}"
echo ""

while true; do
    echo -ne "  ${CYAN}Continue?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

bash -c "$(wget -qO- https://pteroca.com/installer.sh)"
