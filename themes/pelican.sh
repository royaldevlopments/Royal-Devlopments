#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;220m'
NC='\033[0m'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"

pause() {
    echo ""
    echo -ne "  ${GRAY}Press any key to return...${NC}"
    read -n 1 -s -r
}

install_theme() {
    local THEME_NAME="$1"
    local THEME_DIR="$2"
    BDIR="/var/www/pelican"

    if [ ! -d "$BDIR" ]; then
        echo -e "  ${RED}Pelican panel not found at $BDIR${NC}"
        pause
        return
    fi

    echo -e "  ${CYAN}Installing ${THEME_NAME}...${NC}"

    if [ -d "$BDIR/plugins/$THEME_DIR" ]; then
        echo -e "  ${YELLOW}Theme already installed. Replacing...${NC}"
        rm -rf "$BDIR/plugins/$THEME_DIR"
    fi

    local SRC_PATH="$BASE_DIR/thame/Pelican/$THEME_DIR"
    if [ -d "$SRC_PATH" ]; then
        cp -r "$SRC_PATH" "$BDIR/plugins/$THEME_DIR"
        echo -e "  ${GREEN}Copied from local repo${NC}"
    else
        echo -e "  ${YELLOW}Local files not found. Downloading from GitHub...${NC}"
        local ARCHIVE_URL="$GITHUB_RAW/thame/Pelican/$THEME_DIR.tar.gz"
        mkdir -p /tmp/pelican-theme-install
        curl -sL "$ARCHIVE_URL" | tar xz -C /tmp/pelican-theme-install 2>/dev/null
        if [ -d "/tmp/pelican-theme-install/$THEME_DIR" ]; then
            cp -r "/tmp/pelican-theme-install/$THEME_DIR" "$BDIR/plugins/$THEME_DIR"
            rm -rf /tmp/pelican-theme-install
        else
            rm -rf /tmp/pelican-theme-install
            cd "$BDIR/plugins" || return
            git clone --depth=1 "https://github.com/$THEME_DIR" 2>/dev/null || \
            git clone --depth=1 "https://github.com/pelican-dev/plugins.git" _pelican_plugins 2>/dev/null && \
            [ -d "_pelican_plugins/$THEME_DIR" ] && cp -r "_pelican_plugins/$THEME_DIR" . && rm -rf _pelican_plugins
            echo -e "  ${GREEN}Downloaded from GitHub${NC}"
        fi
    fi

    if [ ! -d "$BDIR/plugins/$THEME_DIR" ]; then
        echo -e "  ${RED}Installation failed${NC}"
        pause
        return
    fi

    cd "$BDIR" || return

    echo -e "  ${CYAN}Running migrations...${NC}"
    php artisan migrate --force 2>/dev/null

    echo -e "  ${CYAN}Clearing cache...${NC}"
    php artisan view:clear 2>/dev/null
    php artisan cache:clear 2>/dev/null

    if command -v yarn &>/dev/null; then
        echo -e "  ${CYAN}Building assets...${NC}"
        cd "$BDIR/plugins/$THEME_DIR" && yarn 2>/dev/null && yarn build:production 2>/dev/null
        cd "$BDIR" || return
    fi

    chown -R www-data:www-data "$BDIR" 2>/dev/null
    echo ""
    echo -e "  ${GREEN}${THEME_NAME} installed successfully!${NC}"
    echo -e "  ${GRAY}Go to Admin Panel -> Plugins to activate it.${NC}"
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
    echo -e "  ${GREEN}[1]${NC} StarryNight Theme"
    echo -e "  ${PURPLE}[2]${NC} Neobrutalism Theme  ${GRAY}(Official)${NC}"
    echo -e "  ${CYAN}[3]${NC} Fluffy Theme        ${GRAY}(Official)${NC}"
    echo -e "  ${WHITE}[4]${NC} Nord Theme          ${GRAY}(Official)${NC}"
    echo -e "  ${YELLOW}[5]${NC} Pterodactyl Theme  ${GRAY}(Official)${NC}"
    echo -e "  ${GREEN}[6]${NC} AlienHost Theme"
    echo -e "  ${PURPLE}[7]${NC} Theme Customizer Plugin"
    echo -e "  ${RED}[0]${NC} Back"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${CYAN}Select Option [0-7]:${NC} "
    read p

    case $p in
        1) install_theme "StarryNight" "starrynight" ;;
        2) install_theme "Neobrutalism" "neobrutalism-theme" ;;
        3) install_theme "Fluffy" "fluffy-theme" ;;
        4) install_theme "Nord" "nord-theme" ;;
        5) install_theme "Pterodactyl Theme" "pterodactyl-theme" ;;
        6) install_theme "AlienHost" "alienhost-theme" ;;
        7) install_theme "Theme Customizer" "theme-customizer" ;;
        0) clear; exit ;;
        *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
    esac
    pause
done
