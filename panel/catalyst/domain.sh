#!/bin/bash

CYAN='\033[38;5;51m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'

INSTALL_DIR="/opt/catalyst-docker"

echo -e "  ${GOLD}Catalyst Domain / SSL${NC}"
echo ""

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "  ${RED}Catalyst not installed.${NC}"
    exit 1
fi

cd "$INSTALL_DIR" || exit 1

read -p "  New domain (e.g. panel.example.com): " DOMAIN
[ -z "$DOMAIN" ] && { echo -e "  ${RED}Cancelled.${NC}"; exit; }

sed -i "s~^PUBLIC_URL=.*~PUBLIC_URL=https://${DOMAIN}~" .env
sed -i "s~^PASSKEY_RP_ID=.*~PASSKEY_RP_ID=${DOMAIN}~" .env
sed -i "s~^NODE_ENV=.*~NODE_ENV=production~" .env
grep -q "^DOMAIN=" .env && sed -i "s~^DOMAIN=.*~DOMAIN=${DOMAIN}~" .env || echo "DOMAIN=${DOMAIN}" >> .env

echo ""
echo -e "  ${GREEN}[OK]${NC} Domain updated to https://$DOMAIN"
echo ""
echo -e "  ${GRAY}For TLS, restart with Caddy overlay:${NC}"
echo -e "  ${WHITE}cd $INSTALL_DIR && docker compose -f docker-compose.yml -f docker-compose.caddy.yml up -d${NC}"
echo ""
echo -e "  ${GRAY}Or use a reverse proxy (Nginx/Caddy) pointing to port 8080.${NC}"
