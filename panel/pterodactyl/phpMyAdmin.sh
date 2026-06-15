#!/bin/bash

CYAN='\033[38;5;51m'; PURPLE='\033[38;5;141m'; GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'; GREEN='\033[38;5;82m'; RED='\033[38;5;196m'; GOLD='\033[38;5;214m'; NC='\033[0m'
HEADER_LINE="${GRAY}────────────────────────────────────────────────────────────${NC}"

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
    PREMIUM phpMyAdmin INSTALLER
EOF
    echo -e "           ${WHITE}PREMIUM phpMyAdmin INSTALLER${NC}"
    echo -e "${HEADER_LINE}"
}
ok() { echo -e "  ${GREEN}[OK]${NC} $1"; }
step() { echo -e "\n  ${PURPLE}::${NC} ${WHITE}$1${NC}"; }
ask() {
    local label=$1 default=$2 var_name=$3
    echo -ne "  ${PURPLE}${NC} ${WHITE}$label${NC} ${GRAY}[$default]${NC}\n  ${GRAY}->${NC} "
    read input
    [ -z "$input" ] && eval "$var_name=\"$default\"" || eval "$var_name=\"$input\""
}

show_banner
ask "phpMyAdmin Domain" "phpmyadmin.nobita.indevs.in" DOMAIN
ask "DB Name" "phpmyadmin" DB_NAME
ask "DB User" "phpmyadmin" DB_USER
ask "DB Pass" "phpmyadmin" DB_PASS

echo -e "\n  ${GOLD}┌─[ REVIEW CONFIGURATION ]${NC}"
echo -e "  ${GOLD}│${NC} ${GRAY}Domain:${NC}   $DOMAIN"
echo -e "  ${GOLD}│${NC} ${GRAY}Name:${NC}     $DB_NAME"
echo -e "  ${GOLD}│${NC} ${GRAY}User:${NC}     $DB_USER"
echo -e "  ${GOLD}└───────────────────────────${NC}"

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) exit ;; esac
done

set -e
INSTALL_DIR="/var/www/phpmyadmin"
SSL_DIR="/etc/certs/phpMyAdmin"
source /etc/os-release
case "$ID" in ubuntu|debian) echo "Detected: $PRETTY_NAME" ;; *) echo "Unsupported OS"; exit 1 ;; esac

apt update
apt install -y wget tar nginx openssl php-fpm
mkdir -p "$INSTALL_DIR/tmp"
cd "$INSTALL_DIR"
wget -O phpMyAdmin.tar.gz https://www.phpmyadmin.net/downloads/phpMyAdmin-latest-english.tar.gz
tar -xzf phpMyAdmin.tar.gz
PMA_DIR=$(find . -maxdepth 1 -type d -name "phpMyAdmin-*-english" | head -n1)
mv "$PMA_DIR"/* .; rm -rf "$PMA_DIR" phpMyAdmin.tar.gz
mkdir -p config; chmod o+rw config
cp config.sample.inc.php config/config.inc.php; chmod o+w config/config.inc.php
chown -R www-data:www-data "$INSTALL_DIR"; chmod -R 755 "$INSTALL_DIR"

mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null || true
mariadb -e "CREATE DATABASE ${DB_NAME};" 2>/dev/null || true
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"

mkdir -p "$SSL_DIR"; cd "$SSL_DIR"
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=$DOMAIN" \
    -keyout privkey.pem -out fullchain.pem

PHP_SOCKET=$(find /run/php -name "php*-fpm.sock" | head -n1)

cat > /etc/nginx/sites-available/phpmyadmin.conf <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    root $INSTALL_DIR;
    index index.php;
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;
    ssl_certificate $SSL_DIR/fullchain.pem;
    ssl_certificate_key $SSL_DIR/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:$PHP_SOCKET;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M\npost_max_size=100M";
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
        fastcgi_intercept_errors off;
    }
    location ~ /\.ht { deny all; }
}
EOF

ln -sf /etc/nginx/sites-available/phpmyadmin.conf /etc/nginx/sites-enabled/phpmyadmin.conf
nginx -t && systemctl restart nginx

clear
echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}DEPLOYMENT COMPLETE${NC}"
echo -e "  ${GRAY}Domain:${NC}   $DOMAIN"
echo -e "  ${GRAY}DB Name:${NC}  $DB_NAME"
echo -e "  ${GRAY}DB User:${NC}  $DB_USER"
echo -e "  ${GRAY}DB Pass:${NC}  $DB_PASS"
echo -e "\n  ${PURPLE}phpMyAdmin installed!${NC}"
echo -e "${HEADER_LINE}"
