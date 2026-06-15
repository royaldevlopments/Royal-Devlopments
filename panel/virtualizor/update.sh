#!/bin/bash

GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'

if [ ! -d "/usr/local/virtualizor" ]; then
    echo -e "  ${RED}Virtualizor not installed.${NC}"
    exit 1
fi

echo -e "  ${GOLD}Virtualizor updates are managed through the admin panel.${NC}"
echo -e "  ${GOLD}Visit Admin Panel -> Settings -> Update${NC}"
