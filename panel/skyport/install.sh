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
INSTALL_DIR="/var/www/skyport"
PANEL_USER="www-data"

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
   ┌─┐┌─┐┬ ┬┬┌─┐┬─┐┌┬┐
   └─┐├─┘└┬┘│├─┤├┬┘ │
   └─┘┴   ┴ ┴┴ ┴┴└─ ┴
EOF
    echo -e "           ${WHITE}SKYPORT PANEL INSTALLER${NC}"
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
ask "Panel Domain (empty = IP:port)" "skyport.nobita.indevs.in" DOMAIN
ask "Admin Email" "admin@skyport.com" EMAIL
ask "Admin Password" "admin123" PASSWORD

USE_SSL=false
if [[ -n "$DOMAIN" ]]; then
    USE_SSL=true
    APP_URL="https://${DOMAIN}"
    echo -e "  ${GOLD}→ SSL will be configured for $DOMAIN${NC}"
else
    ask "Port" "8080" PORT
    APP_URL="http://$(hostname -I | awk '{print $1}'):${PORT}"
    echo -e "  ${GOLD}→ No domain — using port $PORT${NC}"
fi

echo -e "\n  ${GOLD}┌─[ REVIEW CONFIGURATION ]${NC}"
echo -e "  ${GOLD}│${NC} ${GRAY}URL:${NC}      $APP_URL"
echo -e "  ${GOLD}│${NC} ${GRAY}Email:${NC}    $EMAIL"
echo -e "  ${GOLD}│${NC} ${GRAY}Database:${NC} SQLite"
echo -e "  ${GOLD}└───────────────────────────${NC}"

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

step "Installing system dependencies"
apt update
DEBIAN_FRONTEND=noninteractive apt install -y curl gnupg2 ca-certificates lsb-release unzip git nginx

source /etc/os-release
if [[ "$ID" == "ubuntu" ]]; then
    DEBIAN_FRONTEND=noninteractive apt install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
else
    curl -fsSL https://packages.sury.org/php/apt.gpg | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    codename=$(lsb_release -sc)
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ ${codename} main" > /etc/apt/sources.list.d/sury-php.list
fi
apt update

DEBIAN_FRONTEND=noninteractive apt install -y \
    php8.4-cli php8.4-common php8.4-curl php8.4-mbstring \
    php8.4-xml php8.4-zip php8.4-bcmath php8.4-sqlite3 \
    php8.4-mysql php8.4-swoole php8.4-readline php8.4-gd php8.4-intl
ok "PHP 8.4 + extensions installed"

step "Installing Composer"
curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php
php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet
rm -f /tmp/composer-setup.php
ok "Composer installed"

step "Installing Bun"
curl -fsSL https://bun.sh/install | bash
[[ -f "$HOME/.bun/bin/bun" ]] && ln -sf "$HOME/.bun/bin/bun" /usr/local/bin/bun
ok "Bun installed"

step "Installing Node.js 22"
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
DEBIAN_FRONTEND=noninteractive apt install -y nodejs
ok "Node.js $(node -v) installed"

step "Downloading Skyport Panel"
[[ -d "$INSTALL_DIR" ]] && rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
git clone --depth 1 https://github.com/skyportsh/panel.git "$INSTALL_DIR"
ok "Panel cloned"

step "Installing PHP dependencies"
cd "$INSTALL_DIR"
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --no-interaction --optimize-autoloader --no-progress
ok "PHP deps installed"

step "Installing JS dependencies"
bun install --frozen-lockfile 2>/dev/null || bun install
ok "JS deps installed"

step "Configuring environment"
cp .env.example .env
php artisan key:generate --no-interaction --force
php artisan environment:setup --url="$APP_URL" --db-connection=sqlite --no-interaction
touch database/database.sqlite
sed -i -e '$a\' .env
grep -q "^OCTANE_SERVER=" .env && sed -i "s/^OCTANE_SERVER=.*/OCTANE_SERVER=swoole/" .env || echo "OCTANE_SERVER=swoole" >> .env
echo "TRUSTED_PROXIES=*" >> .env
echo "ASSET_URL=${APP_URL}" >> .env
echo "SKYPORT_TELEMETRY_ENABLED=false" >> .env
ok "Environment configured"

step "Running database migrations"
php artisan migrate --force --no-interaction
ok "Migrations done"

step "Generating route bindings"
php artisan wayfinder:generate --with-form --no-interaction
ok "Wayfinder generated"

step "Building frontend assets"
bun run build:ssr
ok "Assets built"

step "Creating admin user"
php artisan user:create --name="Admin" --email="$EMAIL" --password="$PASSWORD" --admin --no-interaction
ok "Admin user: $EMAIL"

step "Setting permissions"
chown -R "$PANEL_USER:$PANEL_USER" "$INSTALL_DIR"
chmod -R 755 storage bootstrap/cache
chown "$PANEL_USER:$PANEL_USER" database database/database.sqlite
chmod 775 database
chmod 664 database/database.sqlite
ok "Permissions set"

if $USE_SSL; then
    step "Setting up SSL"
    DEBIAN_FRONTEND=noninteractive apt install -y certbot python3-certbot-nginx
    systemctl stop nginx 2>/dev/null || true
    certbot certonly --standalone -d "$DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email || {
        echo -e "  ${RED}SSL failed — check DNS + port 80${NC}"
        USE_SSL=false
    }
    systemctl start nginx 2>/dev/null || true
    ok "SSL certificate obtained"
fi

step "Configuring Nginx"
OCTANE_PORT=8000
if $USE_SSL; then
    cat > /etc/nginx/sites-available/skyport.conf <<NGINX
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$host\$request_uri;
}
server {
    listen 443 ssl;
    server_name ${DOMAIN};
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    root ${INSTALL_DIR}/public;
    client_max_body_size 256m;
    location / {
        proxy_pass http://127.0.0.1:${OCTANE_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_buffering off;
    }
}
NGINX
else
    cat > /etc/nginx/sites-available/skyport.conf <<NGINX
server {
    listen ${PORT};
    server_name _;
    root ${INSTALL_DIR}/public;
    client_max_body_size 256m;
    location / {
        proxy_pass http://127.0.0.1:${OCTANE_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_buffering off;
    }
}
NGINX
fi
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/skyport.conf /etc/nginx/sites-enabled/skyport.conf
nginx -t && systemctl restart nginx
ok "Nginx configured"

step "Creating systemd services"
cat > /etc/systemd/system/skyport-panel.service <<SVC
[Unit]
Description=Skyport Panel (Octane)
After=network.target
[Service]
User=${PANEL_USER}
Group=${PANEL_USER}
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/php artisan octane:start --server=swoole --host=127.0.0.1 --port=8000
ExecReload=/usr/bin/php artisan octane:reload
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
SVC

cat > /etc/systemd/system/skyport-queue.service <<SVC
[Unit]
Description=Skyport Queue Worker
After=network.target skyport-panel.service
[Service]
User=${PANEL_USER}
Group=${PANEL_USER}
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/php artisan queue:work --tries=3 --timeout=60
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
SVC

cat > /etc/systemd/system/skyport-ssr.service <<SVC
[Unit]
Description=Skyport Inertia SSR
After=network.target
[Service]
User=${PANEL_USER}
Group=${PANEL_USER}
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/php artisan inertia:start-ssr
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
SVC

systemctl daemon-reload
systemctl enable skyport-panel skyport-queue skyport-ssr
systemctl restart skyport-panel skyport-queue skyport-ssr
ok "Services running"

clear
echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}SKYPORT DEPLOYMENT COMPLETE${NC}"
echo -e "  ${GRAY}URL :${NC} ${WHITE}$APP_URL${NC}"
echo -e "  ${GRAY}Email :${NC} ${WHITE}$EMAIL${NC}"
echo -e "  ${GRAY}Password :${NC} ${WHITE}$PASSWORD${NC}"
echo -e ""
echo -e "  ${GRAY}Services:${NC}"
echo -e "    systemctl status skyport-panel"
echo -e "    systemctl status skyport-queue"
echo -e "    systemctl status skyport-ssr"
echo -e "\n  ${PURPLE}Enjoy your Skyport Panel!${NC}"
echo -e "${HEADER_LINE}"
