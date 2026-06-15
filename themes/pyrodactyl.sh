#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;220m'
ORANGE='\033[38;5;208m'
NC='\033[0m'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"

pause() {
    echo ""
    echo -ne "  ${GRAY}Press any key to return...${NC}"
    read -n 1 -s -r
}

list_bundled_extensions() {
    echo -e "  ${CYAN}Bundled Blueprint Extensions:${NC}"
    echo ""

    if [ -d "$BASE_DIR/thame/Extension" ]; then
        local count=0
        for ext in "$BASE_DIR"/thame/Extension/*; do
            if [ -f "$ext" ]; then
                local name
                name=$(basename "$ext" .blueprint 2>/dev/null)
                if [ -n "$name" ] && [ "$name" != "*" ]; then
                    count=$((count + 1))
                    echo -e "  ${GRAY}-${NC} $name"
                fi
            fi
        done
        if [ "$count" -eq 0 ]; then
            echo -e "  ${YELLOW}No extensions found in thame/Extension/${NC}"
        else
            echo -e ""
            echo -e "  ${GRAY}Total: $count extensions${NC}"
        fi
    else
        echo -e "  ${YELLOW}Directory thame/Extension/ not found${NC}"
        echo -e "  ${GRAY}Some Blueprint extensions may still be available${NC}"
    fi
}

install_blueprint_extension() {
    clear
    echo -e "${YELLOW}Install Blueprint Extension${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""

    BDIR="/var/www/pyrodactyl"
    if [ ! -d "$BDIR" ]; then
        echo -ne "  ${CYAN}Enter Pyrodactyl path:${NC} "
        read BDIR
        if [ ! -d "$BDIR" ]; then
            echo -e "  ${RED}Directory not found${NC}"
            pause
            return
        fi
    fi

    if [ ! -f "$BDIR/blueprint.json" ]; then
        echo -e "  ${RED}Blueprint not detected at $BDIR${NC}"
        echo -e "  ${YELLOW}Blueprint must be installed first!${NC}"
        echo ""
        echo -e "  ${GRAY}Pyrodactyl's Blueprint fork is archived.${NC}"
        echo -e "  ${GRAY}Use Blueprint v3.5.2 from github.com/BlueprintFramework/framework${NC}"
        echo -ne "  ${CYAN}Continue anyway? [y/N]:${NC} "
        read confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            return
        fi
    fi

    list_bundled_extensions
    echo ""
    echo -ne "  ${CYAN}Enter extension filename (without .blueprint):${NC} "
    read EXT_NAME

    if [ -z "$EXT_NAME" ]; then
        echo -e "  ${RED}No name entered${NC}"
        pause
        return
    fi

    local EXT_FILE="$BASE_DIR/thame/Extension/${EXT_NAME}.blueprint"
    if [ ! -f "$EXT_FILE" ]; then
        echo -e "  ${RED}Extension '$EXT_NAME.blueprint' not found in thame/Extension/${NC}"
        pause
        return
    fi

    cp "$EXT_FILE" "$BDIR/"
    cd "$BDIR" || return

    if command -v blueprint &>/dev/null; then
        blueprint extensions:import "${EXT_NAME}.blueprint" 2>/dev/null
        echo -e "  ${GREEN}Extension '$EXT_NAME' imported via Blueprint CLI!${NC}"
    else
        echo -e "  ${YELLOW}Blueprint CLI not found. File copied to $BDIR${NC}"
        echo -e "  ${GRAY}Import manually: blueprint extensions:import ${EXT_NAME}.blueprint${NC}"
    fi

    chown -R www-data:www-data "$BDIR" 2>/dev/null
}

install_blueprint_framework() {
    clear
    echo -e "${YELLOW}Install Blueprint Framework on Pyrodactyl${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""

    BDIR="/var/www/pyrodactyl"
    if [ ! -d "$BDIR" ]; then
        echo -ne "  ${CYAN}Enter Pyrodactyl path:${NC} "
        read BDIR
        if [ ! -d "$BDIR" ]; then
            echo -e "  ${RED}Directory not found${NC}"
            pause
            return
        fi
    fi

    echo -e "  ${YELLOW}Note: Pyrodactyl's own Blueprint fork is archived.${NC}"
    echo -e "  ${YELLOW}Using standard Blueprint Framework v3.5.2 instead.${NC}"
    echo ""
    echo -e "  ${WHITE}This installs Blueprint on your Pyrodactyl panel so you${NC}"
    echo -e "  ${WHITE}can use the bundled extensions from thame/Extension/.${NC}"
    echo ""
    echo -ne "  ${CYAN}Install Blueprint? [y/N]:${NC} "
    read confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "  ${YELLOW}Cancelled${NC}"
        pause
        return
    fi

    cd "$BDIR" || return

    bash <(curl -sL https://raw.githubusercontent.com/BlueprintFramework/framework/main/install.sh) 2>/dev/null

    if [ -f "$BDIR/blueprint.json" ]; then
        echo -e "  ${GREEN}Blueprint installed on Pyrodactyl!${NC}"
        echo -e "  ${GRAY}You can now install extensions from thame/Extension/${NC}"
    else
        echo -e "  ${RED}Blueprint installation may have failed${NC}"
        echo -e "  ${YELLOW}Try visiting: https://github.com/BlueprintFramework/framework${NC}"
    fi
}

while true; do
    clear
    echo -e "${ORANGE}"
    echo -e "   ____       _           _           _ _ _     "
    echo -e "  |  _ \ _   _| | ___  ___| |_ __ __ _(_) | |_  "
    echo -e "  | |_) | | | | |/ _ \/ __| __/ __/ _\ | | | __| "
    echo -e "  |  __/| |_| | | (_) \__ \ || (_| (_| | | | |_  "
    echo -e "  |_|    \__, |_|\___/|___/\__\___\__,_|_|_|\__| "
    echo -e "         |___/                                    "
    echo -e "${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}[1]${NC} List Bundled Blueprint Extensions"
    echo -e "  ${CYAN}[2]${NC} Install Blueprint Extension"
    echo -e "  ${PURPLE}[3]${NC} Install Blueprint Framework"
    echo -e "  ${YELLOW}[4]${NC} Theme Status"
    echo -e "  ${RED}[0]${NC} Back"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${CYAN}Select Option [0-4]:${NC} "
    read p

    case $p in
        1)
            clear
            echo -e "${YELLOW}Bundled Blueprint Extensions${NC}"
            echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
            echo ""
            list_bundled_extensions
            pause
            ;;
        2) install_blueprint_extension ;;
        3) install_blueprint_framework ;;
        4)
            clear
            echo -e "${YELLOW}Pyrodactyl Theme Status${NC}"
            echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
            echo ""
            BDIR="/var/www/pyrodactyl"
            if [ -d "$BDIR" ]; then
                echo -e "  ${GREEN}[INSTALLED]${NC} Pyrodactyl Panel"
                if [ -f "$BDIR/blueprint.json" ]; then
                    echo -e "  ${GREEN}[BLUEPRINT]${NC} Framework detected"
                    echo -e "  ${GRAY}Extensions can be imported${NC}"
                else
                    echo -e "  ${YELLOW}[NO BLUEPRINT]${NC} Framework not installed"
                    echo -e "  ${GRAY}Install Blueprint (Option 3) first${NC}"
                fi
            else
                echo -e "  ${YELLOW}Pyrodactyl not installed yet${NC}"
                echo -e "  ${GRAY}Install via main menu first${NC}"
            fi
            pause
            ;;
        0) clear; exit ;;
        *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
    esac
    pause
done
