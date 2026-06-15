#!/bin/bash

RED='\033[38;5;196m'
PURPLE='\033[38;5;141m'
GREEN='\033[38;5;82m'
NC='\033[0m'

echo -e "  ${RED}WARNING: This will remove Webmin/Virtualmin!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GREEN}Cancelled.${NC}"; exit; }

echo -e "  ${PURPLE}::${NC} Removing Webmin..."
apt remove --purge -y webmin virtualmin*
rm -f /etc/apt/sources.list.d/webmin*
rm -f /usr/share/keyrings/webmin*

echo -e "  ${GREEN}[OK]${NC} Webmin removed."
