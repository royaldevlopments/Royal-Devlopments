#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'

check() {
    if [ ! -d "/var/www/hydra" ]; then echo -e "  ${RED}HydraPanel not installed.${NC}"; return 1; fi
    cd /var/www/hydra || return 1
}

echo -e "  ${GOLD}HydraPanel User Management${NC}"
echo ""
echo -e "  ${GREEN}[1]${NC} Create Custom User"
echo -e "  ${GREEN}[2]${NC} Auto Create Admin User"
echo ""
echo -ne "  ${CYAN}Choose option:${NC} "
read choice

check || exit 1

if [ "$choice" = "1" ]; then
    node exec/createUser.js
elif [ "$choice" = "2" ]; then
    EMAIL="$(openssl rand -base64 4)@hydra.com"
    USERNAME="admin$(openssl rand -hex 2)"
    PASSWORD="$(openssl rand -base64 10)"
    node exec/createUser.js << EOF
$EMAIL
$USERNAME
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
