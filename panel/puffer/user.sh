#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'

echo -e "  ${GOLD}PufferPanel User Management${NC}"
echo ""
if ! command -v pufferpanel &> /dev/null; then echo -e "  ${RED}PufferPanel not installed.${NC}"; exit 1; fi

echo -e "  ${GREEN}[1]${NC} Custom User Create"
echo -e "  ${GREEN}[2]${NC} Auto Create Admin User"
echo ""
echo -ne "  ${CYAN}Choose option:${NC} "
read choice

if [ "$choice" = "1" ]; then
    pufferpanel user add
elif [ "$choice" = "2" ]; then
    USERNAME="user$(openssl rand -hex 2)"
    PASSWORD="$(openssl rand -base64 10)"
    EMAIL="$(openssl rand -base64 4)@puffer.com"
    pufferpanel user add << EOF
$EMAIL
$USERNAME
$PASSWORD
$PASSWORD
y
EOF
    echo ""
    echo -e "  ${GREEN}[OK]${NC} User created!"
    echo -e "  ${GRAY}Email:${NC}    $EMAIL"
    echo -e "  ${GRAY}Username:${NC} $USERNAME"
    echo -e "  ${GRAY}Password:${NC} $PASSWORD"
else
    echo -e "  ${RED}Invalid.${NC}"
fi
