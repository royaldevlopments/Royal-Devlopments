#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
WHITE='\033[1;37m'
GRAY='\033[0;90m'
NC='\033[0m'

INSTALL_DIR="/var/www/pelican"

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "  ${RED}[ERR]${NC} Pelican not found at $INSTALL_DIR."
    exit 1
fi

cd "$INSTALL_DIR"

php artisan down
echo -e "  ${GREEN}[OK]${NC} Maintenance mode on"

echo -e "  ${GRAY}Downloading latest release...${NC}"
curl -L https://github.com/pelican-dev/panel/releases/latest/download/panel.tar.gz | tar -xzv
chmod -R 755 storage/* bootstrap/cache/
echo -e "  ${GREEN}[OK]${NC} Files updated"

COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
echo -e "  ${GREEN}[OK]${NC} PHP deps updated"

php artisan migrate --seed --force
echo -e "  ${GREEN}[OK]${NC} Migrations done"

chown -R www-data:www-data "$INSTALL_DIR"/*
echo -e "  ${GREEN}[OK]${NC} Permissions fixed"

systemctl restart pelicanq.service
echo -e "  ${GREEN}[OK]${NC} Queue worker restarted"

php artisan up
echo -e "  ${GREEN}[OK]${NC} Maintenance mode off"
echo ""
echo -e "  ${GREEN}Pelican panel updated successfully.${NC}"
