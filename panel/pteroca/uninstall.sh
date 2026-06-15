#!/bin/bash

CYAN='\033[38;5;51m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

echo -e "  ${RED}WARNING: This will delete all PteroCA data and databases!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GREEN}Cancelled.${NC}"; exit; }

echo -e "  ${PURPLE}::${NC} Stopping services..."
systemctl stop nginx 2>/dev/null || true

echo -e "  ${PURPLE}::${NC} Removing panel files..."
rm -rf /var/www/pteroca

echo -e "  ${PURPLE}::${NC} Dropping database..."
mysql -u root -e "DROP DATABASE IF EXISTS pteroca; DROP USER IF EXISTS 'pteroca'@'127.0.0.1'; DROP USER IF EXISTS 'pteroca'@'%'; DROP USER IF EXISTS 'pteroca'@'localhost'; FLUSH PRIVILEGES;" 2>/dev/null || true

echo -e "  ${PURPLE}::${NC} Cleaning Nginx configs..."
rm -f /etc/nginx/sites-enabled/pteroca.conf /etc/nginx/sites-available/pteroca.conf
systemctl reload nginx 2>/dev/null || true

rm -f /root/.pteroca_mysql 2>/dev/null || true

echo -e "  ${GREEN}[OK]${NC} PteroCA removed successfully."
