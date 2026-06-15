#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${RED}  WARNING: This will remove all Skyport panel data!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GRAY}Cancelled.${NC}"; exit; }

echo -e "  ${GRAY}Stopping services...${NC}"
systemctl stop skyport-panel skyport-queue skyport-ssr 2>/dev/null || true
systemctl disable skyport-panel skyport-queue skyport-ssr 2>/dev/null || true

rm -f /etc/systemd/system/skyport-panel.service
rm -f /etc/systemd/system/skyport-queue.service
rm -f /etc/systemd/system/skyport-ssr.service
systemctl daemon-reload

echo -e "  ${GRAY}Removing panel files...${NC}"
rm -rf /var/www/skyport

echo -e "  ${GRAY}Removing Nginx config...${NC}"
rm -f /etc/nginx/sites-enabled/skyport.conf
rm -f /etc/nginx/sites-available/skyport.conf
systemctl reload nginx 2>/dev/null || true

echo -e "  ${GREEN}[OK]${NC} Skyport panel removed."
