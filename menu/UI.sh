#!/bin/bash
# CODING HUB - OBSIDIAN NEXT GEN (v12.0 - Nobita Edition)
# Style: Modern Glass / Segmented Neo UI / Full Redesign

# --- COLORS (Premium Palette) ---
B_BLUE='\033[1;38;5;33m'
B_CYAN='\033[1;38;5;51m'
B_PURPLE='\033[1;38;5;141m'
B_GREEN='\033[1;38;5;82m'
B_RED='\033[1;38;5;196m'
GOLD='\033[38;5;220m'
W='\033[1;38;5;255m'
G='\033[0;38;5;244m'
BG_SHADE='\033[48;5;236m'
NC='\033[0m'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"

# --- REAL-TIME METRICS ---
get_metrics() {
    CPU=$(top -bn1 | grep "Cpu(s)" | awk '{printf "%.0f", $2+$4}' 2>/dev/null || echo "??")
    RAM=$(free | grep Mem | awk '{printf "%.0f", $3*100/$2}' 2>/dev/null || echo "??")
    UPT=$(uptime -p | sed 's/up //' 2>/dev/null || echo "Unknown")
    DISK=$(df -h / | awk 'NR==2 {print $5}' 2>/dev/null || echo "??")
    CURRENT_HOST=$(hostname)
}

run_script() {
    local script="$1"
    if [ -f "$BASE_DIR/$script" ]; then
        bash "$BASE_DIR/$script"
    else
        bash <(curl -s "$GITHUB_RAW/$script")
    fi
}

# --- MAIN UI RENDERER ---
render_ui() {
    clear
    get_metrics

    echo -e " ${B_BLUE}${NC}${BG_SHADE}${W} $CURRENT_HOST ${NC}${B_BLUE}${NC}  ${B_PURPLE}${NC}${BG_SHADE}${W} $UPT ${NC}${B_PURPLE}${NC}  ${B_GREEN}${NC}${BG_SHADE}${W} $DISK ${NC}${B_GREEN}${NC}  ${B_CYAN}${NC}${BG_SHADE}${W} CPU ${CPU}% RAM ${RAM}%${NC}${B_CYAN}${NC}"
    echo ""

    local WIDTH=$(tput cols 2>/dev/null || echo 80)
    if [ "$WIDTH" -ge 139 ]; then
        echo -e "${B_CYAN}██████  ███████ █     █    █    █          ██████  ███████ █     █ ███████ █       ███████ ██████  █     █ ███████ █     █ ███████  █████  ${NC}"
        echo -e "${B_CYAN}█     █ █     █  █   █    █ █   █          █     █ █       █     █ █       █       █     █ █     █ ██   ██ █       ██    █    █    █     █ ${NC}"
        echo -e "${B_PURPLE}█     █ █     █   █ █    █   █  █          █     █ █       █     █ █       █       █     █ █     █ █ █ █ █ █       █ █   █    █    █       ${NC}"
        echo -e "${B_PURPLE}██████  █     █    █    █     █ █          █     █ █████   █     █ █████   █       █     █ ██████  █  █  █ █████   █  █  █    █     █████  ${NC}"
        echo -e "${GOLD}█   █   █     █    █    ███████ █          █     █ █        █   █  █       █       █     █ █       █     █ █       █   █ █    █          █ ${NC}"
        echo -e "${GOLD}█    █  █     █    █    █     █ █          █     █ █         █ █   █       █       █     █ █       █     █ █       █    ██    █    █     █ ${NC}"
        echo -e "${B_CYAN}█     █ ███████    █    █     █ ███████    ██████  ███████    █    ███████ ███████ ███████ █       █     █ ███████ █     █    █     █████  ${NC}"
        echo -e "${G}ROYAL DEVELOPMENTS — OBSIDIAN NEXT GEN${NC}"
    elif [ "$WIDTH" -ge 106 ]; then
        echo -e "${B_CYAN} ____   _____   __ _    _       ____  _______     _______ _     ___  ____  __  __ _____ _   _ _____ ____  ${NC}"
        echo -e "${B_CYAN}|  _ \ / _ \ \ / // \  | |     |  _ \| ____\ \   / / ____| |   / _ \|  _ \|  \/  | ____| \ | |_   _/ ___| ${NC}"
        echo -e "${B_PURPLE}| |_) | | | \ V // _ \ | |     | | | |  _|  \ \ / /|  _| | |  | | | | |_) | |\/| |  _| |  \| | | | \___ \ ${NC}"
        echo -e "${B_PURPLE}|  _ <| |_| || |/ ___ \| |___  | |_| | |___  \ V / | |___| |__| |_| |  __/| |  | | |___| |\  | | |  ___) |${NC}"
        echo -e "${GOLD}|_| \_\\___/ |_/_/   \_\_____| |____/|_____|  \_/  |_____|_____\___/|_|   |_|  |_|_____|_| \_| |_| |____/ ${NC}"
        echo -e "${G}ROYAL DEVELOPMENTS — OBSIDIAN NEXT GEN${NC}"
    else
        echo -e "${B_CYAN} █▀█ █▀█ █▄█ ▄▀█ █░░  █▀▄ █▀▀ █░█ █▀▀ █░░ █▀█ █▀█ █▄░▄█ █▀▀ █▄░█ ▀█▀ ▄▀▀${NC}"
        echo -e "${B_CYAN} █▀▄ █▄█ ░█░ █▀█ █▄▄  █▄▀ ██▄ ▀▄▀ ██▄ █▄▄ █▄█ █▀▀ █░▀░█ ██▄ █░▀█ ░█░ ▄██${NC}"
        echo -e "${G}ROYAL DEVELOPMENTS — OBSIDIAN NEXT GEN${NC}"
    fi

    echo -e " ${G}────────────────────────────────────────────────────────────────────────────────${NC}"
    echo ""

    echo -e " ${W}SYSTEM STATUS${NC}"
    printf "   ${G}CPU Usage:${NC} ${B_CYAN}%3s%%${NC}     ${G}RAM Usage:${NC} ${B_PURPLE}%3s%%${NC}     ${G}Network:${NC} ${B_GREEN}CONNECTED${NC}\n" "$CPU" "$RAM"
    echo ""

    echo -e " ${B_CYAN}PANEL MANAGEMENT${NC}"
    echo -e " ${G}|-${NC} ${W}[1]${NC} Panel         ${G}|-${NC} ${W}[2]${NC} Wings"
    echo -e " ${G}|-${NC} ${W}[3]${NC} Themes        ${G}|-${NC} ${W}[0]${NC} Exit"
    echo -e "\n ${G}────────────────────────────────────────────────────────────────────────────────${NC}"
    echo -ne " ${B_CYAN}->${NC} ${W}Enter Option${NC} ${G}(0-3):${NC} "
}

# --- MAIN LOOP ---
while true; do
    render_ui
    read -r opt

    case $opt in
        1|panel)
            run_script "panel/1.sh" ;;
        2|wings)
            run_script "wings/1.sh" ;;
        3|themes)
            run_script "themes/1.sh" ;;
        0|exit|quit)
            echo -e "\n ${B_RED}DISCONNECTED${NC}  Goodbye, Nobita."
            exit 0 ;;
        *)
            echo -e "\n ${B_RED}Invalid Option! Please try again.${NC}"
            sleep 0.8 ;;
    esac
done
