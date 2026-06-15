#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${RED}  WARNING: This will remove all Pelican panel data!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GRAY}Cancelled.${NC}"; exit; }

systemctl stop pelicanq.service 2>/dev/null || true
systemctl disable pelicanq.service 2>/dev/null || true
rm -f /etc/systemd/system/pelicanq.service
systemctl daemon-reload

rm -rf /var/www/pelican

mysql -u root -e "DROP DATABASE IF EXISTS pelican; DROP USER IF EXISTS 'pelican'@'127.0.0.1'; FLUSH PRIVILEGES;"

rm -f /etc/nginx/sites-enabled/pelican.conf /etc/nginx/sites-available/pelican.conf
systemctl reload nginx || true

echo -e "  ${GREEN}[OK]${NC} Pelican panel removed."
