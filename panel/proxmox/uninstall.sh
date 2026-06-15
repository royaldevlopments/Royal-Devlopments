#!/bin/bash

RED='\033[38;5;196m'
PURPLE='\033[38;5;141m'
GREEN='\033[38;5;82m'
NC='\033[0m'

echo -e "  ${RED}WARNING: This will remove Proxmox VE and all its VMs/containers!${NC}"
read -p "  Are you sure? (y/N): " confirm
[[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GREEN}Cancelled.${NC}"; exit; }

echo -e "  ${PURPLE}::${NC} Removing Proxmox VE packages..."
apt remove --purge -y proxmox-ve postfix open-iscsi chrony
apt autoremove -y

echo -e "  ${PURPLE}::${NC} Cleaning up..."
rm -f /etc/apt/sources.list.d/pve.list
rm -f /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

echo -e "  ${GREEN}[OK]${NC} Proxmox VE removed."
