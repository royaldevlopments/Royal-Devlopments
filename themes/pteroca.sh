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

install_noirui() {
    clear
    echo -e "${YELLOW}Installing NoirUI Theme for PteroCA...${NC}"
    echo ""

    local PTEROCA_DIR
    if [ -d "/var/www/pteroca" ]; then
        PTEROCA_DIR="/var/www/pteroca"
    elif [ -d "/var/www/pteroca/public" ]; then
        PTEROCA_DIR="/var/www/pteroca"
    else
        echo -ne "  ${CYAN}Enter PteroCA installation path:${NC} "
        read PTEROCA_DIR
    fi

    if [ ! -d "$PTEROCA_DIR" ]; then
        echo -e "  ${RED}Directory not found: $PTEROCA_DIR${NC}"
        pause
        return
    fi

    cd "$PTEROCA_DIR" || return

    local NOIRUI_SRC="$BASE_DIR/thame/PteroCA/noirui"
    if [ -d "$NOIRUI_SRC" ]; then
        echo -e "  ${GREEN}Using local files from repo${NC}"
        rm -rf /tmp/noirui-install
        cp -r "$NOIRUI_SRC" /tmp/noirui-install
    else
        echo -e "  ${YELLOW}Downloading NoirUI Theme from GitHub...${NC}"
        rm -rf /tmp/noirui-install
        local ARCHIVE_URL="$GITHUB_RAW/thame/PteroCA/noirui.tar.gz"
        mkdir -p /tmp/noirui-install
        curl -sL "$ARCHIVE_URL" | tar xz -C /tmp/noirui-install 2>/dev/null
        if [ ! -d "/tmp/noirui-install/noirui" ]; then
            rm -rf /tmp/noirui-install
            git clone --depth=1 "https://github.com/austndoesui/NoirUI-pteroca-theme.git" /tmp/noirui-install 2>/dev/null
        fi
    fi

    if [ ! -d "/tmp/noirui-install/noirui" ] && [ ! -d "/tmp/noirui-install/themes" ]; then
        echo -e "  ${RED}Download failed!${NC}"
        rm -rf /tmp/noirui-install
        pause
        return
    fi

    local INSTALL_DIR="/tmp/noirui-install"
    if [ -d "$INSTALL_DIR/noirui/themes" ]; then
        INSTALL_DIR="$INSTALL_DIR/noirui"
    fi

    echo -e "  ${CYAN}Backing up current theme...${NC}"
    if [ -d "$PTEROCA_DIR/themes/noirui" ]; then
        mv "$PTEROCA_DIR/themes/noirui" "$PTEROCA_DIR/themes/noirui.bak.$(date +%s)"
        echo -e "  ${GRAY}Backup created${NC}"
    fi

    echo -e "  ${CYAN}Copying theme files...${NC}"
    cp -r "$INSTALL_DIR/themes/noirui" "$PTEROCA_DIR/themes/" 2>/dev/null
    if [ -d "$INSTALL_DIR/public/assets/theme/noirui" ]; then
        cp -r "$INSTALL_DIR/public/assets/theme/noirui" "$PTEROCA_DIR/public/assets/theme/" 2>/dev/null
    fi

    echo -e "  ${CYAN}Setting permissions...${NC}"
    chown -R www-data:www-data "$PTEROCA_DIR/themes/noirui" 2>/dev/null
    chown -R www-data:www-data "$PTEROCA_DIR/public/assets/theme/noirui" 2>/dev/null

    echo -e "  ${CYAN}Clearing cache...${NC}"
    cd "$PTEROCA_DIR" || return
    php bin/console cache:clear 2>/dev/null
    php bin/console cache:warmup 2>/dev/null

    rm -rf /tmp/noirui-install

    echo ""
    echo -e "  ${GREEN}NoirUI Theme Installed!${NC}"
    echo -e "  ${GRAY}To activate:${NC}"
    echo -e "  ${GRAY}1. Go to Admin Panel -> Settings -> Theme Settings${NC}"
    echo -e "  ${GRAY}2. Select 'NoirUI' from dropdown${NC}"
    echo -e "  ${GRAY}3. Save changes${NC}"
}

remove_noirui() {
    clear
    echo -e "${YELLOW}Removing NoirUI Theme...${NC}"
    echo ""

    local PTEROCA_DIR
    if [ -d "/var/www/pteroca" ]; then
        PTEROCA_DIR="/var/www/pteroca"
    else
        echo -ne "  ${CYAN}Enter PteroCA installation path:${NC} "
        read PTEROCA_DIR
    fi

    if [ ! -d "$PTEROCA_DIR" ]; then
        echo -e "  ${RED}Directory not found${NC}"
        pause
        return
    fi

    echo -ne "  ${YELLOW}Remove NoirUI theme? [y/N]:${NC} "
    read confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "  ${YELLOW}Cancelled${NC}"
        pause
        return
    fi

    rm -rf "$PTEROCA_DIR/themes/noirui" 2>/dev/null
    rm -rf "$PTEROCA_DIR/public/assets/theme/noirui" 2>/dev/null
    cd "$PTEROCA_DIR" || return
    php bin/console cache:clear 2>/dev/null
    php bin/console cache:warmup 2>/dev/null

    echo -e "  ${GREEN}NoirUI removed. Default theme restored.${NC}"
}

create_custom_theme() {
    clear
    echo -e "${YELLOW}Create Custom PteroCA Theme${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${CYAN}Theme name:${NC} "
    read THEME_NAME

    if [ -z "$THEME_NAME" ]; then
        echo -e "  ${RED}Name cannot be empty${NC}"
        pause
        return
    fi

    local SLUG="${THEME_NAME// /_}"
    SLUG="${SLUG,,}"

    local PTEROCA_DIR
    if [ -d "/var/www/pteroca" ]; then
        PTEROCA_DIR="/var/www/pteroca"
    else
        echo -e "  ${RED}PteroCA not found${NC}"
        pause
        return
    fi

    mkdir -p "$PTEROCA_DIR/themes/$SLUG"
    mkdir -p "$PTEROCA_DIR/public/assets/theme/$SLUG/css"
    mkdir -p "$PTEROCA_DIR/public/assets/theme/$SLUG/js"
    mkdir -p "$PTEROCA_DIR/public/assets/theme/$SLUG/img"

    cat > "$PTEROCA_DIR/themes/$SLUG/template.json" << EOF
{
    "template": {
        "name": "$SLUG",
        "description": "$THEME_NAME - Custom theme",
        "author": "Royal-Devlopments",
        "version": "1.0.0",
        "license": "MIT",
        "pterocaVersion": "0.6.5",
        "phpVersion": ">=8.2",
        "contexts": ["panel", "landing", "email"],
        "translations": [],
        "options": {
            "supportDarkMode": true,
            "supportCustomColors": true
        }
    }
}
EOF

    cat > "$PTEROCA_DIR/themes/$SLUG/base.html.twig" << 'TWIG'
<!DOCTYPE html>
<html lang="{{ app.request.locale }}">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}{% endblock %} | {{ config('app.name') }}</title>
    <link rel="stylesheet" href="{{ asset('assets/theme/' ~ theme.active ~ '/css/theme.css') }}">
    {% block stylesheets %}{% endblock %}
</head>
<body>
    {% block body %}{% endblock %}
    <script src="{{ asset('assets/theme/' ~ theme.active ~ '/js/theme.js') }}"></script>
    {% block javascripts %}{% endblock %}
</body>
</html>
TWIG

    cat > "$PTEROCA_DIR/public/assets/theme/$SLUG/css/theme.css" << 'CSS'
:root {
    --primary: #6366f1;
    --primary-hover: #4f46e5;
    --bg: #0f172a;
    --bg-card: #1e293b;
    --text: #f1f5f9;
    --text-muted: #94a3b8;
    --border: #334155;
    --radius: 8px;
}

body {
    background: var(--bg);
    color: var(--text);
    font-family: 'Inter', system-ui, sans-serif;
}

.card {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: var(--radius);
}

.btn-primary {
    background: var(--primary);
    color: white;
    border: none;
    border-radius: var(--radius);
    padding: 8px 16px;
}

.btn-primary:hover {
    background: var(--primary-hover);
}
CSS

    chown -R www-data:www-data "$PTEROCA_DIR/themes/$SLUG" "$PTEROCA_DIR/public/assets/theme/$SLUG" 2>/dev/null

    echo ""
    echo -e "  ${GREEN}Theme '$THEME_NAME' created!${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo -e "  ${WHITE}Theme structure:${NC}"
    echo -e "  ${GRAY}  $PTEROCA_DIR/themes/$SLUG/${NC}"
    echo -e "  ${GRAY}    ├── template.json      ${GRAY}(Theme manifest)${NC}"
    echo -e "  ${GRAY}    └── base.html.twig     ${GRAY}(Layout template)${NC}"
    echo -e "  ${GRAY}  $PTEROCA_DIR/public/assets/theme/$SLUG/${NC}"
    echo -e "  ${GRAY}    ├── css/theme.css      ${GRAY}(Edit this to style your theme)${NC}"
    echo -e "  ${GRAY}    ├── js/                ${GRAY}(Add custom JS here)${NC}"
    echo -e "  ${GRAY}    └── img/               ${GRAY}(Add images here)${NC}"
    echo ""
    echo -e "  ${YELLOW}Next steps:${NC}"
    echo -e "  ${GRAY}1.${NC} Edit ${GREEN}css/theme.css${NC} to change colors, fonts, layout"
    echo -e "  ${GRAY}2.${NC} Edit ${GREEN}base.html.twig${NC} to customize HTML structure"
    echo -e "  ${GRAY}3.${NC} Add more Twig files to ${GREEN}themes/$SLUG/${NC} as needed"
    echo -e "  ${GRAY}4.${NC} Go to ${GREEN}Admin -> Settings -> Theme Settings${NC}"
    echo -e "  ${GRAY}5.${NC} Select your theme from the dropdown"
    echo -e "  ${GRAY}6.${NC} Click Save and reload the page"
    echo ""
    echo -e "  ${PURPLE}Tip:${NC} Use Chrome DevTools to inspect elements and"
    echo -e "  ${GRAY}find the CSS classes you want to override.${NC}"
}

while true; do
    clear
    echo -e "${PURPLE}"
    echo -e "   ____      _           _               _     "
    echo -e "  |  _ \ ___| |__   __ _| | ___   __ _  | |    "
    echo -e "  | |_) / _ \ '_ \ / _\ | |/ _ \ / _\ | | |    "
    echo -e "  |  _ <  __/ | | | (_| | | (_) | (_| | | |    "
    echo -e "  |_| \_\___|_| |_|\__,_|_|\___/ \__,_| |_|    "
    echo -e "${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo -e "  ${GREEN}[1]${NC} Install NoirUI Theme ${GRAY}(recommended)${NC}"
    echo -e "  ${RED}[2]${NC} Remove NoirUI Theme"
    echo -e "  ${CYAN}[3]${NC} Create Custom Theme"
    echo -e "  ${YELLOW}[4]${NC} Theme Status"
    echo -e "  ${RED}[0]${NC} Back"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${CYAN}Select Option [0-4]:${NC} "
    read p

    case $p in
        1) install_noirui ;;
        2) remove_noirui ;;
        3) create_custom_theme ;;
        4)
            clear
            echo -e "${YELLOW}PteroCA Theme Status${NC}"
            echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
            echo ""
            if [ -d "/var/www/pteroca/themes/noirui" ]; then
                echo -e "  ${GREEN}[INSTALLED]${NC} NoirUI Theme"
            else
                echo -e "  ${YELLOW}[NOT INSTALLED]${NC} NoirUI Theme"
            fi
            echo -e "  ${GRAY}Available themes:${NC}"
            ls -1 /var/www/pteroca/themes/ 2>/dev/null | while IFS= read -r theme; do
                echo -e "  ${GRAY}-${NC} $theme"
            done
            if [ ! -d "/var/www/pteroca" ]; then
                echo -e "  ${RED}PteroCA not found${NC}"
            fi
            pause
            ;;
        0) clear; exit ;;
        *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
    esac
    pause
done
