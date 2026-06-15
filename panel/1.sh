#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;220m'
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
    echo -ne "  ${GRAY}Press any key to return to grid...${NC}"
    read -n 1 -s -r
}

get_metrics() {
    UPT=$(uptime -p | sed 's/up //')
    LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | xargs)
}

show_header() {
    get_metrics
    clear
    echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}SERVER PANEL MANAGER${NC} ${GRAY}v15.0${NC}         ${GRAY}$(date +"%H:%M")${NC}  ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
    echo -e "  ${CYAN}SYSTEM STATUS${NC}"
    echo -e "  ${GRAY}|- Uptime :${NC} ${WHITE}$UPT${NC}"
    echo -e "  ${GRAY}+- Load   :${NC} ${WHITE}$LOAD${NC}"
    echo -e "${GRAY}────────────────────────────────────────────────────────────${NC}"
}

panel_menu() {
    while true; do
        show_header
        echo -e "  ${GOLD}PTERODACTYL PANEL${NC}"
        echo -e "  ${GRAY}┌──────────────────────────────────────────────┐${NC}"
        echo -e "  ${GRAY}│${NC} ${PURPLE}[1]${NC} Pterodactyl Panel                      ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${CYAN}[2]${NC} Skyport Panel                          ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${GOLD}[3]${NC} Reviactyl Panel                         ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${GREEN}[4]${NC} HydraPanel                             ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${YELLOW}[5]${NC} PufferPanel                            ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${WHITE}[6]${NC} Pelican Panel                           ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${GOLD}[7]${NC} Pyrodactyl Panel                         ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${CYAN}[8]${NC} Catalyst Panel                           ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${PURPLE}[9]${NC} Jexactyl Panel                           ${GRAY}│${NC}"
        echo -e "  ${GRAY}│${NC} ${YELLOW}[10]${NC} Paymentar Panel                         ${GRAY}│${NC}"
         echo -e "  ${GRAY}│${NC} ${CYAN}[11]${NC} PteroCA Panel                           ${GRAY}│${NC}"
         echo -e "  ${GRAY}│${NC} ${GREEN}[12]${NC} CtrlPanel                              ${GRAY}│${NC}"
         echo -e "  ${GRAY}│${NC} ${YELLOW}[13]${NC} FOSSBilling                            ${GRAY}│${NC}"
         echo -e "  ${GRAY}│${NC} ${RED}[14]${NC} Proxmox VE                             ${GRAY}│${NC}"
         echo -e "  ${GRAY}│${NC} ${CYAN}[15]${NC} ConvoyPanel                            ${GRAY}│${NC}"
         echo -e "  ${GRAY}│${NC} ${GREEN}[16]${NC} Virtualizor                            ${GRAY}│${NC}"
         echo -e "  ${GRAY}│${NC} ${PURPLE}[17]${NC} Webmin / Virtualmin                   ${GRAY}│${NC}"
         echo -e "  ${GRAY}│${NC} ${GOLD}[18]${NC} Portainer                              ${GRAY}│${NC}"
         echo -e "  ${GRAY}│${NC} ${RED}[0]${NC} Back                                  ${GRAY}│${NC}"
         echo -e "  ${GRAY}└──────────────────────────────────────────────┘${NC}"
         echo ""
         echo -ne "  ${CYAN}Select Option [0-18]:${NC} "
        read p

        case $p in
            1)  echo -e "  ${CYAN}-> Executing Pterodactyl Routine...${NC}"
                run_script "panel/pterodactyl/run.sh"
                pause ;;
            2)  echo -e "  ${CYAN}-> Executing Skyport Routine...${NC}"
                run_script "panel/skyport/run.sh"
                pause ;;
            3)  echo -e "  ${CYAN}-> Executing Reviactyl Routine...${NC}"
                run_script "panel/reviactyl/run.sh"
                pause ;;
            4)  echo -e "  ${CYAN}-> Executing HydraPanel Routine...${NC}"
                run_script "panel/hydra/run.sh"
                pause ;;
            5)  echo -e "  ${CYAN}-> Executing PufferPanel Routine...${NC}"
                run_script "panel/puffer/run.sh"
                pause ;;
            6)  echo -e "  ${CYAN}-> Executing Pelican Routine...${NC}"
                run_script "panel/pelican/run.sh"
                pause ;;
            7)  echo -e "  ${CYAN}-> Executing Pyrodactyl Routine...${NC}"
                run_script "panel/pyrodactyl/run.sh"
                pause ;;
            8)  echo -e "  ${CYAN}-> Executing Catalyst Routine...${NC}"
                run_script "panel/catalyst/run.sh"
                pause ;;
            9)  echo -e "  ${CYAN}-> Executing Jexactyl Routine...${NC}"
                run_script "panel/jexactyl/run.sh"
                pause ;;
            10) echo -e "  ${CYAN}-> Executing Paymentar Routine...${NC}"
                run_script "panel/paymentar/run.sh"
                pause ;;
             11) echo -e "  ${CYAN}-> Executing PteroCA Routine...${NC}"
                 run_script "panel/pteroca/run.sh"
                 pause ;;
             12) echo -e "  ${CYAN}-> Executing CtrlPanel Routine...${NC}"
                 run_script "panel/ctrlpanel/run.sh"
                 pause ;;
             13) echo -e "  ${CYAN}-> Executing FOSSBilling Routine...${NC}"
                 run_script "panel/fossbilling/run.sh"
                 pause ;;
             14) echo -e "  ${CYAN}-> Executing Proxmox Routine...${NC}"
                 run_script "panel/proxmox/run.sh"
                 pause ;;
             15) echo -e "  ${CYAN}-> Executing ConvoyPanel Routine...${NC}"
                 run_script "panel/convoy/run.sh"
                 pause ;;
             16) echo -e "  ${CYAN}-> Executing Virtualizor Routine...${NC}"
                 run_script "panel/virtualizor/run.sh"
                 pause ;;
             17) echo -e "  ${CYAN}-> Executing Webmin Routine...${NC}"
                 run_script "panel/webmin/run.sh"
                 pause ;;
             18) echo -e "  ${CYAN}-> Executing Portainer Routine...${NC}"
                 run_script "panel/portainer/run.sh"
                 pause ;;
             0)  echo -e "\n  ${RED}Going back...${NC}"
                return ;;
            *)  echo -e "  ${RED}Invalid Selection${NC}"
                sleep 1 ;;
        esac
    done
}

panel_menu
