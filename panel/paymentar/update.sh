#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

if [ ! -d "/var/www/paymenter" ]; then
    echo -e "  ${RED}Paymenter is not installed.${NC}"
    exit 1
fi

cd /var/www/paymenter || exit 1
php artisan down

echo -e "  ${PURPLE}::${NC} Downloading latest release..."
curl -Lso paymenter.tar.gz https://github.com/Paymenter/Paymenter/releases/latest/download/paymenter.tar.gz
tar -xzf paymenter.tar.gz
chmod -R 755 storage/* bootstrap/cache/

COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

php artisan view:clear
php artisan config:clear
php artisan migrate --force --seed
php artisan db:seed --class=CustomPropertySeeder
chown -R www-data:www-data /var/www/paymenter/*
php artisan queue:restart
php artisan up

echo -e "  ${GREEN}[OK]${NC} Paymenter updated successfully."
