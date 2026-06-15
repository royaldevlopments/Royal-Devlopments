#!/bin/bash

CYAN='\033[38;5;51m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

echo -e "  ${RED}WARNING: This will delete all Paymenter data and databases!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GREEN}Cancelled.${NC}"; exit; }

echo -e "  ${PURPLE}::${NC} Stopping services..."
systemctl stop paymenter.service 2>/dev/null || true
systemctl disable paymenter.service 2>/dev/null || true
rm -f /etc/systemd/system/paymenter.service
systemctl daemon-reload

echo -e "  ${PURPLE}::${NC} Removing panel files..."
rm -rf /var/www/paymenter

echo -e "  ${PURPLE}::${NC} Dropping database..."
mysql -u root -e "DROP DATABASE IF EXISTS paymenter; DROP USER IF EXISTS 'paymenter'@'127.0.0.1'; FLUSH PRIVILEGES;" 2>/dev/null || true

echo -e "  ${PURPLE}::${NC} Cleaning Nginx configs..."
rm -f /etc/nginx/sites-enabled/paymenter.conf /etc/nginx/sites-available/paymenter.conf
systemctl reload nginx 2>/dev/null || true

rm -f /etc/certs/paymenter/fullchain.pem /etc/certs/paymenter/privkey.pem 2>/dev/null || true
rmdir /etc/certs/paymenter 2>/dev/null || true

echo -e "  ${GREEN}[OK]${NC} Paymenter removed successfully."
