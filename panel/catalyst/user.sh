#!/bin/bash

CYAN='\033[38;5;51m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
PURPLE='\033[38;5;141m'
NC='\033[0m'

INSTALL_DIR="/opt/catalyst-docker"

echo -e "  ${GOLD}Catalyst User Management${NC}"
echo ""
echo -e "  ${PURPLE}Catalyst uses self-registration.${NC}"
echo -e "  ${GRAY}The first user to register becomes the admin.${NC}"
echo ""
echo -e "  ${GREEN}[1]${NC} Open panel in browser"
echo -e "  ${GREEN}[2]${NC} Show registration URL"
echo ""
echo -ne "  ${CYAN}Choose option:${NC} "
read choice

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "  ${RED}Catalyst not installed.${NC}"
    exit 1
fi

cd "$INSTALL_DIR" || exit 1

PUBLIC_URL=$(grep "^PUBLIC_URL=" .env | cut -d= -f2-)

if [ "$choice" = "1" ]; then
    echo -e "  ${GREEN}Open ${WHITE}$PUBLIC_URL${NC} ${GREEN}in your browser and register.${NC}"
elif [ "$choice" = "2" ]; then
    echo -e "  ${GRAY}Registration URL:${NC} ${WHITE}$PUBLIC_URL${NC}"
else
    echo -e "  ${RED}Invalid.${NC}"
fi
