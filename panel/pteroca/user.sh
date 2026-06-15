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
    if [ ! -d "/var/www/pteroca" ]; then echo -e "  ${RED}PteroCA not installed.${NC}"; return 1; fi
    cd /var/www/pteroca || return 1
}

PHP_BIN="php"
if command -v php8.4 &>/dev/null; then PHP_BIN="php8.4"
elif command -v php8.3 &>/dev/null; then PHP_BIN="php8.3"
elif command -v php8.2 &>/dev/null; then PHP_BIN="php8.2"
fi

echo -e "  ${GOLD}PteroCA User Management${NC}"
echo ""
echo -e "  ${GREEN}[1]${NC} Create User"
echo -e "  ${GREEN}[2]${NC} Auto Create Admin User"
echo -e "  ${GREEN}[3]${NC} List Users"
echo -e "  ${GREEN}[4]${NC} User Info"
echo ""
echo -ne "  ${CYAN}Choose option:${NC} "
read choice

check || exit 1

if [ "$choice" = "1" ]; then
    read -p "  Email: " EMAIL
    read -sp "  Password: " PASSWORD; echo ""
    read -p "  Role [ROLE_ADMIN]: " ROLE
    ROLE=${ROLE:-ROLE_ADMIN}
    ${PHP_BIN} bin/console pteroca:user:create "$EMAIL" "$PASSWORD" "$ROLE"
elif [ "$choice" = "2" ]; then
    EMAIL="admin$(openssl rand -hex 4)@pteroca.com"
    PASSWORD="$(openssl rand -base64 12)"
    ${PHP_BIN} bin/console pteroca:user:create "$EMAIL" "$PASSWORD" ROLE_ADMIN
    echo ""
    echo -e "  ${GREEN}[OK]${NC} User created!"
    echo -e "  ${GRAY}Email:${NC}    $EMAIL"
    echo -e "  ${GRAY}Password:${NC} $PASSWORD"
elif [ "$choice" = "3" ]; then
    ${PHP_BIN} bin/console pteroca:user:list
elif [ "$choice" = "4" ]; then
    read -p "  User email or ID: " USER_ID
    ${PHP_BIN} bin/console pteroca:user:info "$USER_ID"
else
    echo -e "  ${RED}Invalid.${NC}"
fi
