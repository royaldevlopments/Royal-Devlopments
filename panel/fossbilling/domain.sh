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
    if [ ! -d "/var/www/fossbilling" ]; then echo -e "  ${RED}FOSSBilling not installed.${NC}"; return 1; fi
}

echo -e "  ${GOLD}FOSSBilling Domain / SSL${NC}"
echo ""
read -p "  New domain (e.g. billing.example.com): " DOMAIN
[ -z "$DOMAIN" ] && { echo -e "  ${RED}Cancelled.${NC}"; exit; }

check || exit 1

mkdir -p /etc/certs/fossbilling
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/fossbilling/privkey.pem \
    -out /etc/certs/fossbilling/fullchain.pem 2>/dev/null

cat > /etc/nginx/sites-available/fossbilling.conf << NGINX
server {
    listen 80;
    server_name ${DOMAIN};
    return 301 https://\$server_name\$request_uri;
}
server {
    listen 443 ssl http2;
    server_name ${DOMAIN};
    root /var/www/fossbilling;
    index index.php;
    ssl_certificate /etc/certs/fossbilling/fullchain.pem;
    ssl_certificate_key /etc/certs/fossbilling/privkey.pem;
    client_max_body_size 100m;
    sendfile off;
    set \$root_path /var/www/fossbilling;
    try_files \$uri \$uri/ @rewrite;
    location @rewrite {
        rewrite ^/page/(.*)$ /index.php?_url=/custompages/\$1;
        rewrite ^/(.*)$ /index.php?_url=/\$1;
    }
    location ~ \.php\$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)\$;
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param PATH_INFO \$fastcgi_path_info;
        fastcgi_intercept_errors on;
    }
    location ~* .(ini|sh|inc|bak|twig|sql)\$ { return 403; }
    location ^~ /vendor/ { return 403; }
    location = /config.php { return 403; }
    location ~ /\.(?!well-known\/) { return 403; }
    location ^~ /data/ { return 403; }
    location ~* ^/(css|img|js|flv|swf|download)/(.+)\$ {
        root \$root_path;
        expires off;
    }
}
NGINX

nginx -t && systemctl restart nginx
echo -e "  ${GREEN}[OK]${NC} Domain updated to https://$DOMAIN"
