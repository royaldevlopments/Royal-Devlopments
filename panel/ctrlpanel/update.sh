#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

if [ ! -d "/var/www/ctrlpanel" ]; then
    echo -e "  ${RED}CtrlPanel is not installed.${NC}"
    exit 1
fi

cd /var/www/ctrlpanel || exit 1
php artisan down

echo -e "  ${PURPLE}::${NC} Pulling latest code..."
git fetch origin
git stash 2>/dev/null || true
git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || {
    echo -e "  ${RED}Git pull failed.${NC}"
    exit 1
}

COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

php artisan view:clear
php artisan config:clear
php artisan migrate --force --seed
chown -R www-data:www-data /var/www/ctrlpanel/*
php artisan queue:restart
php artisan up

echo -e "  ${GREEN}[OK]${NC} CtrlPanel updated successfully."
