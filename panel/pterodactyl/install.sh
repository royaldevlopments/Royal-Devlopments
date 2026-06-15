#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'
HEADER_LINE="${GRAY}────────────────────────────────────────────────────────────${NC}"
GITHUB_REPO="pterodactyl/panel"
PHP_VERSION="8.3"

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
               .                                      .o8                          .               oooo
             .o8                                     "888                        .o8               `888
oo.ooooo.  .o888oo  .ooooo.  oooo d8b  .ooooo.   .oooo888   .oooo.    .ooooo.  .o888oo oooo    ooo  888
 888' `88b   888   d88' `88b `888""8P d88' `88b d88' `888  `P  )88b  d88' `"Y8   888    `88.  .8'   888
 888   888   888   888ooo888  888     888   888 888   888   .oP"888  888         888     `88..8'    888
 888   888   888 . 888    .o  888     888   888 888   888  d8(  888  888   .o8   888 .    `888'     888
 888bod8P'   "888" `Y8bod8P' d888b    `Y8bod8P' `Y8bod88P" `Y888""8o `Y8bod8P'   "888"     .8'     o888o
 888                                                                                   .o..P'
o888o                                                                                  `Y8P'
EOF
    echo -e "           ${WHITE}PREMIUM PTERODACTYL INSTALLER${NC}"
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

fetch_github_versions() {
    local repo=$1
    echo -e "  ${GRAY}Fetching releases from ${WHITE}$repo${GRAY}...${NC}" >&2
    local json
    json=$(curl -sf "https://api.github.com/repos/$repo/releases?per_page=20" 2>/dev/null) || { echo -e "  ${RED}Failed to fetch releases.${NC}" >&2; return 1; }
    echo "$json" | python3 -c "import sys,json; data=json.load(sys.stdin); [print(r['tag_name']) for r in data if not r.get('prerelease',False) and r.get('tag_name','').startswith('v')]" 2>/dev/null || return 1
}

select_version() {
    local repo=$1 var_name=$2 default="latest"
    echo -e "\n  ${PURPLE}::${NC} ${WHITE}Available Panel Versions${NC}"
    local tags=() disp=() i=0
    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue
        tags+=("$tag"); i=$((i+1))
        disp+=("  ${GRAY}$i.${NC} ${WHITE}$tag${NC}")
    done < <(fetch_github_versions "$repo" 2>/dev/null) || true
    [[ ${#tags[@]} -eq 0 ]] && { echo -e "  ${YELLOW}No versions found. Using latest.${NC}"; eval "$var_name=\"$default\""; return; }
    printf '%b\n' "${disp[@]}"
    local max=${#tags[@]}
    echo -ne "\n  ${PURPLE}${NC} ${WHITE}Select version [1-$max]${NC} ${GRAY}[1 = latest]${NC}\n  ${GRAY}->${NC} "
    if ! read -t 10 choice; then echo -e "\n  ${GOLD}Timeout — using latest: ${WHITE}${tags[0]}${NC}"; eval "$var_name=\"${tags[0]}\""; return; fi
    if [[ -z "$choice" || "$choice" == "1" ]]; then eval "$var_name=\"${tags[0]}\""
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $max ]]; then
        local idx=$((choice - 1)); eval "$var_name=\"${tags[$idx]}\""
    else eval "$var_name=\"${tags[0]}\""
    fi
}

show_banner
ask "Panel Domain" "panel.nobita.indevs.in" DOMAIN
ask "Admin Email" "admin@gmail.com" EMAIL
ask "Admin Username" "admin" USERNAME
ask_timeout "Admin Password" "admin" PASSWORD
select_version "$GITHUB_REPO" "version_PANEL"

echo -e "\n  ${GOLD}┌─[ REVIEW CONFIGURATION ]${NC}"
echo -e "  ${GOLD}│${NC} ${GRAY}Domain:${NC}   $DOMAIN"
echo -e "  ${GOLD}│${NC} ${GRAY}Email:${NC}    $EMAIL"
echo -e "  ${GOLD}│${NC} ${GRAY}User:${NC}     $USERNAME"
echo -e "  ${GOLD}│${NC} ${GRAY}Version:${NC}  $version_PANEL"
echo -e "  ${GOLD}└───────────────────────────${NC}"

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

apt update && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release

OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
if [[ "$OS" == "ubuntu" ]]; then
    apt install -y software-properties-common
    LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
elif [[ "$OS" == "debian" ]]; then
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
fi
rm -f /usr/share/keyrings/redis-archive-keyring.gpg
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/redis.list
apt update

apt install -y php${PHP_VERSION} php${PHP_VERSION}-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
if ! command -v composer &>/dev/null; then
    echo -e "  ${RED}Composer installation failed. Retrying...${NC}"
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    php -r "if (hash_file('sha384', 'composer-setup.php') === '$EXPECTED_CHECKSUM') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); exit(1); }"
    php composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f composer-setup.php
fi

mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
if [[ "$version_PANEL" == "latest" ]]; then
    step "Downloading latest panel release..."
    curl -Lso panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
else
    step "Downloading panel version $version_PANEL..."
    curl -Lso panel.tar.gz "https://github.com/pterodactyl/panel/releases/download/${version_PANEL}/panel.tar.gz"
fi
tar -xzf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

DB_NAME=panel; DB_USER=pterodactyl; DB_PASS=$(openssl rand -base64 16)
systemctl enable --now mariadb 2>/dev/null || systemctl enable --now mysql 2>/dev/null || true
sleep 2
DB_CMD=""
command -v mariadb &>/dev/null && DB_CMD="mariadb" || DB_CMD="mysql"
$DB_CMD -e "SELECT 1" 2>/dev/null || { echo -e "  ${RED}Database server not running.${NC}"; exit 1; }
$DB_CMD -e "DROP USER IF EXISTS '${DB_USER}'@'127.0.0.1';" 2>/dev/null || true
$DB_CMD -e "DROP USER IF EXISTS '${DB_USER}'@'localhost';" 2>/dev/null || true
$DB_CMD -e "DROP DATABASE IF EXISTS ${DB_NAME};" 2>/dev/null || true
$DB_CMD -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
$DB_CMD -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
$DB_CMD -e "CREATE DATABASE ${DB_NAME};"
$DB_CMD -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
$DB_CMD -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' WITH GRANT OPTION;"
$DB_CMD -e "FLUSH PRIVILEGES;"

[ ! -f ".env.example" ] && curl -Lo .env.example https://raw.githubusercontent.com/pterodactyl/panel/develop/.env.example
cp .env.example .env
is_ip() { [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; }

if is_ip "$DOMAIN"; then
    sed -i "s|APP_URL=.*|APP_URL=http://${DOMAIN}|g" .env
else
    sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
fi
sed -i "s|DB_HOST=.*|DB_HOST=127.0.0.1|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env
grep -q "^APP_ENVIRONMENT_ONLY=" .env || echo "APP_ENVIRONMENT_ONLY=false" >> .env

if ! command -v composer &>/dev/null; then
    echo -e "  ${RED}Composer not found. Aborting.${NC}"; exit 1
fi
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader || {
    echo -e "  ${RED}Composer install failed. Check network/requirements.${NC}"; exit 1
}
php artisan key:generate --force
php artisan migrate --seed --force || {
    echo -e "  ${RED}Database migration failed. Check DB credentials in .env${NC}"; exit 1
}

chown -R www-data:www-data /var/www/pterodactyl/*
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -

if is_ip "$DOMAIN"; then
    tee /etc/nginx/sites-available/pterodactyl.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    root /var/www/pterodactyl/public;
    index index.php;
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
else
    mkdir -p /etc/certs/panel
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
        -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
        -keyout /etc/certs/panel/privkey.pem -out /etc/certs/panel/fullchain.pem

    tee /etc/nginx/sites-available/pterodactyl.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    root /var/www/pterodactyl/public;
    index index.php;
    ssl_certificate /etc/certs/panel/fullchain.pem;
    ssl_certificate_key /etc/certs/panel/privkey.pem;
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
fi

ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

tee /etc/systemd/system/pteroq.service > /dev/null << 'EOF'
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service
[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now redis-server
systemctl enable --now pteroq.service
ok "Queue running"

clear
step "Create admin user"
cd /var/www/pterodactyl
sed -i '/^APP_ENVIRONMENT_ONLY=/d' .env; echo "APP_ENVIRONMENT_ONLY=false" >> .env
sed -i '/RECAPTCHA_ENABLED=/d' .env; echo 'RECAPTCHA_ENABLED=false' >> .env
sed -i '/APP_NAME=/d' .env; echo 'APP_NAME="Nobita Cloud"' >> .env
TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
sed -i "s|APP_TIMEZONE=.*|APP_TIMEZONE=${TIMEZONE}|g" .env
php artisan p:location:make --short=IN --long="India" 2>/dev/null || true
php artisan view:clear; php artisan config:clear; php artisan cache:clear; php artisan config:cache
chown -R www-data:www-data /var/www/pterodactyl/*
php artisan queue:restart
php artisan p:user:make -n --email="$EMAIL" --username="${USERNAME}" --password="$PASSWORD" --admin=1 --name-first=My --name-last=Admin

clear
echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}DEPLOYMENT COMPLETE${NC}"
is_ip "$DOMAIN" && SCHEME="http" || SCHEME="https"
echo -e "  ${GRAY}Panel URL :${NC} ${WHITE}${SCHEME}://$DOMAIN${NC}"
echo -e "  ${GRAY}Username  :${NC} ${WHITE}$USERNAME${NC}"
echo -e "  ${GRAY}Password  :${NC} ${WHITE}$PASSWORD${NC}"
echo -e "  ${GRAY}Email     :${NC} ${WHITE}$EMAIL${NC}"
echo -e "\n  ${PURPLE}Enjoy your new Pterodactyl Panel!${NC}"
echo -e "${HEADER_LINE}"
