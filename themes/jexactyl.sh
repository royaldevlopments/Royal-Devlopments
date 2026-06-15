#!/bin/bash

GREEN='\033[38;5;82m'
GRAY='\033[38;5;242m'
GOLD='\033[38;5;214m'
WHITE='\033[38;5;255m'
RED='\033[38;5;196m'
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
    echo -e "${GOLD}"
    echo -e "      _            _           _ _ _           _     "
    echo -e "     | | ___  __ _(_)_ __ __ _| | (_)_ __   ___| |_  "
    echo -e "  _  | |/ _ \/ _\ | | '__/ _\ | | | \ '_ \ / _ \ __| "
    echo -e " | |_| |  __/ (_| | | | | (_| | | | | | | |  __/ |_  "
    echo -e "  \___/ \___|\__,_|_|_|  \__,_|_|_|_|_| |_|\___|\__| "
    echo -e "${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}[1]${NC} Jexactyl Panel"
    echo -e "  ${RED}[0]${NC} Back"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${CYAN}Select Option [0-1]:${NC} "
    read p

    case $p in
        1) run_script "panel/jexactyl/run.sh" ;;
        0) clear; exit ;;
        *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
    esac
    pause
done
