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
    echo -ne "  ${GRAY}Press any key to return to wings grid...${NC}"
    read -n 1 -s -r
}

get_metrics() {
    UPT=$(uptime -p | sed 's/up //')
    LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)
}

show_header() {
    get_metrics
    clear
    echo -e "${CYAN}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${CYAN}│${NC}  ${PURPLE}WINGS DAEMON MANAGER${NC} ${GRAY}v1.0${NC}            ${GRAY}$(date +"%H:%M")${NC}  ${CYAN}│${NC}"
    echo -e "${CYAN}└──────────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${CYAN}SYSTEM STATUS${NC}"
    echo -e "  ${GRAY}|- Uptime :${NC} ${WHITE}$UPT${NC}"
    echo -e "  ${GRAY}+- Load   :${NC} ${WHITE}$LOAD${NC}"
    echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"
}

panel_menu() {
    while true; do
        show_header
        echo -e "  ${GOLD}AVAILABLE WINGS${NC}"
        echo -e "  ${GRAY}┌──────────────────────────────────────────────┐${NC}"
        echo -e "  ${GRAY}│${NC} ${GREEN}[1]${NC} Pterodactyl Wings                    ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${PURPLE}[2]${NC} Pelican Wings                        ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${YELLOW}[3]${NC} Reviactyl Wings                       ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${CYAN}[4]${NC} Pyrodactyl Wings                       ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${GREEN}[5]${NC} Jexactyl Wings                        ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${PURPLE}[6]${NC} PteroCA Wings                         ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${RED}[0]${NC} Back                                  ${GRAY}│${NC}"
        echo -e "  ${GRAY}└──────────────────────────────────────────────┘${NC}"
        echo ""
        echo -ne "  ${CYAN}Select Option [0-6]:${NC} "
        read p

        case $p in
            1)  echo -e "  ${CYAN}-> Pterodactyl Wings...${NC}"
                run_script "wings/pterodactyl/wings.sh"
                pause ;;
            2)  echo -e "  ${CYAN}-> Pelican Wings...${NC}"
                run_script "wings/pelican/wings.sh"
                pause ;;
            3)  echo -e "  ${CYAN}-> Reviactyl Wings...${NC}"
                run_script "wings/reviactyl/wings.sh"
                pause ;;
            4)  echo -e "  ${CYAN}-> Pyrodactyl Wings...${NC}"
                run_script "wings/pyrodactyl/wings.sh"
                pause ;;
            5)  echo -e "  ${CYAN}-> Jexactyl Wings...${NC}"
                run_script "wings/jexactyl/wings.sh"
                pause ;;
            6)  echo -e "  ${CYAN}-> PteroCA Wings...${NC}"
                run_script "wings/pteroca/wings.sh"
                pause ;;
            0)  echo -e "\n  ${RED}Going back...${NC}"
                return ;;
            *)  echo -e "  ${RED}Invalid Selection${NC}"
                sleep 1 ;;
        esac
    done
}

panel_menu
