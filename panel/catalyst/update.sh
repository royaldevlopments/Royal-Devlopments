#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

INSTALL_DIR="/opt/catalyst-docker"

if [ ! -d "$INSTALL_DIR" ]; then
    echo -e "  ${RED}Catalyst not installed at $INSTALL_DIR.${NC}"
    exit 1
fi

cd "$INSTALL_DIR" || exit 1

echo -e "  ${PURPLE}::${NC} Pulling latest images..."
docker compose pull

echo -e "  ${PURPLE}::${NC} Recreating containers..."
docker compose up -d

echo -e "  ${GREEN}[OK]${NC} Catalyst updated successfully."
