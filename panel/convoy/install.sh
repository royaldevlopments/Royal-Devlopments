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
   ___                     ___
  / __|___ _ _  _ _  ___  | _ \_ _ ___ _  _ _ __
 | (__/ _ \ ' \| ' \/ _ \ |  _/ '_/ _ \ || | '_ \
  \___\___/_||_|_||_\___/ |_| |_| \___/\_,_| .__/
                                           |_|
EOF
    echo -e "           ${WHITE}CONVOYPANEL INSTALLER${NC}"
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
ask "ConvoyPanel Domain" "convoy.nobita.indevs.in" DOMAIN
ask "ConvoyPanel MySQL Password" "rand0mStr0ngPa\$\$" MYSQL_PASSWORD

while true; do
    echo -ne "\n  ${CYAN}Start Installation?${NC} ${WHITE}(y/n)${NC}${GRAY}:${NC} "
    read -n 1 -r CONFIRM; echo ""
    case $CONFIRM in [Yy]*) break ;; [Nn]*) echo -e "  ${RED}Aborted.${NC}"; exit ;; *) echo -e "  ${GRAY}Enter y or n.${NC}" ;; esac
done

echo -e "${HEADER_LINE}"

step "Installing dependencies..."
apt update && apt install -y curl git docker.io docker-compose-plugin nginx certbot python3-certbot-nginx

step "Deploying ConvoyPanel..."
mkdir -p /opt/convoy
cd /opt/convoy

if [ -d "/opt/convoy/panel" ]; then
    echo -e "  ${GOLD}ConvoyPanel already cloned, pulling latest...${NC}"
    cd /opt/convoy/panel && git pull
else
    git clone https://github.com/ConvoyPanel/panel.git .
fi

step "Configuring environment..."
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=https://$DOMAIN|" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$MYSQL_PASSWORD|" .env

step "Starting Docker containers..."
docker compose up -d

step "Running migrations..."
docker compose exec -T app php artisan migrate --force
docker compose exec -T app php artisan db:seed --force
docker compose exec -T app php artisan storage:link

step "Setting up Nginx..."
mkdir -p /etc/certs/convoy
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 \
    -subj "/C=NA/ST=NA/L=NA/O=NA/CN=${DOMAIN}" \
    -keyout /etc/certs/convoy/privkey.pem \
    -out /etc/certs/convoy/fullchain.pem

tee /etc/nginx/sites-available/convoy.conf > /dev/null << EOF
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
EOF

ln -sf /etc/nginx/sites-available/convoy.conf /etc/nginx/sites-enabled/convoy.conf
nginx -t && systemctl restart nginx

echo -e "${HEADER_LINE}"
echo -e "\n  ${CYAN}CONVOYPANEL DEPLOYED${NC}"
echo -e "  ${GRAY}URL :${NC} ${WHITE}https://$DOMAIN${NC}"
echo -e "  ${GRAY}Admin:${NC} ${WHITE}https://$DOMAIN/admin${NC}"
echo ""
cat /opt/convoy/panel/.env | grep -E "^(DB_PASSWORD|APP_KEY)" | sed 's/^/  /'
echo -e "\n  ${GOLD}Create an admin user via:${NC}"
echo -e "  ${GRAY}cd /opt/convoy/panel && docker compose exec app php artisan make:user${NC}"
echo -e "${HEADER_LINE}"
