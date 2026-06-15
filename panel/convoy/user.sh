#!/bin/bash

PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

echo -e "  ${PURPLE}::${NC} Creating ConvoyPanel admin user..."

if [ ! -d "/opt/convoy/panel" ]; then
    echo -e "  ${RED}ConvoyPanel not installed.${NC}"
    exit 1
fi

cd /opt/convoy/panel || exit 1
docker compose exec -T app php artisan make:user
