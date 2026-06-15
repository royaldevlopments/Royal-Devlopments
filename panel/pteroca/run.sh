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
    echo -e "${CYAN}   ____  _                    ____    _              ${NC}"
    echo -e "${CYAN}  |  _ \| |_ ___ _ __ ___   / ___|  / \             ${NC}"
    echo -e "${CYAN}  | |_) | __/ _ \\ '__/ _ \\ | |     / _ \\            ${NC}"
    echo -e "${CYAN}  |  __/| ||  __/ | | (_) || |___ / ___ \\           ${NC}"
    echo -e "${CYAN}  |_|    \\__\\___|_|  \\___/  \\____/_/   \\_\\          ${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} Install        ${GRAY}[4]${NC} User"
    echo -e "  ${YELLOW}[2]${NC} Update        ${GRAY}[5]${NC} Domain"
    echo -e "  ${RED}[3]${NC} Uninstall      ${GRAY}[6]${NC} phpMyAdmin"
    echo -e "  ${GRAY}[7]${NC} Images"
    echo -e "  ${WHITE}[0]${NC} Back"
    echo ""
    echo -ne "${BOLD}${WHITE}  pteroca:~# ${NC}"
    read choice

    case $choice in
        1) run_script "panel/pteroca/install.sh" ;;
        2) run_script "panel/pteroca/update.sh" ;;
        3) run_script "panel/pteroca/uninstall.sh" ;;
        4) run_script "panel/pteroca/user.sh" ;;
        5) run_script "panel/pteroca/domain.sh" ;;
        6) run_script "panel/pterodactyl/phpMyAdmin.sh" ;;
        7) run_script "panel/pterodactyl/images.sh" ;;
        0) clear; exit ;;
        *) echo -e "${RED}  Invalid option...${NC}"; sleep 1 ;;
    esac
    echo ""; pause
done
