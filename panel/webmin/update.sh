#!/bin/bash

PURPLE='\033[38;5;141m'
GREEN='\033[38;5;82m'
NC='\033[0m'

echo -e "  ${PURPLE}::${NC} Updating Webmin..."
apt update && apt install --only-upgrade -y webmin

echo -e "  ${GREEN}[OK]${NC} Webmin updated."
