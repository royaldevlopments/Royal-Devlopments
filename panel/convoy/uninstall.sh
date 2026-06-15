#!/bin/bash

RED='\033[38;5;196m'
PURPLE='\033[38;5;141m'
GREEN='\033[38;5;82m'
NC='\033[0m'

echo -e "  ${RED}WARNING: This will remove ConvoyPanel and all its data!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GREEN}Cancelled.${NC}"; exit; }

echo -e "  ${PURPLE}::${NC} Stopping containers..."
cd /opt/convoy/panel 2>/dev/null && docker compose down -v

echo -e "  ${PURPLE}::${NC} Removing files..."
rm -rf /opt/convoy

echo -e "  ${PURPLE}::${NC} Cleaning Nginx configs..."
rm -f /etc/nginx/sites-enabled/convoy.conf /etc/nginx/sites-available/convoy.conf
systemctl reload nginx 2>/dev/null || true
rm -f /etc/certs/convoy/fullchain.pem /etc/certs/convoy/privkey.pem 2>/dev/null || true
rmdir /etc/certs/convoy 2>/dev/null || true

echo -e "  ${GREEN}[OK]${NC} ConvoyPanel removed."
