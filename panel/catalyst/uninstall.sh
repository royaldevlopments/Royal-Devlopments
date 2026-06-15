#!/bin/bash

CYAN='\033[38;5;51m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

INSTALL_DIR="/opt/catalyst-docker"

echo -e "  ${RED}WARNING: This will remove Catalyst and all its Docker containers!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GREEN}Cancelled.${NC}"; exit; }

if [ -d "$INSTALL_DIR" ]; then
    cd "$INSTALL_DIR"

    echo -e "  ${PURPLE}::${NC} Stopping containers..."
    docker compose down -v 2>/dev/null || true

    echo -e "  ${PURPLE}::${NC} Removing directory..."
    rm -rf "$INSTALL_DIR"
fi

echo -e "  ${GREEN}[OK]${NC} Catalyst removed successfully."
echo -e "  ${GRAY}Note: Docker images and volumes may remain. Run 'docker system prune' to clean up.${NC}"
