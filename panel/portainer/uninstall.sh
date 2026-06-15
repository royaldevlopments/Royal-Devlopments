#!/bin/bash

PURPLE='\033[38;5;141m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

echo -e "  ${RED}WARNING: This will remove Portainer and all its data!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GREEN}Cancelled.${NC}"; exit; }

echo -e "  ${PURPLE}::${NC} Stopping and removing Portainer..."
docker stop portainer 2>/dev/null || true
docker rm portainer 2>/dev/null || true
docker volume rm portainer_data 2>/dev/null || true

echo -e "  ${PURPLE}::${NC} Cleaning Nginx configs..."
rm -f /etc/nginx/sites-enabled/portainer.conf /etc/nginx/sites-available/portainer.conf
systemctl reload nginx 2>/dev/null || true
rm -f /etc/certs/portainer/fullchain.pem /etc/certs/portainer/privkey.pem 2>/dev/null || true
rmdir /etc/certs/portainer 2>/dev/null || true

echo -e "  ${GREEN}[OK]${NC} Portainer removed."
