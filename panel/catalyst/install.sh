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
INSTALL_DIR="/opt/catalyst-docker"
REPO="catalystctl/catalyst"
BRANCH="main"

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
   ╔══════════════════════════════════════════╗
   ║          Catalyst Panel Setup           ║
   ║        Game Server Management           ║
   ╚══════════════════════════════════════════╝
EOF
    echo -e "           ${WHITE}CATALYST INSTALLER${NC}"
    echo -e "${HEADER_LINE}"
}

ok()    { echo -e "  ${GREEN}[OK]${NC} $1"; }
step()  { echo -e "\n  ${PURPLE}::${NC} ${WHITE}$1${NC}"; }

show_banner

echo -e "\n  ${GOLD}┌─[ CATALYST DOCKER INSTALL ]${NC}"
echo -e "  ${GOLD}│${NC} ${GRAY}Install Dir:${NC} $INSTALL_DIR"
echo -e "  ${GOLD}└───────────────────────────${NC}"

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

step "Installing Docker..."
if ! command -v docker &>/dev/null; then
    apt update && apt install -y ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    systemctl enable --now docker
    ok "Docker installed"
else
    ok "Docker already installed"
    if ! docker compose version &>/dev/null; then
        apt install -y docker-compose-plugin
    fi
fi

step "Downloading Catalyst..."
curl -fsSL "https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz" -o /tmp/catalyst.tar.gz
rm -rf "$INSTALL_DIR" /tmp/catalyst-extract
mkdir -p /tmp/catalyst-extract
tar -xzf /tmp/catalyst.tar.gz -C /tmp/catalyst-extract --strip-components=1 "${REPO#*/}-${BRANCH}/catalyst-docker/"
rm -f /tmp/catalyst.tar.gz
mv /tmp/catalyst-extract/catalyst-docker "$INSTALL_DIR"
rm -rf /tmp/catalyst-extract
ok "Downloaded to $INSTALL_DIR"

step "Generating configuration..."
cd "$INSTALL_DIR"

DETECTED_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
DEFAULT_URL="http://${DETECTED_IP:-localhost}:8080"

cp .env.example .env
sed -i "s~^PUBLIC_URL=.*~PUBLIC_URL=${DEFAULT_URL}~" .env
sed -i "s~^PASSKEY_RP_ID=.*~PASSKEY_RP_ID=${DETECTED_IP:-localhost}~" .env

PG_PASS=$(openssl rand -base64 48 | tr -d '/+=' | head -c 32)
AUTH_SECRET=$(openssl rand -base64 32)
REDIS_PASS=$(openssl rand -base64 48 | tr -d '/+=' | head -c 24)

sed -i "s~^POSTGRES_PASSWORD=.*~POSTGRES_PASSWORD=${PG_PASS}~" .env
sed -i "s~^BETTER_AUTH_SECRET=.*~BETTER_AUTH_SECRET=${AUTH_SECRET}~" .env
sed -i "s~^REDIS_PASSWORD=.*~REDIS_PASSWORD=${REDIS_PASS}~" .env

ok "Configuration generated"

step "Starting containers..."
docker compose up -d
ok "Catalyst is running!"

clear
echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}DEPLOYMENT COMPLETE${NC}"
echo -e "  ${GRAY}Panel URL :${NC} ${WHITE}${DEFAULT_URL}${NC}"
echo -e "  ${GRAY}Directory :${NC} ${WHITE}$INSTALL_DIR${NC}"
echo -e "\n  ${PURPLE}First user to register becomes admin!${NC}"
echo -e "\n  ${GRAY}Manage:${NC} cd $INSTALL_DIR && docker compose [up/down/restart]"
echo -e "${HEADER_LINE}"
