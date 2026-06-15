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
PANEL_NAME="${PANEL_NAME:-Skyport}"
BINARY_NAME="${2:-skyportd}"
REPO="${3:-skyportsh/skyportd}"
CONFIG_DIR="${4:-/etc/skyportd}"
SERVICE_NAME="${5:-skyportd}"

show_banner() {
    clear
    echo -e "${CYAN}"
    echo -e "   ____  _        _                _ "
    echo -e "  / ___|| | __  _| |_ _ __  _ __ | |"
    echo -e "  \___ \| |/ / |_| __| '_ \| '_ \| |"
    echo -e "   ___) |   <  _| |_| |_) | |_) |_|"
    echo -e "  |____/|_|\_\_|  \__| .__/| .__/(_)"
    echo -e "                     |_|   |_|     "
    echo -e "${HEADER_LINE}"
    echo -e "           ${WHITE}${PANEL_NAME} DAEMON${NC}"
    echo -e "${HEADER_LINE}"
}

ok()    { echo -e "  ${GREEN}[OK]${NC} $1"; }
step()  { echo -e "\n  ${PURPLE}::${NC} ${WHITE}$1${NC}"; }
fail()  { echo -e "  ${RED}[FAIL]${NC} $1"; }

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "x86_64" ;;
        aarch64|arm64) echo "aarch64" ;;
        *) fail "Unsupported architecture"; exit 1 ;;
    esac
}

install_wings() {
    show_banner
    step "Installing Docker..."
    if ! command -v docker &> /dev/null; then
        curl -fsSL https://get.docker.com | bash
        systemctl enable --now docker
        ok "Docker installed"
    else
        ok "Docker already installed"
    fi

    step "Creating directories..."
    mkdir -p "$CONFIG_DIR/config" "$CONFIG_DIR/volumes"

    step "Downloading ${BINARY_NAME} binary..."
    ARCH=$(detect_arch)
    curl -L -o /usr/local/bin/${BINARY_NAME} \
        "https://github.com/${REPO}/releases/latest/download/${BINARY_NAME}-linux-${ARCH}"
    chmod +x /usr/local/bin/${BINARY_NAME}
    ok "Binary installed to /usr/local/bin/${BINARY_NAME}"

    echo ""
    echo -e "  ${GOLD}Create your node in the ${PANEL_NAME} panel first,${NC}"
    echo -e "  ${GOLD}then paste the configuration below:${NC}"
    echo ""
    echo -ne "  ${CYAN}Paste config (Ctrl+D to finish):${NC}\n"
    cat > "$CONFIG_DIR/config/default.toml"

    step "Creating systemd service..."
    cat > /etc/systemd/system/${SERVICE_NAME}.service << SERVICEEOF
[Unit]
Description=${PANEL_NAME} Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=${CONFIG_DIR}
LimitNOFILE=4096
ExecStart=/usr/local/bin/${BINARY_NAME} --config ${CONFIG_DIR}/config
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

    step "Removing binary..."
    rm -f /usr/local/bin/${BINARY_NAME}

    echo ""
    echo -ne "  ${CYAN}Remove config and data files?${NC} ${WHITE}(y/N)${NC}: "
    read -r remove_data
    if [[ "$remove_data" == "y" || "$remove_data" == "Y" ]]; then
        rm -rf "$CONFIG_DIR"
        ok "Config and data removed"
    fi

    ok "${PANEL_NAME} Daemon uninstalled"
}

update_wings() {
    step "Updating ${BINARY_NAME} binary..."
    ARCH=$(detect_arch)
    curl -L -o /usr/local/bin/${BINARY_NAME} \
        "https://github.com/${REPO}/releases/latest/download/${BINARY_NAME}-linux-${ARCH}"
    chmod +x /usr/local/bin/${BINARY_NAME}
    ok "Binary updated"

    step "Restarting service..."
    systemctl restart ${SERVICE_NAME}
    ok "${SERVICE_NAME} restarted"
    ok "${PANEL_NAME} Daemon updated"
}

status_wings() {
    systemctl status ${SERVICE_NAME} --no-pager 2>&1 | head -20
    echo ""
    echo -e "  ${GRAY}Binary:${NC} $(which ${BINARY_NAME} 2>/dev/null || echo 'Not installed')"
    echo -e "  ${GRAY}Config:${NC} ${CONFIG_DIR}/config/default.toml"
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
