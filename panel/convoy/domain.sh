#!/bin/bash

PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

check() {
    if [ ! -d "/opt/convoy/panel" ]; then echo -e "  ${RED}ConvoyPanel not installed.${NC}"; return 1; fi
}

read -p "  New domain (e.g. convoy.example.com): " DOMAIN
[ -z "$DOMAIN" ] && { echo -e "  ${RED}Cancelled.${NC}"; exit; }

check || exit 1

mkdir -p /etc/certs/convoy
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/convoy/privkey.pem \
    -out /etc/certs/convoy/fullchain.pem

cat > /etc/nginx/sites-available/convoy.conf << NGINX
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    ssl_certificate /etc/certs/convoy/fullchain.pem;
    ssl_certificate_key /etc/certs/convoy/privkey.pem;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
NGINX

nginx -t && systemctl restart nginx
cd /opt/convoy/panel && sed -i "s|APP_URL=.*|APP_URL=https://$DOMAIN|" .env
echo -e "  ${GREEN}[OK]${NC} Domain updated to https://$DOMAIN"
