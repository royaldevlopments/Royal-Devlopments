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
    echo -e "${PURPLE}"
    cat << "EOF"
   ██████╗ ██╗   ██╗███████╗███████╗███████╗██████╗
   ██╔══██╗██║   ██║██╔════╝██╔════╝██╔════╝██╔══██╗
   ██████╔╝██║   ██║█████╗  █████╗  █████╗  ██████╔╝
   ██╔═══╝ ██║   ██║██╔══╝  ██╔══╝  ██╔══╝  ██╔══██╗
   ██║     ╚██████╔╝██║     ██║     ███████╗██║  ██║
   ╚═╝      ╚═════╝ ╚═╝     ╚═╝     ╚══════╝╚═╝  ╚═╝
EOF
    echo -e "           ${WHITE}PUFFERPANEL INSTALLER${NC}"
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
ask "Panel Domain (empty for IP:8080)" "puffer.nobita.indevs.in" DOMAIN
ask "Admin Email" "admin@puffer.com" EMAIL
ask "Admin Username" "admin" USERNAME
ask "Admin Password" "admin123" PASSWORD

USE_SSL=false
if [[ -n "$DOMAIN" ]]; then
    USE_SSL=true
    APP_URL="https://${DOMAIN}"
else
    APP_URL="http://$(hostname -I | awk '{print $1}'):8080"
fi

echo -e "\n  ${GOLD}┌─[ REVIEW CONFIGURATION ]${NC}"
echo -e "  ${GOLD}│${NC} ${GRAY}URL:${NC}       $APP_URL"
echo -e "  ${GOLD}│${NC} ${GRAY}Email:${NC}     $EMAIL"
echo -e "  ${GOLD}└───────────────────────────${NC}"

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

step "Installing PufferPanel"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y curl gnupg apt-transport-https

curl -fsSL https://packagecloud.io/pufferpanel/pufferpanel/gpgkey | gpg --dearmor -o /etc/apt/keyrings/pufferpanel.gpg
cat > /etc/apt/sources.list.d/pufferpanel.sources << EOF
X-Repolib-Name: PufferPanel
Types: deb
URIs: https://packagecloud.io/pufferpanel/pufferpanel/any/
Suites: any
Components: main
Signed-By: /etc/apt/keyrings/pufferpanel.gpg
EOF

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y pufferpanel
ok "PufferPanel installed"

step "Creating admin user"
pufferpanel user add << EOF
$EMAIL
$USERNAME
$PASSWORD
$PASSWORD
y
EOF
ok "Admin user: $EMAIL"

step "Starting service"
systemctl enable --now pufferpanel
ok "PufferPanel running on port 8080"

if $USE_SSL; then
    step "Setting up Nginx reverse proxy with SSL"
    DEBIAN_FRONTEND=noninteractive apt install -y nginx

    mkdir -p /etc/certs/puffer
    openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
        -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
        -keyout /etc/certs/puffer/privkey.pem -out /etc/certs/puffer/fullchain.pem

    tee /etc/nginx/sites-available/puffer.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    ssl_certificate /etc/certs/puffer/fullchain.pem;
    ssl_certificate_key /etc/certs/puffer/privkey.pem;
    client_max_body_size 100m;
    location / {
        proxy_pass http://127.0.0.1:8080;
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

    ln -sf /etc/nginx/sites-available/puffer.conf /etc/nginx/sites-enabled/puffer.conf
    nginx -t && systemctl restart nginx
    ok "Nginx configured for $DOMAIN"
fi

clear
echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}PUFFERPANEL DEPLOYMENT COMPLETE${NC}"
echo -e "  ${GRAY}Panel URL :${NC} ${WHITE}$APP_URL${NC}"
echo -e "  ${GRAY}Email     :${NC} ${WHITE}$EMAIL${NC}"
echo -e "  ${GRAY}Password  :${NC} ${WHITE}$PASSWORD${NC}"
echo -e "${HEADER_LINE}"
