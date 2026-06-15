#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'

check() {
    if [ ! -d "/var/www/hydra" ]; then echo -e "  ${RED}HydraPanel not installed.${NC}"; return 1; fi
    cd /var/www/hydra || return 1
}

echo -e "  ${GOLD}HydraPanel Domain / SSL${NC}"
echo ""
read -p "  New domain (e.g. panel.example.com): " DOMAIN
[ -z "$DOMAIN" ] && { echo -e "  ${RED}Cancelled.${NC}"; exit; }

check || exit 1

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

mkdir -p /etc/certs/hydra
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/hydra/privkey.pem \
    -out /etc/certs/hydra/fullchain.pem 2>/dev/null

cat > /etc/nginx/sites-available/hydra.conf << NGINX
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
NGINX

nginx -t && systemctl restart nginx
echo -e "  ${GREEN}[OK]${NC} Domain updated to https://$DOMAIN"
