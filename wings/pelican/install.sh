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

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
WINGS_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$(dirname "$WINGS_DIR")"
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"

download_binary() {
    local ARCH=$(detect_arch)
    local FILENAME="wings_linux_${ARCH}"
    local LOCAL_PATH="$BASE_DIR/daemon/pelican/$FILENAME"

    if [ -f "$LOCAL_PATH" ]; then
        cp "$LOCAL_PATH" /usr/local/bin/wings
        chmod +x /usr/local/bin/wings
        ok "Binary copied from local repo"
        return
    fi

    local REMOTE_URL="$GITHUB_RAW/daemon/pelican/$FILENAME"
    if curl -fsL -o /usr/local/bin/wings "$REMOTE_URL"; then
        chmod +x /usr/local/bin/wings
        ok "Binary downloaded from repo"
        return
    fi

    curl -L -o /usr/local/bin/wings \
        "https://github.com/pelican-dev/wings/releases/latest/download/$FILENAME"
    chmod +x /usr/local/bin/wings
    ok "Binary downloaded from upstream"
}

show_banner() {
    clear
    echo -e "${PURPLE}"
    cat << "EOF"
   ____      _ _       _
  |  _ \ ___(_) |_ ___(_)_ __   ___ ___
  | |_) / _ \ | __/ __| | '_ \ / _ \ __|
  |  __/  __/ | || (__| | | | |  __\__ \
  |_|   \___|_|\__\___|_|_| |_|\___|___/
          ___    _   _   ___  ___
         | _ \  /_\ | \ / / |_  )
         |  _/ / _ \ \   /   / /
         |_|  /_/ \_\ |_|   /___|
EOF
    echo -e "${HEADER_LINE}"
    echo -e "           ${WHITE}PELICAN WINGS DAEMON${NC}"
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
    mkdir -p /etc/pelican
    mkdir -p /var/lib/pelican

    download_binary

    echo ""
    echo -e "  ${GOLD}Create your node in the Pelican panel first,${NC}"
    echo -e "  ${GOLD}then paste the configuration below:${NC}"
    echo ""
    echo -ne "  ${CYAN}Paste config (Ctrl+D to finish):${NC}\n"
    cat > /etc/pelican/config.yml

    step "Creating systemd service..."
    cat > /etc/systemd/system/wings.service << SERVICEEOF
[Unit]
Description=Pelican Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/var/lib/pelican
LimitNOFILE=4096
PIDFile=/var/run/wings/pid.pid
ExecStart=/usr/local/bin/wings --config /etc/pelican/config.yml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICEEOF

    systemctl daemon-reload
    systemctl enable --now wings
    ok "wings service started"

    echo -e "${HEADER_LINE}"
    echo -e "\n  ${CYAN}PELICAN WINGS INSTALLED${NC}"
    echo -e "  ${GRAY}Check status: systemctl status wings${NC}"
    echo -e "${HEADER_LINE}"
}

uninstall_wings() {
    echo -e "  ${RED}WARNING: This will remove Pelican Wings!${NC}"
    read -p "  Are you sure? (y/N): " confirm
    [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "  ${GREEN}Cancelled.${NC}"; exit; }

    systemctl stop wings 2>/dev/null || true
    systemctl disable wings 2>/dev/null || true
    rm -f /etc/systemd/system/wings.service
    systemctl daemon-reload
    rm -f /usr/local/bin/wings

    echo ""
    echo -ne "  ${CYAN}Remove config and data files?${NC} ${WHITE}(y/N)${NC}: "
    read -r remove_data
    if [[ "$remove_data" == "y" || "$remove_data" == "Y" ]]; then
        rm -rf /etc/pelican
        rm -rf /var/lib/pelican
        ok "Config and data removed"
    fi

    ok "Pelican Wings uninstalled"
}

update_wings() {
    step "Updating Pelican Wings binary..."
    download_binary

    systemctl restart wings
    ok "Pelican Wings updated"
}

case "${1:-install}" in
    install)   install_wings ;;
    uninstall) uninstall_wings ;;
    update)    update_wings ;;
    *)
        echo "  Usage: $0 {install|uninstall|update}"
        exit 1
        ;;
esac
