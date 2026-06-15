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

PANEL_NAME="$1"
PANEL_NAME="${PANEL_NAME:-HydraPanel}"
BINARY_NAME="${2:-hydra-daemon}"
CONFIG_DIR="${4:-/var/www/hydra/daemon}"
SERVICE_NAME="${5:-hydra-daemon}"

show_banner() {
    clear
    echo -e "${CYAN}"
    echo -e "  _   _       _               _   _          _ "
    echo -e " | | | |_   _| |__  _ __ __ _| \ | | ___  __| |"
    echo -e " | |_| | | | | '_ \| '__/ _\` |  \| |/ _ \/ _\` |"
    echo -e " |  _  | |_| | | | | | | (_| | |\  |  __/ (_| |"
    echo -e " |_| |_|\__, |_| |_|_|  \__,_|_| \_|\___|\__,_|"
    echo -e "        |___/                                   "
    echo -e "${HEADER_LINE}"
    echo -e "           ${WHITE}${PANEL_NAME} DAEMON${NC}"
    echo -e "${HEADER_LINE}"
}

ok()    { echo -e "  ${GREEN}[OK]${NC} $1"; }
step()  { echo -e "\n  ${PURPLE}::${NC} ${WHITE}$1${NC}"; }
fail()  { echo -e "  ${RED}[FAIL]${NC} $1"; }

install_wings() {
    show_banner
    step "Installing Node.js and npm..."
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt-get install -y nodejs
        ok "Node.js installed"
    else
        ok "Node.js already installed ($(node --version))"
    fi

    step "Installing Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | bash
        systemctl enable --now docker
        ok "Docker installed"
    else
        ok "Docker already installed"
    fi

    step "Cloning ${BINARY_NAME} repository..."
    mkdir -p "$CONFIG_DIR"
    if [ -d "$CONFIG_DIR/.git" ]; then
        cd "$CONFIG_DIR" && git pull
        ok "Repository updated"
    else
        git clone https://github.com/hydren-dev/HydraDAEMON.git "$CONFIG_DIR"
        ok "Repository cloned"
    fi

    step "Installing npm dependencies..."
    cd "$CONFIG_DIR"
    npm install
    ok "npm dependencies installed"

    step "Installing PM2..."
    if ! command -v pm2 &> /dev/null; then
        npm install -g pm2
        ok "PM2 installed"
    else
        ok "PM2 already installed"
    fi

    echo ""
    echo -e "  ${GOLD}Configure the daemon by editing the config file:${NC}"
    echo -e "  ${WHITE}${CONFIG_DIR}/config.json${NC}"
    echo ""
    echo -e "  ${GRAY}Set your panel URL, access key, and daemon port.${NC}"
    echo -e "  ${GRAY}Then restart the service.${NC}"
    echo ""

    step "Creating systemd service..."
    cat > /etc/systemd/system/${SERVICE_NAME}.service << SERVICEEOF
[Unit]
Description=${PANEL_NAME} Daemon
After=docker.service network.target
Requires=docker.service

[Service]
User=root
WorkingDirectory=${CONFIG_DIR}
ExecStart=$(which node) ${CONFIG_DIR}/index.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

    systemctl daemon-reload
    systemctl enable --now ${SERVICE_NAME}
    ok "${SERVICE_NAME} service started"

    echo -e "${HEADER_LINE}"
    echo -e "\n  ${CYAN}${PANEL_NAME} DAEMON INSTALLED${NC}"
    echo -e "  ${GRAY}Check status: systemctl status ${SERVICE_NAME}${NC}"
    echo -e "  ${GRAY}Config: ${CONFIG_DIR}/config.json${NC}"
    echo -e "${HEADER_LINE}"
}

uninstall_wings() {
    echo -e "  ${RED}WARNING: This will remove ${PANEL_NAME} Daemon!${NC}"
    read -p "  Are you sure? (y/N): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GREEN}Cancelled.${NC}"; exit; }

    step "Stopping service..."
    systemctl stop ${SERVICE_NAME} 2>/dev/null || true
    systemctl disable ${SERVICE_NAME} 2>/dev/null || true

    step "Removing service file..."
    rm -f /etc/systemd/system/${SERVICE_NAME}.service
    systemctl daemon-reload

    step "Removing daemon files..."
    rm -rf "$CONFIG_DIR"

    ok "${PANEL_NAME} Daemon uninstalled"
}

update_wings() {
    step "Updating ${BINARY_NAME}..."
    if [ -d "$CONFIG_DIR/.git" ]; then
        cd "$CONFIG_DIR"
        git pull
        npm install
        ok "Dependencies updated"
    else
        fail "Repository not found at $CONFIG_DIR"
        exit 1
    fi

    step "Restarting service..."
    systemctl restart ${SERVICE_NAME}
    ok "${SERVICE_NAME} restarted"
    ok "${PANEL_NAME} Daemon updated"
}

status_wings() {
    systemctl status ${SERVICE_NAME} --no-pager 2>&1 | head -20
    echo ""
    echo -e "  ${GRAY}Directory:${NC} ${CONFIG_DIR}"
    echo -e "  ${GRAY}Config:${NC} ${CONFIG_DIR}/config.json"
}

case "$6" in
    install)   install_wings ;;
    uninstall) uninstall_wings ;;
    update)    update_wings ;;
    status)    status_wings ;;
    *)
        echo "  Usage: $0 <panel_name> <binary_name> <repo> <config_dir> <service_name> {install|uninstall|update|status}"
        exit 1
        ;;
esac
