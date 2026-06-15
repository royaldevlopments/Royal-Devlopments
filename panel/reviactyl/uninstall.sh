#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${RED}  WARNING: This will remove all Reviactyl panel data!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GRAY}Cancelled.${NC}"; exit; }

echo -e "  ${GRAY}Stopping services...${NC}"
systemctl stop reviq.service 2>/dev/null || true
systemctl disable reviq.service 2>/dev/null || true
rm -f /etc/systemd/system/reviq.service
systemctl daemon-reload

echo -e "  ${GRAY}Removing panel files...${NC}"
rm -rf /var/www/reviactyl

echo -e "  ${GRAY}Dropping database...${NC}"
mysql -u root -e "DROP DATABASE IF EXISTS reviactyl; DROP USER IF EXISTS 'reviactyl'@'127.0.0.1'; FLUSH PRIVILEGES;"

echo -e "  ${GRAY}Cleaning Nginx configs...${NC}"
rm -f /etc/nginx/sites-enabled/reviactyl.conf /etc/nginx/sites-available/reviactyl.conf
systemctl reload nginx || true

echo -e "  ${GREEN}[OK]${NC} Reviactyl panel removed."
