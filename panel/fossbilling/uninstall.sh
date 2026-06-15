#!/bin/bash

CYAN='\033[38;5;51m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

echo -e "  ${RED}WARNING: This will delete all FOSSBilling data and databases!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GREEN}Cancelled.${NC}"; exit; }

echo -e "  ${PURPLE}::${NC} Stopping services..."
rm -f /etc/cron.d/fossbilling

echo -e "  ${PURPLE}::${NC} Removing panel files..."
rm -rf /var/www/fossbilling

echo -e "  ${PURPLE}::${NC} Dropping database..."
mysql -u root -e "DROP DATABASE IF EXISTS fossbilling; DROP USER IF EXISTS 'fossbilling'@'127.0.0.1'; FLUSH PRIVILEGES;" 2>/dev/null || true

echo -e "  ${PURPLE}::${NC} Cleaning Nginx configs..."
rm -f /etc/nginx/sites-enabled/fossbilling.conf /etc/nginx/sites-available/fossbilling.conf
systemctl reload nginx 2>/dev/null || true

rm -f /etc/certs/fossbilling/fullchain.pem /etc/certs/fossbilling/privkey.pem 2>/dev/null || true
rmdir /etc/certs/fossbilling 2>/dev/null || true
rm -f /root/.fossbilling_db 2>/dev/null || true

echo -e "  ${GREEN}[OK]${NC} FOSSBilling removed successfully."
