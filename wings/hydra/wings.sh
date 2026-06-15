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
WINGS_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$(dirname "$WINGS_DIR")"
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"

PANEL_NAME="HydraPanel"
BINARY_NAME="hydra-daemon"
REPO="hydren-dev/HydraDAEMON"
CONFIG_DIR="/var/www/hydra/daemon"
SERVICE_NAME="hydra-daemon"

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

while true; do
    clear
    echo -e "${CYAN}"
    echo -e "  _   _       _               _   _          _ "
    echo -e " | | | |_   _| |__  _ __ __ _| \ | | ___  __| |"
    echo -e " | |_| | | | | '_ \| '__/ _\` |  \| |/ _ \/ _\` |"
    echo -e " |  _  | |_| | | | | | | (_| | |\  |  __/ (_| |"
    echo -e " |_| |_|\__, |_| |_|_|  \__,_|_| \_|\___|\__,_|"
    echo -e "        |___/                                   "
    echo -e "${NC}"
    echo -e "  ${GREEN}[1]${NC} Install"
    echo -e "  ${YELLOW}[2]${NC} Update"
    echo -e "  ${RED}[3]${NC} Uninstall"
    echo -e "  ${GRAY}[4]${NC} Start"
    echo -e "  ${GRAY}[5]${NC} Stop"
    echo -e "  ${GRAY}[6]${NC} Restart"
    echo -e "  ${GRAY}[7]${NC} Status"
    echo -e "  ${WHITE}[0]${NC} Back"
    echo ""
    echo -ne "${BOLD}${WHITE}  ${BINARY_NAME}~# ${NC}"
    read choice

    case $choice in
        1) bash "$SCRIPT_DIR/install.sh" "$PANEL_NAME" "$BINARY_NAME" "$REPO" "$CONFIG_DIR" "$SERVICE_NAME" install ;;
        2) bash "$SCRIPT_DIR/install.sh" "$PANEL_NAME" "$BINARY_NAME" "$REPO" "$CONFIG_DIR" "$SERVICE_NAME" update ;;
        3) bash "$SCRIPT_DIR/install.sh" "$PANEL_NAME" "$BINARY_NAME" "$REPO" "$CONFIG_DIR" "$SERVICE_NAME" uninstall ;;
        4) systemctl start "$SERVICE_NAME" && echo -e "  ${GREEN}[OK]${NC} Started" ;;
        5) systemctl stop "$SERVICE_NAME" && echo -e "  ${GREEN}[OK]${NC} Stopped" ;;
        6) systemctl restart "$SERVICE_NAME" && echo -e "  ${GREEN}[OK]${NC} Restarted" ;;
        7) systemctl status "$SERVICE_NAME" --no-pager | head -25 ;;
        0) clear; exit ;;
        *) echo -e "${RED}  Invalid option...${NC}"; sleep 1 ;;
    esac
    echo ""; pause
done
