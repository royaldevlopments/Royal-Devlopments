#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'
HEADER_LINE="${GRAY}────────────────────────────────────────────────────────────${NC}"

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PANEL_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$(dirname "$PANEL_DIR")"
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"

download_src() {
    local SRC_FILE="installer.sh"
    local LOCAL_PATH="$BASE_DIR/src/pteroca/$SRC_FILE"

    if [ -f "$LOCAL_PATH" ]; then
        ok "Running from local repo"
        bash "$LOCAL_PATH"
        return 0
    fi

    echo -e "  ${YELLOW}Local source not found. Trying GitHub raw...${NC}"
    local REMOTE_SCRIPT
    REMOTE_SCRIPT=$(curl -sL "$GITHUB_RAW/src/pteroca/$SRC_FILE" 2>/dev/null)
    if [ -n "$REMOTE_SCRIPT" ]; then
        ok "Running from GitHub raw"
        bash -c "$REMOTE_SCRIPT"
        return 0
    fi

    echo -e "  ${YELLOW}Trying upstream...${NC}"
step "Downloading PteroCA installer..."
download_src
}

echo -e "${GOLD}"
cat << "EOF"
   ____  _                    ____    _
  |  _ \| |_ ___ _ __ ___   / ___|  / \
  | |_) | __/ _ \ '__/ _ \ | |     / _ \
  |  __/| ||  __/ | | (_) || |___ / ___ \
  |_|    \__\___|_|  \___/  \____/_/   \_\
EOF
echo -e "${NC}"
echo -e "           ${WHITE}PTEROCA INSTALLER${NC}"
echo -e "${HEADER_LINE}"

echo -e "\n  ${GOLD}PteroCA uses its own comprehensive auto-installer.${NC}"
echo -e "  ${GOLD}This will download and run the official installer from pteroca.com${NC}"
echo ""

while true; do
    echo -ne "  ${CYAN}Continue?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

bash -c "$(wget -qO- https://pteroca.com/installer.sh)"
