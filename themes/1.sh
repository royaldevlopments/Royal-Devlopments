#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;220m'
GOLD='\033[38;5;214m'
NC='\033[0m'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
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
    echo -ne "  ${GRAY}Press any key to return...${NC}"
    read -n 1 -s -r
}

while true; do
    clear
    echo -e "${PURPLE}"
    echo -e "  _______ _                                  _     "
    echo -e " |__   __| |                                | |    "
    echo -e "    | |  | |__  _ __ ___  ___ _ __ ___   ___| |__  "
    echo -e "    | |  | '_ \| '__/ _ \/ _ \ '_ \ _ \ / __| '_ \ "
    echo -e "    | |  | | | | | |  __/  __/ | | | | | (__| | | |"
    echo -e "    |_|  |_| |_|_|  \___|\___|_| |_| |_|\___|_| |_|"
    echo -e "${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}[1]${NC} Pterodactyl Themes"
    echo -e "  ${YELLOW}[2]${NC} Reviactyl Themes"
    echo -e "  ${CYAN}[3]${NC} Pelican Themes"
    echo -e "  ${GOLD}[4]${NC} Jexactyl Themes"
    echo -e "  ${GREEN}[5]${NC} PteroCA Themes"
    echo -e "  ${RED}[0]${NC} Back"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${CYAN}Select Option [0-5]:${NC} "
    read p

    case $p in
        1) run_script "themes/pterodactyl.sh" ;;
        2) run_script "themes/reviactyl.sh" ;;
        3) run_script "themes/pelican.sh" ;;
        4) run_script "themes/jexactyl.sh" ;;
        5) run_script "themes/pteroca.sh" ;;
        0) clear; exit ;;
        *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
    esac
    pause
done
