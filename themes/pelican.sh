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

pelican_theme_install() {
    local THEME_NAME="$1"
    local THEME_DIR="$2"
    BDIR="/var/www/pelican"

    if [ ! -d "$BDIR" ]; then
        echo -e "  ${RED}Pelican panel not found at $BDIR${NC}"
        pause
        return 1
    fi

    cd "$BDIR" || return 1

    echo -e "  ${CYAN}Installing ${THEME_NAME}...${NC}"

    if [ -d "$BDIR/plugins/$THEME_DIR" ]; then
        echo -e "  ${YELLOW}Theme already installed. Updating...${NC}"
        rm -rf "$BDIR/plugins/$THEME_DIR"
    fi

    mkdir -p plugins
    cd plugins || return 1

    git clone --depth=1 "https://github.com/pelican-dev/plugins.git" pelican-plugins-repo 2>/dev/null

    if [ -d "pelican-plugins-repo/$THEME_DIR" ]; then
        cp -r "pelican-plugins-repo/$THEME_DIR" "$THEME_DIR"
        rm -rf pelican-plugins-repo
        cd "$BDIR" || return 1

        echo -e "  ${CYAN}Running migration...${NC}"
        php artisan migrate --force 2>/dev/null

        echo -e "  ${CYAN}Clearing cache...${NC}"
        php artisan view:clear 2>/dev/null
        php artisan cache:clear 2>/dev/null

        if command -v yarn &>/dev/null; then
            echo -e "  ${CYAN}Rebuilding assets...${NC}"
            yarn 2>/dev/null
            yarn build:production 2>/dev/null
        fi

        chown -R www-data:www-data "$BDIR" 2>/dev/null
        echo -e "  ${GREEN}${THEME_NAME} installed!${NC}"
        echo -e "  ${GRAY}Go to Admin Panel -> Plugins to activate it.${NC}"
    else
        rm -rf pelican-plugins-repo
        echo -e "  ${RED}Theme not found in plugins repo${NC}"
        return 1
    fi
}

pelican_hub_install() {
    local PLUGIN_ID="$1"
    local THEME_NAME="$2"
    BDIR="/var/www/pelican"

    if [ ! -d "$BDIR" ]; then
        echo -e "  ${RED}Pelican panel not found at $BDIR${NC}"
        pause
        return 1
    fi

    cd "$BDIR" || return 1

    echo -e "  ${CYAN}Installing ${THEME_NAME} from Pelican Hub...${NC}"
    echo -e "  ${YELLOW}Visit https://hub.pelican.dev/plugins/${PLUGIN_ID}${NC}"
    echo -e "  ${YELLOW}Login with Discord and click Install${NC}"
    echo ""
    echo -e "  ${WHITE}Or install manually:${NC}"
    echo -e "  ${GRAY}1. Download the plugin zip from Hub${NC}"
    echo -e "  ${GRAY}2. Upload via Admin Panel -> Plugins -> Import${NC}"
    echo ""
    echo -ne "  ${YELLOW}Open Hub page in browser? [y/N]:${NC} "
    read confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        if command -v xdg-open &>/dev/null; then
            xdg-open "https://hub.pelican.dev/plugins/${PLUGIN_ID}" 2>/dev/null
        elif command -v sensible-browser &>/dev/null; then
            sensible-browser "https://hub.pelican.dev/plugins/${PLUGIN_ID}" 2>/dev/null
        else
            echo -e "  ${YELLOW}Open this URL: https://hub.pelican.dev/plugins/${PLUGIN_ID}${NC}"
        fi
    fi
    echo -e "  ${GREEN}Done!${NC}"
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
        1) pelican_hub_install "starrynight" "StarryNight" ;;
        2) pelican_hub_install "neobrutalism-theme" "Neobrutalism" ;;
        3) pelican_hub_install "fluffy-theme" "Fluffy" ;;
        4) pelican_hub_install "nord-theme" "Nord" ;;
        5) pelican_hub_install "pterodactyl-theme" "Pterodactyl Theme" ;;
        6) pelican_hub_install "alienhost-theme" "AlienHost" ;;
        7)
            clear
            echo -e "${YELLOW}Theme Customizer${NC}"
            echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
            echo ""
            BDIR="/var/www/pelican"
            if [ ! -d "$BDIR" ]; then
                echo -e "  ${RED}Pelican panel not found${NC}"
            else
                cd "$BDIR" || exit
                echo -e "  ${CYAN}Installing Theme Customizer...${NC}"
                mkdir -p plugins
                cd plugins || exit
                git clone --depth=1 "https://github.com/pelican-dev/plugins.git" pelican-plugins 2>/dev/null
                if [ -d "pelican-plugins/theme-customizer" ]; then
                    cp -r "pelican-plugins/theme-customizer" .
                    rm -rf pelican-plugins
                    cd "$BDIR" || exit
                    php artisan migrate --force 2>/dev/null
                    php artisan view:clear 2>/dev/null
                    chown -R www-data:www-data "$BDIR" 2>/dev/null
                    echo -e "  ${GREEN}Theme Customizer installed!${NC}"
                    echo -e "  ${GRAY}Go to Admin -> Plugins -> Theme Customizer to change colors/fonts${NC}"
                else
                    rm -rf pelican-plugins
                    echo -e "  ${RED}Download failed${NC}"
                fi
            fi
            pause
            ;;
        0) clear; exit ;;
        *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
    esac
    pause
done
