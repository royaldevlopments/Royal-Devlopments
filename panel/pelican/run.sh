#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m'
GRAY='\033[0;90m'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"

run_script() {
    local script="$1"
    if [ -f "$BASE_DIR/$script" ]; then
        bash "$BASE_DIR/$script"
    else
        bash <(curl -s "$GITHUB_RAW/$script")
    fi
}

pause() {
    echo ""
    read -p "  Press [Enter] to return to menu..."
}

while true; do
    clear
    echo -e "${CYAN}"
    cat << "EOF"
   ██████╗ ███████╗██╗     ██╗ ██████╗ █████╗ ███╗   ██╗
   ██╔══██╗██╔════╝██║     ██║██╔════╝██╔══██╗████╗  ██║
   ██████╔╝█████╗  ██║     ██║██║     ███████║██╔██╗ ██║
   ██╔═══╝ ██╔══╝  ██║     ██║██║     ██╔══██║██║╚██╗██║
   ██║     ███████╗███████╗██║╚██████╗██║  ██║██║ ╚████║
   ╚═╝     ╚══════╝╚══════╝╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝
EOF
    echo -e "${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}║${NC}          ${BOLD}${WHITE}PELICAN PANEL MANAGEMENT${NC}                       ${PURPLE}║${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo ""
    if [ -d "/var/www/pelican" ]; then
        echo -e "  ${CYAN}Status:${NC} ${GREEN}INSTALLED${NC}"
    else
        echo -e "  ${CYAN}Status:${NC} ${RED}NOT INSTALLED${NC}"
    fi
    echo ""
    echo -e "  ${GREEN}[1]${NC} Install        ${GRAY}[4]${NC} User"
    echo -e "  ${YELLOW}[2]${NC} Update        ${GRAY}[5]${NC} Domain"
    echo -e "  ${RED}[3]${NC} Uninstall      ${GRAY}[6]${NC} phpMyAdmin"
    echo -e "  ${GRAY}[7]${NC} Images"
    echo -e "  ${WHITE}[0]${NC} Back"
    echo ""
    echo -ne "${BOLD}${WHITE}  pelican:~# ${NC}"
    read choice

    case $choice in
        1) run_script "panel/pelican/install.sh" ;;
        2) run_script "panel/pelican/update.sh" ;;
        3) run_script "panel/pelican/uninstall.sh" ;;
        4) run_script "panel/pelican/user.sh" ;;
        5) run_script "panel/pelican/domain.sh" ;;
        6) run_script "panel/pterodactyl/phpMyAdmin.sh" ;;
        7) run_script "panel/pterodactyl/images.sh" ;;
        0) clear; exit ;;
        *) echo -e "${RED}  Invalid option...${NC}"; sleep 1 ;;
    esac
    echo ""; pause
done
