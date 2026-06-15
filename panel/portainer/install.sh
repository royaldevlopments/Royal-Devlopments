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
    echo -e "${CYAN}"
    cat << "EOF"
   ____           _                               _
  |  _ \ __ _ ___| |_ __ _ _ __   __ _ _ __   ___| |
  | |_) / _\ / __| __/ _\ | '_ \ / _\ | '_ \ / _ \ |
  |  __/ (_| \__ \ || (_| | | | | (_| | | | |  __/ |
  |_|   \__,_|___/\__\__,_|_| |_|\__,_|_| |_|\___|_|
EOF
    echo -e "           ${WHITE}PORTAINER INSTALLER${NC}"
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
echo -e "  ${GOLD}Portainer is a Docker container management web UI.${NC}\n"

ask "Portainer Domain" "portainer.nobita.indevs.in" DOMAIN

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

step "Installing Docker if not present..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | bash
fi

step "Deploying Portainer..."
docker volume create portainer_data 2>/dev/null || true
docker stop portainer 2>/dev/null || true
docker rm portainer 2>/dev/null || true
docker run -d \
    -p 8000:8000 \
    -p 9443:9443 \
    --name portainer \
    --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    portainer/portainer-ce:latest

step "Setting up Nginx..."
mkdir -p /etc/certs/portainer
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/portainer/privkey.pem \
    -out /etc/certs/portainer/fullchain.pem

tee /etc/nginx/sites-available/portainer.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    ssl_certificate /etc/certs/portainer/fullchain.pem;
    ssl_certificate_key /etc/certs/portainer/privkey.pem;
    location / {
        proxy_pass https://127.0.0.1:9443;
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

ln -sf /etc/nginx/sites-available/portainer.conf /etc/nginx/sites-enabled/portainer.conf
nginx -t && systemctl restart nginx

echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}PORTAINER DEPLOYED${NC}"
echo -e "  ${GRAY}URL :${NC} ${WHITE}https://$DOMAIN${NC}"
echo ""
echo -e "  ${GOLD}Set up your admin account on first visit.${NC}"
echo -e "${HEADER_LINE}"
