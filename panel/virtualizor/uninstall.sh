#!/bin/bash

RED='\033[38;5;196m'
PURPLE='\033[38;5;141m'
GREEN='\033[38;5;82m'
NC='\033[0m'

echo -e "  ${RED}WARNING: This will remove Virtualizor and all VMs!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GREEN}Cancelled.${NC}"; exit; }

echo -e "  ${PURPLE}::${NC} Stopping services..."
/usr/local/virtualizor/scripts/stop_virtualizor 2>/dev/null || true

echo -e "  ${PURPLE}::${NC} Removing Virtualizor files..."
rm -rf /usr/local/virtualizor
rm -rf /var/virtualizor

echo -e "  ${PURPLE}::${NC} Removing cron jobs..."
crontab -l 2>/dev/null | grep -v virtualizor | crontab -

echo -e "  ${GREEN}[OK]${NC} Virtualizor removed."
