#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${RED}  WARNING: This will remove all HydraPanel data!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GRAY}Cancelled.${NC}"; exit; }

systemctl stop hydrapanel 2>/dev/null || true
systemctl disable hydrapanel 2>/dev/null || true
rm -f /etc/systemd/system/hydrapanel.service
systemctl daemon-reload

rm -rf /var/www/hydra
rm -f /etc/nginx/sites-enabled/hydra.conf /etc/nginx/sites-available/hydra.conf
systemctl reload nginx 2>/dev/null || true

echo -e "  ${GREEN}[OK]${NC} HydraPanel removed."
