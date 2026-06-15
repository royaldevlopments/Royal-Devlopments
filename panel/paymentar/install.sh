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
GITHUB_REPO="Paymenter/Paymenter"
PHP_VERSION="8.3"

show_banner() {
    clear
    echo -e "${GOLD}"
    cat << "EOF"
    ____                            _   _
   |  _ \ ___  __ _ _ __ ___   __ _| |_(_)_   _____
   | |_) / _ \/ _` | '_ ` _ \ / _` | __| \ \ / / _ \
   |  __/  __/ (_| | | | | | | (_| | |_| |\ V /  __/
   |_|   \___|\__,_|_| |_| |_|\__,_|\__|_| \_/ \___|

EOF
    echo -e "           ${WHITE}PAYMENTER INSTALLER${NC}"
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
ask "Paymenter Domain" "billing.nobita.indevs.in" DOMAIN
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

apt install -y php${PHP_VERSION} php${PHP_VERSION}-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,intl,redis} mariadb-server nginx redis-server
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

mkdir -p /var/www/paymenter
cd /var/www/paymenter
if [[ "$version_PANEL" == "latest" ]]; then
    step "Downloading latest panel release..."
    curl -Lso paymenter.tar.gz https://github.com/Paymenter/Paymenter/releases/latest/download/paymenter.tar.gz
else
    step "Downloading panel version $version_PANEL..."
    curl -Lso paymenter.tar.gz "https://github.com/Paymenter/Paymenter/releases/download/${version_PANEL}/paymenter.tar.gz"
fi
tar -xzf paymenter.tar.gz
chmod -R 755 storage/* bootstrap/cache/

DB_NAME=paymenter; DB_USER=paymenter; DB_PASS=yourPassword
mariadb -e "CREATE USER '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';" 2>/dev/null || true
mariadb -e "CREATE DATABASE ${DB_NAME};" 2>/dev/null || true
mariadb -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -e "FLUSH PRIVILEGES;"

cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|g" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|g" .env

COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
php artisan key:generate --force
php artisan storage:link
php artisan migrate --force --seed
php artisan db:seed --class=CustomPropertySeeder

chown -R www-data:www-data /var/www/paymenter/*
systemctl enable --now cron
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/paymenter/artisan schedule:run >> /dev/null 2>&1") | crontab -

mkdir -p /etc/certs/paymenter
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/paymenter/privkey.pem -out /etc/certs/paymenter/fullchain.pem

tee /etc/nginx/sites-available/paymenter.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    root /var/www/paymenter/public;
    index index.php;
    ssl_certificate /etc/certs/paymenter/fullchain.pem;
    ssl_certificate_key /etc/certs/paymenter/privkey.pem;
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

ln -sf /etc/nginx/sites-available/paymenter.conf /etc/nginx/sites-enabled/paymenter.conf
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl restart nginx

tee /etc/systemd/system/paymenter.service > /dev/null << 'EOF'
[Unit]
Description=Paymenter Queue Worker
After=redis-server.service
[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/paymenter/artisan queue:work
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now redis-server
systemctl enable --now paymenter.service
ok "Queue running"

clear
step "Initialize Paymenter"
cd /var/www/paymenter
TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
sed -i "s|APP_TIMEZONE=.*|APP_TIMEZONE=${TIMEZONE}|g" .env
sed -i '/APP_NAME=/d' .env; echo 'APP_NAME="Nobita Cloud"' >> .env
php artisan app:init <<< $'\n\n'
php artisan config:clear
php artisan cache:clear
chown -R www-data:www-data /var/www/paymenter/*
php artisan queue:restart

clear
echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}DEPLOYMENT COMPLETE${NC}"
echo -e "  ${GRAY}Panel URL :${NC} ${WHITE}https://$DOMAIN${NC}"
echo -e "  ${GRAY}Username  :${NC} ${WHITE}$USERNAME${NC}"
echo -e "  ${GRAY}Password  :${NC} ${WHITE}$PASSWORD${NC}"
echo -e "  ${GRAY}Email     :${NC} ${WHITE}$EMAIL${NC}"
echo -e "\n  ${GOLD}Run ${WHITE}php artisan app:user:create${GOLD} in ${GRAY}/var/www/paymenter${GOLD} to create a user.${NC}"
echo -e "\n  ${PURPLE}Enjoy Paymenter!${NC}"
echo -e "${HEADER_LINE}"
