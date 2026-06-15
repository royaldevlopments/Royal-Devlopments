#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

INSTALL_DIR="/var/www/hydra"

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "  ${RED}[ERR]${NC} HydraPanel not found."
    exit 1
fi

cd "$INSTALL_DIR"

echo -e "  ${GRAY}Pulling latest code...${NC}"
git fetch --all --tags
git reset --hard origin/main
echo -e "  ${GREEN}[OK]${NC} Code updated"

npm install --production
echo -e "  ${GREEN}[OK]${NC} npm deps updated"

systemctl restart hydrapanel
echo -e "  ${GREEN}[OK]${NC} Service restarted"
echo ""
echo -e "  ${GREEN}HydraPanel updated successfully.${NC}"
