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
    local SRC_FILE="$1"
    local LOCAL_PATH="$BASE_DIR/src/webmin/$SRC_FILE"

    if [ -f "$LOCAL_PATH" ]; then
        if [[ "$SRC_FILE" == *.sh ]]; then
            bash "$LOCAL_PATH"
        else
            cp "$LOCAL_PATH" ./
        fi
        ok "Copied from local repo"
        return 0
    fi

    echo -e "  ${YELLOW}Local source not found. Trying GitHub raw...${NC}"
    if [[ "$SRC_FILE" == *.sh ]]; then
        local REMOTE_SCRIPT
        REMOTE_SCRIPT=$(curl -sL "$GITHUB_RAW/src/webmin/$SRC_FILE" 2>/dev/null)
        if [ -n "$REMOTE_SCRIPT" ]; then
            ok "Running from GitHub raw"
            bash -c "$REMOTE_SCRIPT"
            return 0
        fi
    fi
    return 1
}

show_banner() {
    clear
    echo -e "${GREEN}"
    cat << "EOF"
 __      __       _ _                 __      __       _ _       _
 \ \    / /      | | |                \ \    / /      (_) |     (_)
  \ \  / /__ _ __| | |__  _ __ ___  _  \ \  / /__ _ __ _| |_ __ _ _ ___
   \ \/ / _ \ '__| | '_ \| '_ \` _ \| |  \ \/ / _ \ '__| | __/ _\ | / __|
    \  /  __/ |  | | |_) | | | | | | |   \  /  __/ |  | | || (_| | \__ \
     \/ \___|_|  |_|_.__/|_| |_| |_|_|    \/ \___|_|  |_|\__\__,_|_|___/
EOF
    echo -e "          ${WHITE}WEBMIN / VIRTUALMIN INSTALLER${NC}"
    echo -e "${HEADER_LINE}"
}

ok()    { echo -e "  ${GREEN}[OK]${NC} $1"; }
step()  { echo -e "\n  ${PURPLE}::${NC} ${WHITE}$1${NC}"; }

show_banner

echo -e "  ${GREEN}[1]${NC} Webmin only"
echo -e "  ${GREEN}[2]${NC} Virtualmin (Webmin + hosting stack)"
echo ""
echo -ne "  ${CYAN}Choose option [1-2]:${NC} "
read choice

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

if [ "$choice" = "1" ]; then
    step "Installing Webmin..."
    if ! download_src "setup-repos.sh"; then
        curl -fsSL https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh | bash
    fi
    apt update && apt install -y webmin
    echo -e "${HEADER_LINE}"
    echo -e "\n  ${CYAN}WEBMIN INSTALLED${NC}"
    echo -e "  ${GRAY}URL :${NC} ${WHITE}https://$(hostname -I | awk '{print $1}'):10000${NC}"
else
    step "Installing Virtualmin..."
    if ! download_src "virtualmin-install.sh"; then
        wget -qN https://software.virtualmin.com/gpl/scripts/virtualmin-install.sh
        bash virtualmin-install.sh
    fi
    echo -e "${HEADER_LINE}"
    echo -e "\n  ${CYAN}VIRTUALMIN INSTALLED${NC}"
    echo -e "  ${GRAY}URL :${NC} ${WHITE}https://$(hostname -I | awk '{print $1}'):10000${NC}"
fi
echo -e "${HEADER_LINE}"
