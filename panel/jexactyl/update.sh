#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

if [ ! -d "/var/www/jexactyl" ]; then
    echo -e "  ${RED}Jexactyl is not installed.${NC}"
    exit 1
fi

cd /var/www/jexactyl || exit 1
php artisan down

echo -e "  ${PURPLE}::${NC} Downloading latest release..."
curl -Lso panel.tar.gz https://github.com/Jexactyl/Jexactyl/releases/latest/download/panel.tar.gz
tar -xzf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
pnpm install
pnpm build

php artisan view:clear
php artisan config:clear
php artisan migrate --seed --force
chown -R www-data:www-data /var/www/jexactyl/*
php artisan queue:restart
php artisan up

echo -e "  ${GREEN}[OK]${NC} Jexactyl updated successfully."
