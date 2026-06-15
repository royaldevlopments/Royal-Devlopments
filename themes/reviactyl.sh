#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;220m'
BLUE='\033[38;5;39m'
NC='\033[0m'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"

pause() {
    echo ""
    echo -ne "  ${GRAY}Press any key to return...${NC}"
    read -n 1 -s -r
}

show_theme_selector_info() {
    clear
    echo -e "${CYAN}Reviactyl Client-Side Theme Selector${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${WHITE}Reviactyl includes a built-in Client-Side Theme Selector.${NC}"
    echo ""
    echo -e "  ${GREEN}To use it:${NC}"
    echo -e "  ${GRAY}1.${NC} Go to Admin Panel -> Appearance -> Theme Selector"
    echo -e "  ${GRAY}2.${NC} Choose from available themes"
    echo -e "  ${GRAY}3.${NC} Customize colors via the built-in color picker"
    echo ""
    echo -e "  ${YELLOW}Available built-in themes:${NC}"
    echo -e "  ${GRAY}-${NC} Default (Light)"
    echo -e "  ${GRAY}-${NC} Dark Mode"
    echo -e "  ${GRAY}-${NC} Midnight Blue"
    echo -e "  ${GRAY}-${NC} Forest Green"
    echo -e "  ${GRAY}-${NC} Royal Purple"
    echo -e "  ${GRAY}-${NC} Sunset Orange"
    echo ""
    echo -e "  ${WHITE}No external themes are needed!${NC}"
}

show_designify_info() {
    clear
    echo -e "${PURPLE}Reviactyl Designify Editor${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${WHITE}Reviactyl has a built-in Designify Editor for CSS customization.${NC}"
    echo ""
    echo -e "  ${GREEN}To access:${NC}"
    echo -e "  ${GRAY}1.${NC} Go to Admin Panel -> Appearance -> Designify"
    echo -e "  ${GRAY}2.${NC} Edit CSS/HTML in real-time"
    echo -e "  ${GRAY}3.${NC} Preview changes live before saving"
    echo ""
    echo -e "  ${YELLOW}You can add custom CSS for:${NC}"
    echo -e "  ${GRAY}-${NC} Background colors & gradients"
    echo -e "  ${GRAY}-${NC} Font families & sizing"
    echo -e "  ${GRAY}-${NC} Button styles & animations"
    echo -e "  ${GRAY}-${NC} Logo & brand colors"
    echo -e "  ${GRAY}-${NC} Custom dashboard layouts"
}

install_blueprint_theme() {
    clear
    echo -e "${YELLOW}Blueprint Theme Compatibility${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -e "  ${WHITE}Reviactyl is based on Pterodactyl 1.x and supports the${NC}"
    echo -e "  ${WHITE}Blueprint theme framework for basic CSS theming.${NC}"
    echo ""

    BDIR="/var/www/reviactyl"
    if [ ! -d "$BDIR" ]; then
        echo -ne "  ${CYAN}Enter Reviactyl installation path:${NC} "
        read BDIR
        if [ ! -d "$BDIR" ]; then
            echo -e "  ${RED}Directory not found${NC}"
            pause
            return
        fi
    fi

    echo -e "  ${GREEN}Available Blueprint extensions in repository:${NC}"
    echo ""

    if [ -d "$BASE_DIR/thame/Extension" ]; then
        local count=0
        for ext in "$BASE_DIR"/thame/Extension/*; do
            local name
            name=$(basename "$ext" .blueprint 2>/dev/null)
            if [ -n "$name" ]; then
                count=$((count + 1))
                echo -e "  ${GRAY}-${NC} $name"
            fi
        done
        if [ "$count" -eq 0 ]; then
            echo -e "  ${YELLOW}No extensions found${NC}"
        fi
    else
        echo -e "  ${YELLOW}No Blueprint extensions bundled${NC}"
    fi

    echo ""
    echo -e "  ${YELLOW}To install Blueprint on Reviactyl:${NC}"
    echo -e "  ${GRAY}1.${NC} Blueprint v3.5.2 (not latest) is required"
    echo -e "  ${GRAY}2.${NC} Download from: github.com/BlueprintFramework/framework"
    echo -e "  ${GRAY}3.${NC} Follow normal Blueprint installation for Pterodactyl"
    echo ""
    echo -e "  ${RED}WARNING:${NC} Blueprint compatibility with Reviactyl is NOT guaranteed."
    echo -e "  ${GRAY}Some extensions may not work properly. Backup first!${NC}"
}

while true; do
    clear
    echo -e "${BLUE}"
    echo -e "   ____      _ _           _ _              _ _ _     "
    echo -e "  |  _ \ ___(_) |_ ___  __| (_) ___   __ _(_) | |_   "
    echo -e "  | |_) / _ \ | __/ _ \/ _\ | |/ __| / _\ | | | __|  "
    echo -e "  |  _ <  __/ | ||  __/ (_| | | (__ | (_| | | | |_   "
    echo -e "  |_| \_\___|_|\__\___|\__,_|_|\___| \__,_|_|_|\__|  "
    echo -e "${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}[1]${NC} Client-Side Theme Selector ${GRAY}(Info)${NC}"
    echo -e "  ${PURPLE}[2]${NC} Designify Editor ${GRAY}(CSS Customizer)${NC}"
    echo -e "  ${YELLOW}[3]${NC} Blueprint Theme Compatibility"
    echo -e "  ${CYAN}[4]${NC} Theme Status"
    echo -e "  ${RED}[0]${NC} Back"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${CYAN}Select Option [0-4]:${NC} "
    read p

    case $p in
        1) show_theme_selector_info ;;
        2) show_designify_info ;;
        3) install_blueprint_theme ;;
        4)
            clear
            echo -e "${YELLOW}Reviactyl Theme Status${NC}"
            echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
            echo ""
            BDIR="/var/www/reviactyl"
            if [ -d "$BDIR" ]; then
                echo -e "  ${GREEN}[INSTALLED]${NC} Reviactyl Panel"
                echo -e "  ${GRAY}Theme system:${NC} Built-in Client-Side Theme Selector"
                echo -e "  ${GRAY}Designify:${NC} Built-in CSS/HTML editor"
                echo ""
                echo -e "  ${WHITE}Reviactyl does not need external themes.${NC}"
                echo -e "  ${WHITE}Use the Admin Panel to customize appearance.${NC}"
            else
                echo -e "  ${YELLOW}Reviactyl not installed yet${NC}"
                echo -e "  ${GRAY}Install via main menu first${NC}"
            fi
            pause
            ;;
        0) clear; exit ;;
        *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
    esac
    pause
done
