#!/bin/bash

PURPLE='\033[38;5;141m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

echo -e "  ${PURPLE}::${NC} Updating Portainer..."
docker stop portainer 2>/dev/null || true
docker rm portainer 2>/dev/null || true
docker pull portainer/portainer-ce:latest
docker run -d \
    -p 8000:8000 \
    -p 9443:9443 \
    --name portainer \
    --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest

echo -e "  ${GREEN}[OK]${NC} Portainer updated."
