#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'
HEADER_LINE="${GRAY}────────────────────────────────────────────────────────────${NC}"

show_banner() {
    clear
    echo -e "${GOLD}"
    cat << "EOF"
   ____                    ___
  / __ \___  ____ ___  ___/ _ \___  ___
 / /_/ / _ \/ __  __ \/ _ \// / _ \/ _ \
/ ____/  __/ / / / / /  __/ // /  __/  __/
\/    \___/_/ /_/ /_/\___/___/ \___/\___/
EOF
    echo -e "           ${WHITE}PROXMOX VE INSTALLER${NC}"
    echo -e "${HEADER_LINE}"
}

ok()    { echo -e "  ${GREEN}[OK]${NC} $1"; }
step()  { echo -e "\n  ${PURPLE}::${NC} ${WHITE}$1${NC}"; }
ask()   {
    local label=$1 default=$2 var_name=$3
    echo -ne "  ${WHITE}$label${NC} ${GRAY}[$default]${NC}\n  ${GRAY}->${NC} "
    read input
    [ -z "$input" ] && eval "$var_name=\"$default\"" || eval "$var_name=\"$input\""
}

show_banner
echo -e "  ${GOLD}Proxmox VE must be installed on a FRESH Debian 12 system.${NC}"
echo -e "  ${GOLD}This will configure repositories and install the hypervisor.${NC}"
echo -e "  ${RED}WARNING: This modifies system network/kernel settings.${NC}"

ask "Proxmox VE Hostname" "proxmox" HOSTNAME
ask "Proxmox VE Domain" "local.lan" DOMAIN

echo ""
echo -e "  ${CYAN}Hostname will be set to: ${WHITE}$HOSTNAME.$DOMAIN${NC}"

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

if [ "$(lsb_release -is)" != "Debian" ]; then
    echo -e "  ${RED}Proxmox VE requires Debian. Aborting.${NC}"
    exit 1
fi

step "Setting hostname..."
hostnamectl set-hostname "$HOSTNAME.$DOMAIN"
echo "$HOSTNAME.$DOMAIN" > /etc/hostname
echo "$(hostname -I | awk '{print $1}') $HOSTNAME.$DOMAIN $HOSTNAME" >> /etc/hosts

step "Adding Proxmox VE repository..."
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve.list
curl -fsSL https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg | gpg --dearmor -o /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg

step "Updating packages..."
apt update && apt upgrade -y

step "Installing Proxmox VE..."
apt install -y proxmox-ve postfix open-iscsi chrony

step "Removing conflicting packages..."
apt remove -y os-prober

step "Enabling services..."
systemctl enable --now chronyd
systemctl enable --now pveproxy

echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}PROXMOX VE INSTALLED${NC}"
echo -e "  ${GRAY}URL :${NC} ${WHITE}https://$(hostname -I | awk '{print $1}'):8006${NC}"
echo ""
echo -e "  ${GOLD}Login with your system root credentials.${NC}"
echo -e "  ${GOLD}A reboot is recommended to load the Proxmox kernel.${NC}"
echo -e "${HEADER_LINE}"
