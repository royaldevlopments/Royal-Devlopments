#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
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
    echo -e "${CYAN}"
    echo -e "   ____      _ _           _ _                 _     "
    echo -e "  |  _ \ ___(_) |_ ___  __| (_) ___ _   _  ___| |__  "
    echo -e "  | |_) / _ \ | __/ _ \/ _\ | |/ __| | | |/ __| '_ \ "
    echo -e "  |  __/  __/ | ||  __/ (_| | | (__| |_| | (__| | | |"
    echo -e "  |_|   \___|_|\__\___|\__,_|_|\___|\__, |\___|_| |_|"
    echo -e "                                     |___/            "
    echo -e "${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}[1]${NC} Pelican Panel"
    echo -e "  ${RED}[0]${NC} Back"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${CYAN}Select Option [0-1]:${NC} "
    read p

    case $p in
        1) run_script "panel/pelican/run.sh" ;;
        0) clear; exit ;;
        *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
    esac
    pause
done
