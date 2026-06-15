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
INSTALL_DIR="/var/www/pelican"
PHP_VERSION="8.3"

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
   ██████╗ ███████╗██╗     ██╗ ██████╗ █████╗ ███╗   ██╗
   ██╔══██╗██╔════╝██║     ██║██╔════╝██╔══██╗████╗  ██║
   ██████╔╝█████╗  ██║     ██║██║     ███████║██╔██╗ ██║
   ██╔═══╝ ██╔══╝  ██║     ██║██║     ██╔══██║██║╚██╗██║
   ██║     ███████╗███████╗██║╚██████╗██║  ██║██║ ╚████║
   ╚═╝     ╚══════╝╚══════╝╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝
EOF
    echo -e "           ${WHITE}PELICAN PANEL INSTALLER${NC}"
    echo -e "${HEADER_LINE}"
}

ok()    { echo -e "  ${GREEN}[OK]${NC} $1"; }
step()  { echo -e "\n  ${PURPLE}::${NC} ${WHITE}$1${NC}"; }
ask()   {
    local label=$1 default=$2 var_name=$3
    echo -ne "  ${WHITE}$label${NC} ${GRAY}[$default]${NC}\n  ${GRAY}->${NC} "
    read input
    [ -z "$input" ] && eval "$var_name=\"$default\"" || eval "$var_name=\"$input\""
}

show_banner
ask "Panel Domain" "pelican.nobita.indevs.in" DOMAIN
ask "Admin Email" "admin@pelican.com" EMAIL
ask "Admin Username" "admin" USERNAME
ask "Admin Password" "admin123" PASSWORD
ask "DB Password" "dbpassword" DB_PASS

echo -e "\n  ${GOLD}┌─[ REVIEW CONFIGURATION ]${NC}"
echo -e "  ${GOLD}│${NC} ${GRAY}Domain:${NC}    $DOMAIN"
echo -e "  ${GOLD}│${NC} ${GRAY}Email:${NC}     $EMAIL"
echo -e "  ${GOLD}│${NC} ${GRAY}Version:${NC}   latest"
echo -e "  ${GOLD}└───────────────────────────${NC}"

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

step "Installing system dependencies"
apt update
DEBIAN_FRONTEND=noninteractive apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release

source /etc/os-release
if [[ "$ID" == "ubuntu" ]]; then
    DEBIAN_FRONTEND=noninteractive apt install -y software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
else
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
fi

curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
apt update

DEBIAN_FRONTEND=noninteractive apt install -y \
    php${PHP_VERSION} php${PHP_VERSION}-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,intl} \
    mariadb-server nginx redis-server
ok "Dependencies installed"

step "Installing Composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
ok "Composer installed"

step "Setting up database"
DB_NAME=pelican
DB_USER=pelican
mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null || true
mariadb -e "CREATE DATABASE ${DB_NAME};" 2>/dev/null || true
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"
ok "Database created"

step "Downloading Pelican panel"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | tar -xzv
chmod -R 755 storage/* bootstrap/cache/
ok "Panel files downloaded"

step "Installing PHP dependencies"
cp .env.example .env
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
php artisan key:generate --force
ok "PHP deps installed"

step "Configuring environment"
php artisan p:environment:setup << EOF
y
$DOMAIN
y
$DB_NAME
$DB_USER
127.0.0.1
3306
$DB_PASS
EOF

sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
ok "Environment configured"

step "Running migrations"
php artisan migrate --seed --force
ok "Migrations done"

step "Creating admin user"
php artisan p:user:make -n --email="$EMAIL" --username="$USERNAME" --password="$PASSWORD" --admin=1 --name-first=Admin --name-last=User
ok "Admin user: $EMAIL"

step "Setting permissions"
chown -R www-data:www-data "$INSTALL_DIR"/*
ok "Permissions set"

step "Configuring cron"
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php ${INSTALL_DIR}/artisan schedule:run >> /dev/null 2>&1") | crontab -
ok "Cron configured"

step "Setting up SSL"
mkdir -p /etc/certs/pelican
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/pelican/privkey.pem -out /etc/certs/pelican/fullchain.pem
ok "Self-signed SSL generated"

step "Configuring Nginx"
tee /etc/nginx/sites-available/pelican.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    root ${INSTALL_DIR}/public;
    index index.php;
    ssl_certificate /etc/certs/pelican/fullchain.pem;
    ssl_certificate_key /etc/certs/pelican/privkey.pem;
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/pelican.conf /etc/nginx/sites-enabled/pelican.conf
nginx -t && systemctl restart nginx
ok "Nginx configured"

step "Setting up queue worker"
tee /etc/systemd/system/pelicanq.service > /dev/null << 'EOF'
[Unit]
Description=Pelican Queue Worker
After=redis-server.service
[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pelican/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now redis-server
systemctl enable --now pelicanq.service
ok "Queue worker running"

clear
echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}PELICAN DEPLOYMENT COMPLETE${NC}"
echo -e "  ${GRAY}Panel URL :${NC} ${WHITE}https://$DOMAIN${NC}"
echo -e "  ${GRAY}Email     :${NC} ${WHITE}$EMAIL${NC}"
echo -e "  ${GRAY}Password  :${NC} ${WHITE}$PASSWORD${NC}"
echo -e "\n  ${PURPLE}Enjoy your Pelican Panel!${NC}"
echo -e "${HEADER_LINE}"
