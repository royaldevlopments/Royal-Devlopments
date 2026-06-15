#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

INSTALL_DIR="/var/www/skyport"

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "  ${RED}[ERR]${NC} Skyport not found at $INSTALL_DIR."
    exit 1
fi

cd "$INSTALL_DIR"

php artisan down
echo -e "  ${GREEN}[OK]${NC} Maintenance mode on"

echo -e "  ${GRAY}Backing up .env and database...${NC}"
cp .env .env.bak
[[ -f database/database.sqlite ]] && cp database/database.sqlite database/database.sqlite.bak

echo -e "  ${GRAY}Pulling latest code...${NC}"
git fetch --all --tags
git reset --hard origin/main 2>/dev/null || {
    echo -e "  ${YELLOW}Git reset failed — trying fresh clone...${NC}"
    cd /tmp
    rm -rf skyport-tmp
    git clone --depth 1 https://github.com/skyportsh/panel.git skyport-tmp
    cp "$INSTALL_DIR/.env" /tmp/skyport-env.bak
    cp -r "$INSTALL_DIR/database" /tmp/skyport-db.bak
    cp -r "$INSTALL_DIR/storage" /tmp/skyport-storage.bak
    rm -rf "$INSTALL_DIR"/*
    cp -r /tmp/skyport-tmp/* "$INSTALL_DIR/"
    cp /tmp/skyport-env.bak "$INSTALL_DIR/.env"
    cp -r /tmp/skyport-db.bak/* "$INSTALL_DIR/database/" 2>/dev/null || true
    cp -r /tmp/skyport-storage.bak/* "$INSTALL_DIR/storage/" 2>/dev/null || true
    rm -rf /tmp/skyport-tmp /tmp/skyport-env.bak /tmp/skyport-db.bak /tmp/skyport-storage.bak
    cd "$INSTALL_DIR"
}
echo -e "  ${GREEN}[OK]${NC} Code updated"

COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-progress
echo -e "  ${GREEN}[OK]${NC} PHP deps updated"

bun install 2>/dev/null
bun run build:ssr
echo -e "  ${GREEN}[OK]${NC} Assets rebuilt"

php artisan migrate --force
php artisan wayfinder:generate --with-form --no-interaction
php artisan optimize:clear
echo -e "  ${GREEN}[OK]${NC} Migrations + cache cleared"

chown -R www-data:www-data "$INSTALL_DIR"
chmod -R 755 storage bootstrap/cache

systemctl restart skyport-panel skyport-queue skyport-ssr
echo -e "  ${GREEN}[OK]${NC} Services restarted"

php artisan up
echo -e "  ${GREEN}[OK]${NC} Maintenance mode off"
echo -e ""
echo -e "  ${GREEN}Skyport panel updated successfully.${NC}"
