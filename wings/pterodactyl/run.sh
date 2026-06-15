#!/bin/bash

PURPLE='\033[38;5;141m'
GREEN='\033[38;5;82m'
GRAY='\033[38;5;242m'
NC='\033[0m'

SERVICE_NAME="${1:-wings}"

echo -e "  ${PURPLE}::${NC} Restarting ${SERVICE_NAME}..."
systemctl restart ${SERVICE_NAME}
echo -e "  ${GREEN}[OK]${NC} ${SERVICE_NAME} restarted"

sleep 2
systemctl is-active --quiet ${SERVICE_NAME} && echo -e "  ${GREEN}[OK]${NC} ${SERVICE_NAME} is running" || echo -e "  ${RED}[FAIL]${NC} ${SERVICE_NAME} failed to start"
