#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

INSTALL_DIR="/var/www/hydra"

if ! command -v pufferpanel &> /dev/null; then
    echo -e "  ${RED}[ERR]${NC} PufferPanel not installed."
    exit 1
fi

echo -e "  ${GRAY}Updating PufferPanel package...${NC}"
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y --only-upgrade pufferpanel
echo -e "  ${GREEN}[OK]${NC} Package updated"

systemctl restart pufferpanel
echo -e "  ${GREEN}[OK]${NC} Service restarted"
echo ""
echo -e "  ${GREEN}PufferPanel updated successfully.${NC}"
