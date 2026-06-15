#!/bin/bash

GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
PURPLE='\033[38;5;141m'
NC='\033[0m'

echo -e "  ${PURPLE}::${NC} Updating Proxmox VE packages..."
apt update && apt upgrade -y

echo -e "  ${GREEN}[OK]${NC} Proxmox VE updated. Reboot if kernel was upgraded."
