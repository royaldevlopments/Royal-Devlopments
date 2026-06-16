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
    local SRC_FILE="install.sh"
    local LOCAL_PATH="$BASE_DIR/src/virtualizor/$SRC_FILE"

    if [ -f "$LOCAL_PATH" ]; then
        cp "$LOCAL_PATH" /root/install
        ok "Copied from local repo"
        return 0
    fi

    echo -e "  ${YELLOW}Local source not found. Trying GitHub raw...${NC}"
    if curl -sL "$GITHUB_RAW/src/virtualizor/$SRC_FILE" -o /root/install 2>/dev/null; then
        ok "Downloaded from GitHub raw"
        return 0
    fi

    echo -e "  ${YELLOW}Trying upstream...${NC}"
    wget -qN https://www.virtualizor.com/install -O /root/install
}

show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
 __   _____     _ _ _           _
 \ \ / /__ \ __| (_) |_ ___  __| |___
  \ V /  / / '__| | | __/ _ \/ _  / __|
   | |  / /| |  | | | ||  __/ (_| \__ \
   |_| |_| |_|  |_|_|\__\___|\__,_|___/
EOF
    echo -e "           ${WHITE}VIRTUALIZOR INSTALLER${NC}"
    echo -e "${HEADER_LINE}"
    echo -e "  ${GOLD}Virtualizor is a commercial product by Softaculous.${NC}"
    echo -e "  ${GOLD}A valid license key is required.${NC}"
}

ok()    { echo -e "  ${GREEN}[OK]${NC} $1"; }
step()  { echo -e "\n  ${PURPLE}::${NC} ${WHITE}$1${NC}"; }

show_banner

while true; do
    echo -ne "\n  ${CYAN}Start Virtualizor Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

step "Downloading Virtualizor installer..."
cd /root
download_src

step "Running Virtualizor installer..."
echo -e "  ${GOLD}Follow the interactive prompts to complete installation.${NC}"
bash install

echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}VIRTUALIZOR INSTALLED${NC}"
echo -e "  ${GRAY}Admin URL :${NC} ${WHITE}https://$(hostname -I | awk '{print $1}'):4085${NC}"
echo -e "${HEADER_LINE}"
