#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

if [ ! -d "/var/www/pteroca" ]; then
    echo -e "  ${RED}PteroCA is not installed.${NC}"
    exit 1
fi

cd /var/www/pteroca || exit 1

PHP_BIN="php"
if command -v php8.4 &>/dev/null; then PHP_BIN="php8.4"
elif command -v php8.3 &>/dev/null; then PHP_BIN="php8.3"
elif command -v php8.2 &>/dev/null; then PHP_BIN="php8.2"
fi

echo -e "  ${PURPLE}::${NC} Storing maintenance mode..."
${PHP_BIN} bin/console cache:clear --no-warmup 2>/dev/null || true

echo -e "  ${PURPLE}::${NC} Pulling latest code..."
git fetch origin
git stash 2>/dev/null || true
git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || {
    echo -e "  ${RED}Git pull failed. Try manual update.${NC}"
    exit 1
}

COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader --no-interaction

echo -e "  ${PURPLE}::${NC} Running migrations..."
${PHP_BIN} bin/console doctrine:migrations:migrate --no-interaction

${PHP_BIN} bin/console cache:clear --no-warmup
${PHP_BIN} bin/console assets:install public

chown -R www-data:www-data /var/www/pteroca/*
systemctl reload nginx 2>/dev/null || true

echo -e "  ${GREEN}[OK]${NC} PteroCA updated successfully."
