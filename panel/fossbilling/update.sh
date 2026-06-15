#!/bin/bash

CYAN='\033[38;5;51m'
PURPLE='\033[38;5;141m'
GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
NC='\033[0m'

if [ ! -d "/var/www/fossbilling" ]; then
    echo -e "  ${RED}FOSSBilling is not installed.${NC}"
    exit 1
fi

echo -e "  ${PURPLE}::${NC} Downloading latest release..."
DL_URL=$(curl -sf "https://api.github.com/repos/FOSSBilling/FOSSBilling/releases/latest" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['assets'][0]['browser_download_url'])" 2>/dev/null) || {
    echo -e "  ${RED}Failed to fetch latest release.${NC}"
    exit 1
}

cd /var/www/fossbilling || exit 1
wget -qO fossbilling_update.zip "$DL_URL"

echo -e "  ${PURPLE}::${NC} Extracting files..."
unzip -qo fossbilling_update.zip
rm fossbilling_update.zip
chown -R www-data:www-data /var/www/fossbilling

echo -e "  ${GREEN}[OK]${NC} FOSSBilling files updated."
echo -e "  ${GOLD}Visit the admin panel to run any pending database migrations.${NC}"
