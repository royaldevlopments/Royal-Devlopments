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
    if [ ! -d "/var/www/skyport" ]; then echo -e "  ${RED}Skyport not installed.${NC}"; return 1; fi
    cd /var/www/skyport || return 1
}

echo -e "  ${GOLD}Skyport User Management${NC}"
echo ""
echo -e "  ${GREEN}[1]${NC} Custom User Create"
echo -e "  ${GREEN}[2]${NC} Auto Create Admin User"
echo ""
echo -ne "  ${CYAN}Choose option:${NC} "
read choice

check || exit 1

if [ "$choice" = "1" ]; then
    php artisan user:create
elif [ "$choice" = "2" ]; then
    USERNAME="user$(openssl rand -hex 2)"
    PASSWORD="$(openssl rand -base64 10)"
    EMAIL="$(openssl rand -base64 4)@skyport.com"
    php artisan user:create --name="Admin" --email="$EMAIL" --password="$PASSWORD" --admin --no-interaction
    echo ""
    echo -e "  ${GREEN}[OK]${NC} User created!"
    echo -e "  ${GRAY}Email:${NC}    $EMAIL"
    echo -e "  ${GRAY}Username:${NC} $USERNAME"
    echo -e "  ${GRAY}Password:${NC} $PASSWORD"
else
    echo -e "  ${RED}Invalid.${NC}"
fi
