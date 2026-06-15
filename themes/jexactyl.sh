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
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"

pause() {
    echo ""
    echo -ne "  ${GRAY}Press any key to return...${NC}"
    read -n 1 -s -r
}

install_jexactyl_theme() {
    local THEME_NAME="$1"
    local THEME_DIR="$2"
    BDIR="/var/www/jexactyl"

    if [ ! -d "$BDIR" ]; then
        echo -e "  ${RED}Jexactyl panel not found at $BDIR${NC}"
        pause
        return
    fi

    cd "$BDIR" || return

    echo -e "  ${CYAN}Installing ${THEME_NAME}...${NC}"

    local LOCAL_SRC="$BASE_DIR/thame/Jexactyl/$THEME_DIR"
    rm -rf /tmp/jexactyl-install

    if [ -d "$LOCAL_SRC" ]; then
        echo -e "  ${GREEN}Using local files from repo${NC}"
        cp -r "$LOCAL_SRC" /tmp/jexactyl-install
    else
        echo -e "  ${YELLOW}Downloading from GitHub...${NC}"
        local ARCHIVE_URL="$GITHUB_RAW/thame/Jexactyl/$THEME_DIR.tar.gz"
        mkdir -p /tmp/jexactyl-install
        curl -sL "$ARCHIVE_URL" | tar xz -C /tmp/jexactyl-install 2>/dev/null
        if [ ! -d "/tmp/jexactyl-install/$THEME_DIR" ]; then
            rm -rf /tmp/jexactyl-install
            git clone --depth=1 "https://github.com/Jexactyl/v2-themes.git" /tmp/jexactyl-install 2>/dev/null
        fi
        if [ -d "/tmp/jexactyl-install/$THEME_DIR" ]; then
            local TMP="/tmp/jexactyl-install/$THEME_DIR"
            mkdir -p /tmp/jexactyl-install-copy
            cp -r "$TMP"/* /tmp/jexactyl-install-copy/ 2>/dev/null
            rm -rf /tmp/jexactyl-install
            mv /tmp/jexactyl-install-copy /tmp/jexactyl-install
        fi
    fi

    if [ ! -d "/tmp/jexactyl-install" ]; then
        echo -e "  ${RED}Download failed! Falling back to CSS-only...${NC}"
        if [ "$THEME_DIR" = "lights-out" ]; then
            jexactyl_apply_css "lights-out" \
"/* Lights Out Dark Theme for Jexactyl */
:root {
    --bg-primary: #0d1117; --bg-secondary: #161b22; --bg-card: #1c2333;
    --text-primary: #e6edf3; --text-secondary: #8b949e;
    --accent: #58a6ff; --border: #30363d;
    --success: #3fb950; --warning: #d29922; --danger: #f85149;
}
body { background: var(--bg-primary); color: var(--text-primary); }
.card, .modal, .box { background: var(--bg-card); border-color: var(--border); }"
        else
            jexactyl_apply_css "flashbang" \
"/* Flashbang Light Theme for Jexactyl */
:root {
    --bg-primary: #ffffff; --bg-secondary: #f6f8fa; --bg-card: #ffffff;
    --text-primary: #1f2328; --text-secondary: #656d76;
    --accent: #0969da; --border: #d0d7de;
    --success: #1a7f37; --warning: #9a6700; --danger: #cf222e;
}
body { background: var(--bg-primary); color: var(--text-primary); }
.card, .modal, .box { background: var(--bg-card); border-color: var(--border); }"
        fi
        return
    fi

    cp -r /tmp/jexactyl-install/* "$BDIR/" 2>/dev/null
    rm -rf /tmp/jexactyl-install

    echo -e "  ${CYAN}Building assets...${NC}"
    command -v yarn &>/dev/null || npm install -g yarn 2>/dev/null
    yarn 2>/dev/null
    yarn build:production 2>/dev/null
    php artisan view:clear 2>/dev/null
    chown -R www-data:www-data "$BDIR" 2>/dev/null
    echo -e "  ${GREEN}${THEME_NAME} installed!${NC}"
}

jexactyl_apply_css() {
    local THEME_NAME="$1"
    local CSS_CONTENT="$2"

    BDIR="/var/www/jexactyl"
    if [ ! -d "$BDIR" ]; then
        echo -e "  ${RED}Jexactyl panel not found at $BDIR${NC}"
        pause
        return
    fi

    cd "$BDIR" || return

    mkdir -p public/themes
    echo "$CSS_CONTENT" > "public/themes/${THEME_NAME}.css"

    echo -e "  ${GREEN}CSS theme applied!${NC}"
    echo -e "  ${GRAY}File: public/themes/${THEME_NAME}.css${NC}"
    echo -e "  ${GRAY}You may need to include it in your layout manually.${NC}"
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
    echo -e "  ${GREEN}[1]${NC} Install Lights Out Theme ${GRAY}(Dark)${NC}"
    echo -e "  ${YELLOW}[2]${NC} Install Flashbang Theme ${GRAY}(Light)${NC}"
    echo -e "  ${PURPLE}[3]${NC} Jexactyl Default Theme ${GRAY}(Reset)${NC}"
    echo -e "  ${CYAN}[4]${NC} Theme Status"
    echo -e "  ${RED}[0]${NC} Back"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${CYAN}Select Option [0-4]:${NC} "
    read p

    case $p in
        1)
            install_jexactyl_theme "Lights Out" "lights-out"
            pause
            ;;
        2)
            install_jexactyl_theme "Flashbang" "flashbang"
            pause
            ;;
        3)
            clear
            echo -e "${YELLOW}Restoring Jexactyl Default Theme...${NC}"
            echo ""
            BDIR="/var/www/jexactyl"
            if [ -d "$BDIR" ]; then
                cd "$BDIR" || exit
                rm -f public/themes/lights-out.css public/themes/flashbang.css 2>/dev/null
                php artisan view:clear 2>/dev/null
                echo -e "  ${GREEN}Default theme restored${NC}"
            else
                echo -e "  ${RED}Jexactyl not found${NC}"
            fi
            pause
            ;;
        4)
            clear
            echo -e "${YELLOW}Jexactyl Theme Status${NC}"
            echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
            echo ""
            BDIR="/var/www/jexactyl"
            if [ ! -d "$BDIR" ]; then
                echo -e "  ${RED}Jexactyl not found${NC}"
            else
                if [ -f "$BDIR/public/themes/lights-out.css" ]; then
                    echo -e "  ${GREEN}[INSTALLED]${NC} Lights Out Theme (Dark)"
                fi
                if [ -f "$BDIR/public/themes/flashbang.css" ]; then
                    echo -e "  ${GREEN}[INSTALLED]${NC} Flashbang Theme (Light)"
                fi
                if [ ! -f "$BDIR/public/themes/lights-out.css" ] && [ ! -f "$BDIR/public/themes/flashbang.css" ]; then
                    echo -e "  ${YELLOW}[DEFAULT]${NC} No custom theme installed"
                fi
                echo -e "  ${GRAY}Jexactyl has built-in customization in Admin Panel${NC}"
            fi
            pause
            ;;
        0) clear; exit ;;
        *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
    esac
done
