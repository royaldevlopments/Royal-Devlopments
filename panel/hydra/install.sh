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
INSTALL_DIR="/var/www/hydra"

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PANEL_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$(dirname "$PANEL_DIR")"
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"

download_src() {
    local SRC_FILE="hydrapanel.tar.gz"
    local LOCAL_PATH="$BASE_DIR/src/hydra/$SRC_FILE"

    if [ -f "$LOCAL_PATH" ]; then
        cp "$LOCAL_PATH" "./$SRC_FILE"
        ok "Copied from local repo"
        tar -xzf "$SRC_FILE"
        return 0
    fi

    echo -e "  ${YELLOW}Local source not found. Trying GitHub raw...${NC}"
    if curl -sL "$GITHUB_RAW/src/hydra/$SRC_FILE" -o "$SRC_FILE" 2>/dev/null; then
        ok "Downloaded from GitHub raw"
        tar -xzf "$SRC_FILE"
        return 0
    fi

    return 1
}

show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
   ██╗  ██╗██╗   ██╗██████╗ ██████╗  █████╗
   ██║  ██║╚██╗ ██╔╝██╔══██╗██╔══██╗██╔══██╗
   ███████║ ╚████╔╝ ██║  ██║██████╔╝███████║
   ██╔══██║  ╚██╔╝  ██║  ██║██╔══██╗██╔══██║
   ██║  ██║   ██║   ██████╔╝██║  ██║██║  ██║
   ╚═╝  ╚═╝   ╚═╝   ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝
EOF
    echo -e "           ${WHITE}HYDRAPANEL INSTALLER${NC}"
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
ask "Panel Domain" "hydra.nobita.indevs.in" DOMAIN
ask "Admin Email" "admin@hydra.com" EMAIL
ask "Admin Password" "admin123" PASSWORD

echo -e "\n  ${GOLD}┌─[ REVIEW CONFIGURATION ]${NC}"
echo -e "  ${GOLD}│${NC} ${GRAY}Domain:${NC}    $DOMAIN"
echo -e "  ${GOLD}│${NC} ${GRAY}Email:${NC}     $EMAIL"
echo -e "  ${GOLD}└───────────────────────────${NC}"

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

step "Installing system dependencies"
apt update
DEBIAN_FRONTEND=noninteractive apt install -y curl git unzip nginx certbot python3-certbot-nginx
ok "Dependencies installed"

step "Installing Node.js 20"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
DEBIAN_FRONTEND=noninteractive apt install -y nodejs
ok "Node.js $(node -v) installed"

step "Downloading HydraPanel"
[[ -d "$INSTALL_DIR" ]] && rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"
if ! download_src; then
    git clone --depth 1 https://github.com/marwanbd83487/HydraPanel.git "$INSTALL_DIR"
fi
ok "Panel cloned"

step "Installing npm dependencies"
cd "$INSTALL_DIR"
npm install --production
ok "npm deps installed"

step "Configuring panel"
cat > config.json << EOF
{
    "baseUri": "https://${DOMAIN}",
    "port": 3001,
    "domain": "${DOMAIN}",
    "mode": "production",
    "version": "0.2.0",
    "ogTitle": "HydraPanel",
    "ogDescription": "HydraPanel - Game Server Management"
}
EOF
ok "Config written"

step "Creating admin user"
node exec/createUser.js << EOF
$EMAIL
admin
$PASSWORD
y
EOF
ok "Admin user: $EMAIL"

step "Setting up SSL"
mkdir -p /etc/certs/hydra
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/hydra/privkey.pem -out /etc/certs/hydra/fullchain.pem
ok "Self-signed SSL generated"

step "Configuring Nginx"
tee /etc/nginx/sites-available/hydra.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    ssl_certificate /etc/certs/hydra/fullchain.pem;
    ssl_certificate_key /etc/certs/hydra/privkey.pem;
    client_max_body_size 100m;
    location / {
        proxy_pass http://127.0.0.1:3001;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

ln -sf /etc/nginx/sites-available/hydra.conf /etc/nginx/sites-enabled/hydra.conf
nginx -t && systemctl restart nginx
ok "Nginx configured"

step "Creating systemd service"
cat > /etc/systemd/system/hydrapanel.service << EOF
[Unit]
Description=HydraPanel
After=network.target
[Service]
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/node index.js
Restart=always
RestartSec=5
User=root
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now hydrapanel
ok "Service started"

clear
echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}HYDRAPANEL DEPLOYMENT COMPLETE${NC}"
echo -e "  ${GRAY}Panel URL :${NC} ${WHITE}https://$DOMAIN${NC}"
echo -e "  ${GRAY}Email     :${NC} ${WHITE}$EMAIL${NC}"
echo -e "  ${GRAY}Password  :${NC} ${WHITE}$PASSWORD${NC}"
echo -e "${HEADER_LINE}"
