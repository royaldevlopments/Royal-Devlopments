#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${RED}  WARNING: This will remove PufferPanel!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GRAY}Cancelled.${NC}"; exit; }

systemctl stop pufferpanel 2>/dev/null || true
systemctl disable pufferpanel 2>/dev/null || true
DEBIAN_FRONTEND=noninteractive apt-get remove -y pufferpanel

rm -f /etc/nginx/sites-enabled/puffer.conf /etc/nginx/sites-available/puffer.conf
systemctl reload nginx 2>/dev/null || true

echo -e "  ${GREEN}[OK]${NC} PufferPanel removed."
