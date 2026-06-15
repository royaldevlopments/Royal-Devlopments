#!/bin/bash

CYAN='\033[38;5;51m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
YELLOW='\033[38;5;220m'
RED='\033[38;5;196m'
BOLD='\033[1m'
PURPLE='\033[38;5;141m'
GOLD='\033[38;5;214m'
NC='\033[0m'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
GITHUB_RAW="https://raw.githubusercontent.com/nobita329/Nobita-Cloud/main"

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
    echo -ne "  ${GRAY}Press any key to return to grid...${NC}"
    read -n 1 -s -r
}

while true; do
    clear
    echo -e "${PURPLE} __   _____     _ _ _           _                  ${NC}"
    echo -e "${PURPLE} \ \ / /__ \ __| (_) |_ ___  __| |___              ${NC}"
    echo -e "${PURPLE}  \ V /  / / '__| | | __/ _ \/ _  / __|            ${NC}"
    echo -e "${PURPLE}   | |  / /| |  | | | ||  __/ (_| \__ \            ${NC}"
    echo -e "${PURPLE}   |_| |_| |_|  |_|_|\__\___|\__,_|___/            ${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} Install        ${GRAY}[4]${NC} N/A"
    echo -e "  ${YELLOW}[2]${NC} Update        ${GRAY}[5]${NC} N/A"
    echo -e "  ${RED}[3]${NC} Uninstall      ${GRAY}[6]${NC} phpMyAdmin"
    echo -e "  ${GRAY}[7]${NC} Images"
    echo -e "  ${WHITE}[0]${NC} Back"
    echo ""
    echo -ne "${BOLD}${WHITE}  virtualizor:~# ${NC}"
    read choice

    case $choice in
        1) run_script "panel/virtualizor/install.sh" ;;
        2) run_script "panel/virtualizor/update.sh" ;;
        3) run_script "panel/virtualizor/uninstall.sh" ;;
        4) echo "  N/A" ;;
        5) echo "  N/A" ;;
        6) run_script "panel/pterodactyl/phpMyAdmin.sh" ;;
        7) run_script "panel/pterodactyl/images.sh" ;;
        0) clear; exit ;;
        *) echo -e "${RED}  Invalid option...${NC}"; sleep 1 ;;
    esac
    echo ""; pause
done
