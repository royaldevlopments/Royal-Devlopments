#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'

echo -e "  ${GOLD}FOSSBilling User Management${NC}"
echo ""
echo -e "  ${GREEN}[1]${NC} Create admin via CLI"
echo -e "  ${GREEN}[2]${NC} Admin panel instructions"
echo ""
echo -ne "  ${CYAN}Choose option:${NC} "
read choice

if [ "$choice" = "1" ]; then
    if [ ! -f "/var/www/fossbilling/index.php" ]; then
        echo -e "  ${RED}FOSSBilling not installed.${NC}"
        exit 1
    fi
    cd /var/www/fossbilling || exit 1
    echo -e "  ${GOLD}FOSSBilling CLI user creation...${NC}"
    echo ""
    read -p "  Email: " EMAIL
    read -sp "  Password: " PASSWORD; echo ""
    read -p "  First Name: " FIRST
    read -p "  Last Name: " LAST
    php index.php "$EMAIL" "$PASSWORD" "$FIRST" "$LAST" 2>/dev/null || {
        echo ""
        echo -e "  ${GOLD}CLI not available. Create a user via:${NC}"
        echo -e "  ${GRAY}1. Visit https://your-domain/admin${NC}"
        echo -e "  ${GRAY}2. Go to Clients -> Add New${NC}"
    }
elif [ "$choice" = "2" ]; then
    echo ""
    echo -e "  ${GOLD}To create a user in FOSSBilling:${NC}"
    echo -e "  ${GRAY}1. Visit https://your-domain/admin${NC}"
    echo -e "  ${GRAY}2. Log in with the admin account created during setup${NC}"
    echo -e "  ${GRAY}3. Go to Clients -> Add New Client${NC}"
    echo -e "  ${GRAY}4. Fill in the details and save${NC}"
else
    echo -e "  ${RED}Invalid.${NC}"
fi
