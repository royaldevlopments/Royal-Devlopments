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
    if [ ! -d "/var/www/pteroca" ]; then echo -e "  ${RED}PteroCA not installed.${NC}"; return 1; fi
    cd /var/www/pteroca || return 1
}

echo -e "  ${GOLD}PteroCA Domain / SSL${NC}"
echo ""
read -p "  New domain (e.g. pteroca.example.com): " DOMAIN
[ -z "$DOMAIN" ] && { echo -e "  ${RED}Cancelled.${NC}"; exit; }

check || exit 1

sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|g" .env

mkdir -p /etc/certs/pteroca
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/pteroca/privkey.pem \
    -out /etc/certs/pteroca/fullchain.pem 2>/dev/null

PHP_FPM_SOCKET="unix:/run/php/php8.3-fpm.sock"
for ver in 8.4 8.3 8.2; do
    [ -S "/run/php/php${ver}-fpm.sock" ] && { PHP_FPM_SOCKET="unix:/run/php/php${ver}-fpm.sock"; break; }
done

cat > /etc/nginx/sites-available/pteroca.conf << NGINX
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    root /var/www/pteroca/public;
    index index.php;
    ssl_certificate /etc/certs/pteroca/fullchain.pem;
    ssl_certificate_key /etc/certs/pteroca/privkey.pem;
    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass ${PHP_FPM_SOCKET};
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize=100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
    location ~ /\.ht { deny all; }
    location ~ ^/(config|storage|vendor|scripts|database)/ { deny all; }
}
NGINX

nginx -t && systemctl restart nginx
echo -e "  ${GREEN}[OK]${NC} Domain updated to https://$DOMAIN"
