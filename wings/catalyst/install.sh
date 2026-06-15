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
PANEL_NAME="${PANEL_NAME:-Catalyst}"
BINARY_NAME="${2:-catalyst-agent}"
CONFIG_DIR="${4:-/opt/catalyst-agent}"
SERVICE_NAME="${5:-catalyst-agent}"

show_banner() {
    clear
    echo -e "${PURPLE}"
    echo -e "   ____        _       _                _           _   "
    echo -e "  / ___|  __ _| |_ ___| |__   ___  __ _| |_ ___  _| |_ "
    echo -e " | |     / _\` | __/ __| '_ \ / _ \/ _\` | __/ _ \|_   _|"
    echo -e " | |___ | (_| | || (__| | | |  __/ (_| | || (_) | |_|  "
    echo -e "  \____| \__,_|\__\___|_| |_|\___|\__,_|\__\___/        "
    echo -e "${HEADER_LINE}"
    echo -e "           ${WHITE}${PANEL_NAME} AGENT${NC}"
    echo -e "${HEADER_LINE}"
}

ok()    { echo -e "  ${GREEN}[OK]${NC} $1"; }
step()  { echo -e "\n  ${PURPLE}::${NC} ${WHITE}$1${NC}"; }
fail()  { echo -e "  ${RED}[FAIL]${NC} $1"; }

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        *) fail "Unsupported architecture"; exit 1 ;;
    esac
}

install_agent() {
    show_banner
    step "Installing containerd..."
    if ! command -v containerd &> /dev/null; then
        curl -fsSL https://github.com/containerd/containerd/releases/latest/download/containerd-1.7.20-linux-$(detect_arch).tar.gz | tar -C /usr/local -xz
        mkdir -p /etc/containerd
        containerd config default > /etc/containerd/config.toml
        systemctl enable --now containerd
        ok "containerd installed"
    else
        ok "containerd already installed"
    fi

    step "Installing Rust toolchain (for building agent)..."
    if ! command -v cargo &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
        ok "Rust installed"
    else
        ok "Rust already installed ($(cargo --version))"
    fi

    step "Creating directories..."
    mkdir -p "$CONFIG_DIR"
    mkdir -p /var/lib/catalyst

    step "Building ${BINARY_NAME} from source..."
    if [ ! -f /usr/local/bin/${BINARY_NAME} ]; then
        TMP_BUILD="/tmp/catalyst-build"
        if [ ! -d "$TMP_BUILD" ]; then
            git clone --depth 1 https://github.com/catalystctl/catalyst.git "$TMP_BUILD"
        fi
        cd "$TMP_BUILD/catalyst-agent"
        cargo build --release
        cp target/release/${BINARY_NAME} /usr/local/bin/${BINARY_NAME}
        chmod +x /usr/local/bin/${BINARY_NAME}
        ok "Agent binary built and installed to /usr/local/bin/${BINARY_NAME}"
    else
        ok "Agent binary already exists"
    fi

    echo ""
    echo -e "  ${GOLD}Create your node in the ${PANEL_NAME} panel first,${NC}"
    echo -e "  ${GOLD}then paste the configuration below:${NC}"
    echo ""
    echo -ne "  ${CYAN}Paste config.toml (Ctrl+D to finish):${NC}\n"
    cat > "$CONFIG_DIR/config.toml"

    step "Creating systemd service..."
    cat > /etc/systemd/system/${SERVICE_NAME}.service << SERVICEEOF
[Unit]
Description=${PANEL_NAME} Agent
After=containerd.service
Requires=containerd.service

[Service]
User=root
WorkingDirectory=${CONFIG_DIR}
LimitNOFILE=4096
ExecStart=/usr/local/bin/${BINARY_NAME} --config ${CONFIG_DIR}/config.toml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

    systemctl daemon-reload
    systemctl enable --now ${SERVICE_NAME}
    ok "${SERVICE_NAME} service started"

    echo -e "${HEADER_LINE}"
    echo -e "\n  ${CYAN}${PANEL_NAME} AGENT INSTALLED${NC}"
    echo -e "  ${GRAY}Check status: systemctl status ${SERVICE_NAME}${NC}"
    echo -e "  ${GRAY}Config: ${CONFIG_DIR}/config.toml${NC}"
    echo -e "  ${GRAY}Data: /var/lib/catalyst${NC}"
    echo -e "${HEADER_LINE}"
}

uninstall_agent() {
    echo -e "  ${RED}WARNING: This will remove ${PANEL_NAME} Agent!${NC}"
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
        rm -rf /var/lib/catalyst
        ok "Config and data removed"
    fi

    ok "${PANEL_NAME} Agent uninstalled"
}

update_agent() {
    step "Updating ${BINARY_NAME} from source..."
    TMP_BUILD="/tmp/catalyst-build"
    if [ -d "$TMP_BUILD" ]; then
        cd "$TMP_BUILD"
        git pull
    else
        git clone --depth 1 https://github.com/catalystctl/catalyst.git "$TMP_BUILD"
        cd "$TMP_BUILD"
    fi
    cd catalyst-agent
    cargo build --release
    cp target/release/${BINARY_NAME} /usr/local/bin/${BINARY_NAME}
    chmod +x /usr/local/bin/${BINARY_NAME}
    ok "Binary updated"

    step "Restarting service..."
    systemctl restart ${SERVICE_NAME}
    ok "${SERVICE_NAME} restarted"
    ok "${PANEL_NAME} Agent updated"
}

status_agent() {
    systemctl status ${SERVICE_NAME} --no-pager 2>&1 | head -20
    echo ""
    echo -e "  ${GRAY}Binary:${NC} $(which ${BINARY_NAME} 2>/dev/null || echo 'Not installed')"
    echo -e "  ${GRAY}Config:${NC} ${CONFIG_DIR}/config.toml"
    echo -e "  ${GRAY}Data:${NC} /var/lib/catalyst"
}

case "$6" in
    install)   install_agent ;;
    uninstall) uninstall_agent ;;
    update)    update_agent ;;
    status)    status_agent ;;
    *)
        echo "  Usage: $0 <panel_name> <binary_name> <repo> <config_dir> <service_name> {install|uninstall|update|status}"
        exit 1
        ;;
esac
