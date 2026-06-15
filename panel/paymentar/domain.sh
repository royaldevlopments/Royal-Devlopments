#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
GOLD='\033[38;5;214m'
NC='\033[0m'
PHP_VERSION="8.3"

check() {
    if [ ! -d "/var/www/paymenter" ]; then echo -e "  ${RED}Paymenter not installed.${NC}"; return 1; fi
    cd /var/www/paymenter || return 1
}

echo -e "  ${GOLD}Paymenter Domain / SSL${NC}"
echo ""
read -p "  New domain (e.g. billing.example.com): " DOMAIN
[ -z "$DOMAIN" ] && { echo -e "  ${RED}Cancelled.${NC}"; exit; }

check || exit 1

sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env

mkdir -p /etc/certs/paymenter
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/paymenter/privkey.pem \
    -out /etc/certs/paymenter/fullchain.pem 2>/dev/null

cat > /etc/nginx/sites-available/paymenter.conf << NGINX
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    root /var/www/paymenter/public;
    index index.php;
    ssl_certificate /etc/certs/paymenter/fullchain.pem;
    ssl_certificate_key /etc/certs/paymenter/privkey.pem;
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
    location ~ /\.ht { deny all; }
}
NGINX

nginx -t && systemctl restart nginx
echo -e "  ${GREEN}[OK]${NC} Domain updated to https://$DOMAIN"
