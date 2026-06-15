#!/bin/bash
# PTERODACTYL CONTROL CENTER v2.1

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
BOLD='\033[1m'
NC='\033[0m'
GRAY='\033[0;90m'

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
BASE_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
GITHUB_RAW="https://raw.githubusercontent.com/nobita329/Nobita-Cloud/main"

run_script() {
    local script="$1"
    if [ -f "$BASE_DIR/$script" ]; then
        bash "$BASE_DIR/$script"
    else
        bash <(curl -s "$GITHUB_RAW/$script")
    fi
}

show_header() {
    clear
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${PURPLE}║${NC}         ${BOLD}${WHITE}PTERODACTYL SERVER MANAGEMENT SYSTEM${NC}             ${PURPLE}║${NC}"
    echo -e "${PURPLE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN}  Current Module: ${YELLOW}$1${NC}"
    echo -e "${PURPLE}────────────────────────────────────────────────────────────${NC}"
    echo ""
}

status_msg() {
    case $1 in
        "OK")   echo -e "  [${GREEN} + ${NC}] $2" ;;
        "ERR")  echo -e "  [${RED} - ${NC}] $2" ;;
        "INFO") echo -e "  [${CYAN} > ${NC}] $2" ;;
        "WAIT") echo -e "  [${YELLOW} .. ${NC}] $2" ;;
    esac
}

pause() {
    echo ""
    read -p "  Press [Enter] to return to main menu..."
}

install_ptero() {
    show_header "PANEL INSTALLATION"
    status_msg "INFO" "Initiating installation script..."
    sleep 1
    run_script "panel/pterodactyl/install.sh"
    echo ""
    status_msg "OK" "Installation Sequence Complete."
    pause
}

create_user() {
    show_header "USER MANAGEMENT"
    if [ ! -d /var/www/pterodactyl ]; then
        status_msg "ERR" "Panel directory not found (/var/www/pterodactyl)."
        pause
        return
    fi
    echo ""
    echo "1) Custom User Create"
    echo "2) Auto Create Admin User"
    echo ""
    read -p "Choose option: " choice
    cd /var/www/pterodactyl || exit
    if [ "$choice" = "1" ]; then
        status_msg "WAIT" "Launching manual user creation..."
        php artisan p:user:make
    elif [ "$choice" = "2" ]; then
        status_msg "WAIT" "Creating auto admin user..."
        USERNAME="user$(openssl rand -hex 2)"
        PASSWORD="$(openssl rand -base64 10)"
        EMAIL="$(openssl rand -base64 4)@email.com"
        FIRST="$(openssl rand -base64 6)"
        LAST="$(openssl rand -base64 4)"
        php artisan p:user:make -n --email=${EMAIL} --username=${USERNAME} --password=${PASSWORD} --admin=1 --name-first=${FIRST} --name-last=${LAST}
        echo ""
        status_msg "OK" "Auto User Created!"
        echo "Username: $USERNAME"
        echo "Password: $PASSWORD"
        echo "Email:    $EMAIL"
    else
        status_msg "ERR" "Invalid option."
    fi
    pause
}

uninstall_ptero() {
    show_header "UNINSTALLATION"
    echo -e "${RED}  WARNING: This will delete all panel data and databases!${NC}"
    read -p "  Are you sure you want to proceed? (y/N): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { status_msg "INFO" "Uninstallation cancelled."; pause; return; }
    echo ""
    status_msg "WAIT" "Stopping services..."
    systemctl stop pteroq.service 2>/dev/null || true
    systemctl disable pteroq.service 2>/dev/null || true
    rm -f /etc/systemd/system/pteroq.service
    systemctl stop nginx 2>/dev/null || true
    systemctl stop php*-fpm 2>/dev/null || true
    systemctl daemon-reload
    status_msg "WAIT" "Removing panel files..."
    cd /tmp && rm -rf /var/www/pterodactyl
    status_msg "WAIT" "Dropping database..."
    DB_CMD=""
    command -v mariadb &>/dev/null && DB_CMD="mariadb" || DB_CMD="mysql"
    sudo $DB_CMD -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || $DB_CMD -e "DROP DATABASE IF EXISTS panel;" 2>/dev/null || true
    sudo $DB_CMD -e "DROP USER IF EXISTS 'pterodactyl'@'127.0.0.1';" 2>/dev/null || true
    sudo $DB_CMD -e "DROP USER IF EXISTS 'pterodactyl'@'localhost';" 2>/dev/null || true
    sudo $DB_CMD -e "FLUSH PRIVILEGES;" 2>/dev/null || true
    status_msg "WAIT" "Cleaning Nginx configs..."
    rm -f /etc/nginx/sites-enabled/pterodactyl.conf /etc/nginx/sites-available/pterodactyl.conf
    systemctl reload nginx 2>/dev/null || true
    status_msg "WAIT" "Removing cron job..."
    crontab -l 2>/dev/null | grep -v "pterodactyl/artisan" | crontab - 2>/dev/null || true
    echo ""
    status_msg "OK" "Panel removed successfully."
    pause
}

update_panel() {
    show_header "SYSTEM UPDATE"
    if [ ! -d /var/www/pterodactyl ]; then
        status_msg "ERR" "Panel not found."
        pause
        return
    fi
    cd /var/www/pterodactyl
    php artisan down
    status_msg "INFO" "Downloading latest release..."
    curl -Lso panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
    tar -xzf panel.tar.gz
    chmod -R 755 storage/* bootstrap/cache/
    COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
    php artisan view:clear
    php artisan config:clear
    php artisan migrate --seed --force
    chown -R www-data:www-data /var/www/pterodactyl/*
    php artisan queue:restart
    php artisan up
    echo ""
    status_msg "OK" "Panel Updated Successfully."
    pause
}

while true; do
    clear
    echo -e "${PURPLE}  ____  _                     _            _         _ ${NC}"
    echo -e "${PURPLE} |  _ \| |_ ___ _ __ ___   __| | __ _  ___| |_ _   _| |${NC}"
    echo -e "${PURPLE} | |_) | __/ _ \ '__/ _ \ / _\` |/ _\` |/ __| __| | | | |${NC}"
    echo -e "${PURPLE} |  __/| ||  __/ | | (_) | (_| | (_| | (__| |_| |_| | |${NC}"
    echo -e "${PURPLE} |_|    \__\___|_|  \___/ \__,_|\__,_|\___|\__|\__, |_|${NC}"
    echo -e "${PURPLE}                                               |___/   ${NC}"
    echo ""
    echo -e "${CYAN} ┌───────────────────────────────────────────────────────┐${NC}"
    if [ -d "/var/www/pterodactyl" ]; then
        echo -e "${CYAN} │${NC} ${BOLD}${WHITE}PANEL STATUS:${NC} ${GREEN}INSTALLED${NC}                                 ${CYAN}│${NC}"
    else
        echo -e "${CYAN} │${NC} ${BOLD}${WHITE}PANEL STATUS:${NC} ${RED}NOT INSTALLED${NC}                             ${CYAN}│${NC}"
    fi
    echo -e "${CYAN} ├───────────────────────────────────────────────────────┤${NC}"
    echo -e "${CYAN} │${NC}                                                       ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${GREEN}[1]${NC} Install       ${GRAY}:: (Fresh Install)${NC}          ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${GREEN}[2]${NC} User          ${GRAY}:: (Add Admin/User)${NC}        ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${YELLOW}[3]${NC} Update       ${GRAY}:: (Latest Release)${NC}        ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${RED}[4]${NC} Domain        ${GRAY}:: (Change Domain/SSL)${NC}       ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${RED}[5]${NC} Uninstall     ${GRAY}:: (Remove Data)${NC}            ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${RED}[6]${NC} phpMyAdmin    ${GRAY}:: (Install phpMyAdmin)${NC}      ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${BOLD}[7]${NC} Images        ${GRAY}:: (View in Terminal)${NC}        ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}                                                       ${CYAN}│${NC}"
    echo -e "${CYAN} │${NC}  ${WHITE}[0] Exit System${NC}                                   ${CYAN}│${NC}"
    echo -e "${CYAN} └───────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -ne "${BOLD}${WHITE}  root@ptero:~# ${NC}"
    read choice

    case $choice in
        1) install_ptero ;;
        2) create_user ;;
        3) update_panel ;;
        4) run_script "panel/pterodactyl/ssl.sh" ;;
        5) uninstall_ptero ;;
        6) run_script "panel/pterodactyl/phpMyAdmin.sh" ;;
        7) run_script "panel/pterodactyl/images.sh" ;;
        0) clear; exit ;;
        *) echo -e "${RED}  Invalid option selected...${NC}"; sleep 1 ;;
    esac
done
