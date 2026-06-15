#!/bin/bash

PURPLE='\033[38;5;141m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GRAY='\033[38;5;242m'
NC='\033[0m'

if [ ! -d "/opt/convoy/panel" ]; then
    echo -e "  ${RED}ConvoyPanel not installed.${NC}"
    exit 1
fi

cd /opt/convoy/panel || exit 1

echo -e "  ${PURPLE}::${NC} Pulling latest code..."
git pull

echo -e "  ${PURPLE}::${NC} Rebuilding containers..."
docker compose pull
docker compose up -d --force-recreate

echo -e "  ${PURPLE}::${NC} Running migrations..."
docker compose exec -T app php artisan migrate --force

echo -e "  ${GREEN}[OK]${NC} ConvoyPanel updated."
