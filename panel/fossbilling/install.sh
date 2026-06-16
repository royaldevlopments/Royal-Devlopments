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
GITHUB_REPO="FOSSBilling/FOSSBilling"
PHP_VERSION="8.3"

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PANEL_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$(dirname "$PANEL_DIR")"
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"

download_src() {
    local SRC_FILE="fossbilling.zip"
    local LOCAL_PATH="$BASE_DIR/src/fossbilling/$SRC_FILE"

    if [ -f "$LOCAL_PATH" ]; then
        cp "$LOCAL_PATH" ./fossbilling.zip
        ok "Copied from local repo"
        return 0
    fi

    echo -e "  ${YELLOW}Local source not found. Trying GitHub raw...${NC}"
    if curl -sL "$GITHUB_RAW/src/fossbilling/$SRC_FILE" -o fossbilling.zip 2>/dev/null; then
        ok "Downloaded from GitHub raw"
        return 0
    fi

    echo -e "  ${YELLOW}Trying upstream release...${NC}"
    local DL_URL
    DL_URL=$(fetch_latest_url) || return 1
    echo -e "  ${GRAY}Download URL: ${WHITE}$DL_URL${NC}"
    wget -qO fossbilling.zip "$DL_URL"
}

show_banner() {
    clear
    echo -e "${GOLD}"
    cat << "EOF"
   _____  ____  ____  _______ _ _ _
  |  ___|/ ___|| __ )| ____(_) | | |
  | |_   \___ \|  _ \|  _| | | | | |
  |  _|   ___) | |_) | |___| | | | |
  |_|    |____/|____/|_____|_|_|_|_|
EOF
    echo -e "           ${WHITE}FOSSBILLING INSTALLER${NC}"
    echo -e "${HEADER_LINE}"
}

ok()    { echo -e "  ${GREEN}[OK]${NC} $1"; }
step()  { echo -e "\n  ${PURPLE}::${NC} ${WHITE}$1${NC}"; }
ask()   {
    local label=$1 default=$2 var_name=$3
    echo -ne "  ${PURPLE}${NC} ${WHITE}$label${NC} ${GRAY}[$default]${NC}\n  ${GRAY}->${NC} "
    read input
    [ -z "$input" ] && eval "$var_name=\"$default\"" || eval "$var_name=\"$input\""
}

ask_timeout() {
    local label=$1 default=$2 var_name=$3
    echo -ne "  ${PURPLE}${NC} ${WHITE}$label${NC} ${GRAY}[$default]${NC}\n  ${GRAY}->${NC} "
    if ! read -t 10 input; then
        echo -e "\n  ${GOLD}Timeout — using default: ${WHITE}$default${NC}"
        eval "$var_name=\"$default\""; return
    fi
    [ -z "$input" ] && eval "$var_name=\"$default\"" || eval "$var_name=\"$input\""
}

fetch_latest_url() {
    echo -e "  ${GRAY}Fetching latest release from ${WHITE}$GITHUB_REPO${GRAY}...${NC}" >&2
    local json
    json=$(curl -sf "https://api.github.com/repos/$GITHUB_REPO/releases/latest" 2>/dev/null) || return 1
    echo "$json" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['assets'][0]['browser_download_url'])" 2>/dev/null || return 1
}

show_banner
ask "FOSSBilling Domain" "billing.nobita.indevs.in" DOMAIN

echo ""
echo -e "  ${GOLD}FOSSBilling uses a web-based installer after files are deployed.${NC}"
echo -e "  ${GOLD}You will complete setup by visiting the domain in your browser.${NC}"

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

apt update && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release wget

OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
if [[ "$OS" == "ubuntu" ]]; then
    apt install -y software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
elif [[ "$OS" == "debian" ]]; then
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
fi
curl -sSL https://downloads.mariadb.com/MariaDB/mariadb_repo_setup | bash -s -- --mariadb-server-version="mariadb-10.11" 2>/dev/null || true
apt update

apt install -y php${PHP_VERSION} php${PHP_VERSION}-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,intl,simplexml} mariadb-server nginx

step "Downloading FOSSBilling..."
mkdir -p /var/www/fossbilling
cd /var/www/fossbilling
download_src || exit 1
unzip -q fossbilling.zip
rm fossbilling.zip

echo -e "  ${GREEN}[OK]${NC} Files extracted"

DB_NAME=fossbilling; DB_USER=fossbilling; DB_PASS=yourPassword
mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null || true
mariadb -e "CREATE DATABASE ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;" 2>/dev/null || true
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"

chown -R www-data:www-data /var/www/fossbilling
find /var/www/fossbilling -type d -exec chmod 755 {} \;
find /var/www/fossbilling -type f -exec chmod 644 {} \;

mkdir -p /etc/certs/fossbilling
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/fossbilling/privkey.pem -out /etc/certs/fossbilling/fullchain.pem

tee /etc/nginx/sites-available/fossbilling.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    root /var/www/fossbilling;
    index index.php;
    ssl_certificate /etc/certs/fossbilling/fullchain.pem;
    ssl_certificate_key /etc/certs/fossbilling/privkey.pem;
    client_max_body_size 100m;
    sendfile off;
    set \$root_path /var/www/fossbilling;
    try_files \$uri \$uri/ @rewrite;
    location @rewrite {
        rewrite ^/page/(.*)$ /index.php?_url=/custompages/\$1;
        rewrite ^/(.*)$ /index.php?_url=/\$1;
    }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_intercept_errors on;
    }
    location ~* .(ini|sh|inc|bak|twig|sql)\$ { return 403; }
    location ^~ /vendor/ { return 403; }
    location = /config.php { return 403; }
    location ~ /\.(?!well-known\/) { return 403; }
    location ^~ /data/ { return 403; }
    location ~* ^/(css|img|js|flv|swf|download)/(.+)\$ {
        root \$root_path;
        expires off;
    }
}
EOF

ln -sf /etc/nginx/sites-available/fossbilling.conf /etc/nginx/sites-enabled/fossbilling.conf
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

systemctl enable --now cron
cat > /etc/cron.d/fossbilling << CRON
* * * * * www-data php /var/www/fossbilling/cron.php > /dev/null 2>&1
CRON

DB_HOST="localhost"

cat > /root/.fossbilling_db << EOF
Database Name: ${DB_NAME}
Database User: ${DB_USER}
Database Password: ${DB_PASS}
Database Host: ${DB_HOST}
EOF
chmod 600 /root/.fossbilling_db

clear
echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}FILES DEPLOYED${NC}"
echo -e "  ${GRAY}Panel URL :${NC} ${WHITE}https://$DOMAIN${NC}"
echo ""
echo -e "  ${GOLD}Complete setup by visiting the URL in your browser.${NC}"
echo -e "  ${GOLD}The web installer will guide you through:${NC}"
echo -e "  ${GRAY}  - Database connection${NC}"
echo -e "  ${GRAY}  - Admin account creation${NC}"
echo -e "  ${GRAY}  - General settings${NC}"
echo ""
echo -e "  ${GRAY}Database Name:${NC} ${DB_NAME}"
echo -e "  ${GRAY}Database User:${NC} ${DB_USER}"
echo -e "  ${GRAY}Database Pass:${NC} ${DB_PASS}"
echo -e "  ${GRAY}Database Host:${NC} ${DB_HOST}"
echo -e "\n  ${PURPLE}Details saved to /root/.fossbilling_db${NC}"
echo -e "${HEADER_LINE}"
