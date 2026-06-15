#!/bin/bash

PURPLE='\033[38;5;141m'
CYAN='\033[38;5;51m'
GRAY='\033[38;5;242m'
WHITE='\033[38;5;255m'
GREEN='\033[38;5;82m'
RED='\033[38;5;196m'
YELLOW='\033[38;5;220m'
NC='\033[0m'

pause() {
    echo ""
    echo -ne "  ${GRAY}Press any key to return...${NC}"
    read -n 1 -s -r
}

fetch_blueprint_versions() {
    local json
    json=$(curl -sf "https://api.github.com/repos/BlueprintFramework/framework/releases?per_page=20" 2>/dev/null) || return 1
    echo "$json" | python3 -c "
import sys,json
data=json.load(sys.stdin)
for r in data:
    tag=r.get('tag_name','')
    if tag:
        print(tag)
" 2>/dev/null || return 1
}

select_blueprint_version() {
    echo -e "\n  ${PURPLE}::${NC} ${WHITE}Fetching Blueprint versions...${NC}" >&2
    local tags=() disp=() i=0
    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue
        tags+=("$tag"); i=$((i+1))
        disp+=("  ${GRAY}$i.${NC} ${WHITE}$tag${NC}")
    done < <(fetch_blueprint_versions 2>/dev/null) || true
    if [ ${#tags[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}No versions found. Using latest.${NC}" >&2
        echo "latest"
        return
    fi
    printf '%b\n' "${disp[@]}" >&2
    local max=${#tags[@]}
    echo "" >&2
    echo -ne "  ${PURPLE}::${NC} ${WHITE}Select version [1-$max]${NC} ${GRAY}[1 = latest]${NC}\n  ${GRAY}->${NC} " >&2
    read choice
    if [[ -z "$choice" || "$choice" == "1" ]]; then
        echo "latest"
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $max ]]; then
        echo "${tags[$((choice-1))]}"
    else
        echo "latest"
    fi
}

blueprint_fix() {
    clear
    echo -e "${YELLOW}Blueprint Fix${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    BDIR="/var/www/pterodactyl"
    if [ ! -d "$BDIR" ]; then
        echo -e "  ${RED}Pterodactyl panel not found at $BDIR${NC}"
        pause; return
    fi
    cd "$BDIR" || return
    php artisan up 2>/dev/null
    if [ ! -f "$BDIR/blueprint.sh" ]; then
        echo -e "  ${YELLOW}Blueprint is not installed.${NC}"
        echo -e "  ${YELLOW}Use option [1] Install first.${NC}"
        pause; return
    fi
    echo -e "  ${CYAN}1/7 Re-extracting Blueprint framework files...${NC}"
    local _ver
    _ver=$(grep -oP 'VERSION="\K[^"]+' blueprint.sh 2>/dev/null || echo "latest")
    if [ "$_ver" = "latest" ] || [ -z "$_ver" ]; then
        wget -q "https://github.com/BlueprintFramework/framework/releases/latest/download/release.zip" -O /tmp/bfix.zip
    else
        wget -q "https://github.com/BlueprintFramework/framework/releases/download/${_ver}/release.zip" -O /tmp/bfix.zip
    fi
    if [ -f "/tmp/bfix.zip" ] && [ "$(stat -c%s /tmp/bfix.zip 2>/dev/null)" -gt 1000 ]; then
        unzip -o /tmp/bfix.zip -d "$BDIR" 2>/dev/null
        rm -f /tmp/bfix.zip
        echo -e "  ${GREEN}->${NC} Framework files restored"
    else
        rm -f /tmp/bfix.zip 2>/dev/null
        echo -e "  ${YELLOW}->${NC} Download failed, using existing files"
    fi
    echo -e "  ${CYAN}2/7 Re-building frontend assets...${NC}"
    command -v yarn &>/dev/null || npm install -g yarn 2>/dev/null
    if [ -f "package.json" ]; then
        timeout 90 yarn install 2>/dev/null
        timeout 180 yarn run production 2>/dev/null
    fi
    echo -e "  ${CYAN}3/7 Fixing .blueprintrc...${NC}"
    if [ ! -f ".blueprintrc" ]; then
        echo 'WEBUSER="www-data";OWNERSHIP="www-data:www-data";USERSHELL="/bin/bash";' > .blueprintrc
    fi
    chown www-data:www-data .blueprintrc 2>/dev/null
    export PTERODACTYL_DIRECTORY="$BDIR"
    echo -e "  ${CYAN}4/7 Re-building autoload & caches...${NC}"
    mkdir -p .blueprint/extensions/blueprint/private/db 2>/dev/null
    echo '<?php return [];' > .blueprint/extensions/blueprint/private/extensionfs.php 2>/dev/null
    : > .blueprint/extensions/blueprint/private/db/installed_extensions 2>/dev/null
    composer dump-autoload 2>/dev/null
    php artisan view:clear 2>/dev/null
    php artisan route:clear 2>/dev/null
    php artisan config:clear 2>/dev/null
    php artisan cache:clear 2>/dev/null
    echo -e "  ${CYAN}5/7 Fixing permissions...${NC}"
    chown -R www-data:www-data "$BDIR/blueprint" "$BDIR/.blueprint" 2>/dev/null
    chown www-data:www-data "$BDIR/blueprint.sh" 2>/dev/null
    chmod -R 755 "$BDIR/storage" "$BDIR/bootstrap/cache" 2>/dev/null
    chown -R www-data:www-data "$BDIR/storage" "$BDIR/bootstrap/cache" 2>/dev/null
    echo -e "  ${CYAN}6/7 Removing stale locks...${NC}"
    rm -f .blueprint/lock 2>/dev/null
    rm -rf .blueprint/blueprint 2>/dev/null
    echo -e "  ${CYAN}7/7 Restarting services...${NC}"
    php artisan queue:restart 2>/dev/null
    systemctl restart php8.3-fpm 2>/dev/null || service php8.3-fpm restart 2>/dev/null || true
    php artisan up 2>/dev/null
    echo ""
    if [ -s "$BDIR/storage/logs/laravel.log" ]; then
        echo -e "  ${YELLOW}Errors in log:${NC}"
        tail -15 "$BDIR/storage/logs/laravel.log" 2>/dev/null | while IFS= read -r _line; do
            echo -e "  ${RED}->${NC} ${_line:0:250}"
        done
    fi
    echo -e "  ${GREEN}Blueprint fix completed!${NC}"
    echo -e "  ${GRAY}If /admin/extensions still shows 500, run:${NC}"
    echo -e "  ${GRAY}tail -50 ${BDIR}/storage/logs/laravel.log${NC}"
    pause
}

blueprint_menu() {
    while true; do
        clear
        echo -e "${CYAN}"
        echo -e "   ____  _            _    _            _           _    "
        echo -e "  | __ )| |_   _  ___| | _| |_ ___  ___| |__   __ _| |_ "
        echo -e "  |  _ \| | | | |/ __| |/ / __/ _ \/ __| '_ \ / _\ | __|"
        echo -e "  | |_) | | |_| | (__|   <| ||  __/ (__| |_) | (_| | |_ "
        echo -e "  |____/|_|\__,_|\___|_|\_\\__\___|\___|_.__/ \__,_|\__|"
        echo -e "${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${GREEN}[1]${NC} Install"
        echo -e "  ${RED}[2]${NC} Uninstall"
        echo -e "  ${CYAN}[3]${NC} Update"
        echo -e "  ${YELLOW}[4]${NC} Check Status"
        echo -e "  ${PURPLE}[5]${NC} Blueprint Extensions Theme"
        echo -e "  ${CYAN}[6]${NC} Blueprint Addons"
        echo -e "  ${GREEN}[7]${NC} Fix Blueprint"
        echo -e "  ${RED}[0]${NC} Back"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo ""
        echo -ne "  ${CYAN}Select Option [0-7]:${NC} "
        read p

        case $p in
            1)
                clear
                echo -e "${YELLOW}Installing Blueprint Framework...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found at $BDIR${NC}"
                else
                    BVERSION=$(select_blueprint_version)
                    cd "$BDIR" || exit
                    rm -f bootstrap/cache/config.php bootstrap/cache/services.php bootstrap/cache/packages.php 2>/dev/null
                    sed -i "/ExtensionfsConfigProvider/d" app/Providers/AppServiceProvider.php 2>/dev/null
                    sed -i "/RouteServiceProvider/d" app/Providers/AppServiceProvider.php 2>/dev/null
                    sed -i "/BlueprintFramework/d" app/Providers/AppServiceProvider.php 2>/dev/null
                    php artisan up 2>/dev/null
                    echo -e "  ${CYAN}Installing dependencies...${NC}"
                    apt update -qq && apt install -y -qq zip unzip wget curl gnupg ca-certificates 2>/dev/null
                    if ! command -v node &>/dev/null; then
                        echo -e "  ${CYAN}Installing Node.js...${NC}"
                        mkdir -p /etc/apt/keyrings
                        curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg 2>/dev/null
                        echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list >/dev/null
                        apt update -qq && apt install -y -qq nodejs 2>/dev/null
                    fi
                    echo -e "  ${CYAN}Downloading Blueprint ${WHITE}$BVERSION${CYAN}...${NC}"
                    if [ "$BVERSION" = "latest" ]; then
                        wget -q "https://github.com/BlueprintFramework/framework/releases/latest/download/release.zip" -O release.zip
                    else
                        wget -q "https://github.com/BlueprintFramework/framework/releases/download/${BVERSION}/release.zip" -O release.zip
                    fi
                    if [ ! -f "release.zip" ] || [ "$(stat -c%s release.zip 2>/dev/null)" -lt 1000 ]; then
                        echo -e "  ${RED}Download failed! Check internet connection.${NC}"
                    else
                        unzip -o release.zip 2>/dev/null
                        rm -f release.zip
                        if [ ! -f "blueprint.sh" ]; then
                            echo -e "  ${RED}Extraction failed - blueprint.sh not found${NC}"
                        else
                            command -v yarn &>/dev/null || npm install -g yarn 2>/dev/null
                            mkdir -p .blueprint/extensions/blueprint/private/db 2>/dev/null
                            echo '<?php return [];' > .blueprint/extensions/blueprint/private/extensionfs.php 2>/dev/null
                            : > .blueprint/extensions/blueprint/private/db/installed_extensions 2>/dev/null
                            echo -e "  ${CYAN}Installing npm packages...${NC}"
                            timeout 60 yarn install 2>&1 | tail -3
                            php artisan down 2>/dev/null
                            if [ ! -f ".blueprintrc" ]; then
                                export PTERODACTYL_DIRECTORY="$BDIR"
                                if [ -d "app/BlueprintFramework" ]; then
                                    echo -e "  ${YELLOW}Creating .blueprintrc for existing installation...${NC}"
                                else
                                    timeout 30 bash blueprint.sh 2>&1 | tail -5
                                fi
                                if [ ! -f ".blueprintrc" ]; then
                                    echo 'WEBUSER="www-data";OWNERSHIP="www-data:www-data";USERSHELL="/bin/bash";' > .blueprintrc
                                    chown www-data:www-data .blueprintrc
                                fi
                            fi
                            rm -f .blueprint/lock 2>/dev/null
                            rm -rf .blueprint/blueprint 2>/dev/null
                            chmod -R 755 storage/ bootstrap/cache 2>/dev/null
                            chown -R www-data:www-data "$BDIR/storage" "$BDIR/bootstrap/cache" 2>/dev/null
                            echo -e "  ${CYAN}Rebuilding autoloader...${NC}"
                            composer dump-autoload 2>&1 | tail -5
                            echo -e "  ${CYAN}Setting up Blueprint database...${NC}"
                            php artisan migrate --force 2>&1 | tail -5
                            php artisan db:seed --class=BlueprintSeeder 2>&1 | tail -5
                            php artisan tinker --execute="
                                \$s = Illuminate\Support\Facades\Schema::class;
                                if (!\$s::hasTable('blueprint_settings')) {
                                    \$s::create('blueprint_settings', function (\$t) {
                                        \$t->string('key')->primary();
                                        \$t->text('value')->nullable();
                                        \$t->timestamps();
                                    });
                                    echo '[OK] blueprint_settings table created\n';
                                }
                                Illuminate\Support\Facades\DB::table('blueprint_settings')->updateOrInsert(
                                    ['key' => 'setup_finished'], ['value' => '1']
                                );
                                echo '[OK] setup_finished set\n';
                            " 2>&1
                            rm -f .blueprint/lock 2>/dev/null
                            local _bpcmd=""
                            if command -v blueprint &>/dev/null; then
                                _bpcmd="blueprint"
                            elif [ -f "blueprint/framework" ]; then
                                _bpcmd="./blueprint/framework"
                            elif [ -f "blueprint.sh" ]; then
                                _bpcmd="bash blueprint.sh"
                            fi
                            if [ -n "$_bpcmd" ]; then
                                yes | timeout -k 10 120 $_bpcmd -upgrade 2>&1
                                echo ""
                            fi
                            mkdir -p .blueprint/tmp .blueprint/extensions/blueprint/private/debug 2>/dev/null
                            if [ ! -f ".blueprintrc" ]; then
                                echo 'WEBUSER="www-data";OWNERSHIP="www-data:www-data";USERSHELL="/bin/bash";' > .blueprintrc
                                chown www-data:www-data .blueprintrc
                            fi
                            echo -e "  ${CYAN}Clearing Laravel caches...${NC}"
                            rm -rf bootstrap/cache/*.php storage/framework/cache/data/* 2>/dev/null
                            php artisan view:clear 2>&1 | tail -5
                            php artisan route:clear 2>&1 | tail -5
                            php artisan queue:restart 2>/dev/null
                            echo -e "  ${CYAN}Fixing permissions after upgrade...${NC}"
                            chown -R www-data:www-data "$BDIR/storage" "$BDIR/bootstrap/cache" "$BDIR/.blueprint" 2>/dev/null
                            chmod -R 755 "$BDIR/storage" "$BDIR/bootstrap/cache" "$BDIR/.blueprint" 2>/dev/null
                            echo -e "  ${CYAN}Restarting PHP-FPM to clear opcache...${NC}"
                            systemctl restart php8.3-fpm 2>/dev/null || service php8.3-fpm restart 2>/dev/null || true
                            echo -e "  ${CYAN}Bringing panel online...${NC}"
                            php artisan up 2>&1 | tail -5
                            echo ""
                            echo -e "  ${GREEN}Blueprint Install Completed!${NC}"
                            echo ""
                            echo -e "  ${CYAN}Testing panel HTTP response...${NC}"
                            sleep 2
                            local _dbg=$(grep -oP 'APP_DEBUG=\K[^ ]+' .env 2>/dev/null | head -1)
                            local _app_url=$(grep -oP 'APP_URL=\K[^ ]+' .env 2>/dev/null | head -1)
                            local _code=""
                            for _try_url in "$_app_url" "http://127.0.0.1" "http://localhost"; do
                                [ -z "$_try_url" ] && continue
                                _code=$(curl -s -o /tmp/ptero-test.html -w "%{http_code}" --connect-timeout 5 "$_try_url" 2>/dev/null)
                                [ -n "$_code" ] && [ "$_code" != "000" ] && break
                            done
                            if [ "$_code" = "200" ] || [ "$_code" = "302" ] || [ "$_code" = "301" ]; then
                                echo -e "  ${GREEN}Panel responds OK (HTTP $_code)${NC}"
                            else
                                echo -e "  ${RED}Panel returned HTTP $_code${NC}"
                                if [ -f /tmp/ptero-test.html ]; then
                                    echo -e "  ${YELLOW}Response body (first 30 lines):${NC}"
                                    head -30 /tmp/ptero-test.html 2>/dev/null | while IFS= read -r _line; do
                                        [ -n "$_line" ] && echo -e "  ${_line:0:250}"
                                    done
                                fi
                            fi
                            rm -f /tmp/ptero-test.html
                            sed -i "s/APP_DEBUG=true/APP_DEBUG=$_dbg/" .env 2>/dev/null
                            if [ -s "$BDIR/storage/logs/laravel.log" ]; then
                                echo -e "  ${YELLOW}Errors in log:${NC}"
                                tail -15 "$BDIR/storage/logs/laravel.log" 2>/dev/null | while IFS= read -r _line; do
                                    echo -e "  ${RED}->${NC} ${_line:0:250}"
                                done
                            fi
                        fi
                    fi
                fi
                pause
                ;;
            2)
                clear
                echo -e "${YELLOW}Removing Blueprint Framework...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found at $BDIR${NC}"
                elif [ ! -f "$BDIR/blueprint.sh" ]; then
                    echo -e "  ${YELLOW}Blueprint is not installed. Nothing to remove.${NC}"
                else
                    echo -ne "  ${YELLOW}WARNING: This will fully remove Blueprint. Continue? [y/N]:${NC} "
                    read confirm
                    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
                        echo -e "  ${YELLOW}Removal cancelled.${NC}"
                    else
                        cd "$BDIR" || exit
                        php artisan up 2>/dev/null
                        php artisan down 2>/dev/null
                        echo -e "  ${CYAN}Removing all Blueprint files...${NC}"
                        rm -f bootstrap/cache/config.php bootstrap/cache/services.php bootstrap/cache/packages.php 2>/dev/null
                        rm -rf "$BDIR/blueprint"
                        rm -f "$BDIR/blueprint.sh"
                        rm -f "$BDIR/.blueprintrc"
                        rm -rf "$BDIR/.blueprint"
                        sed -i "/Blueprint\\\\ExtensionfsConfigProvider/d" config/app.php 2>/dev/null
                        sed -i "/BlueprintFramework/d" config/app.php 2>/dev/null
                        sed -i "/BlueprintExtensionLibrary/d" config/app.php 2>/dev/null
                        sed -i "/RouteServiceProvider/d" config/app.php 2>/dev/null
                        rm -rf "$BDIR/app/Providers/Blueprint"
                        sed -i "/ExtensionfsConfigProvider/d" "$BDIR/app/Providers/AppServiceProvider.php" 2>/dev/null
                        sed -i "/RouteServiceProvider/d" "$BDIR/app/Providers/AppServiceProvider.php" 2>/dev/null
                        sed -i "/BlueprintFramework/d" "$BDIR/app/Providers/AppServiceProvider.php" 2>/dev/null
                        rm -rf "$BDIR/app/BlueprintFramework"
                        rm -rf "$BDIR/app/Http/Controllers/Admin/Extensions/Blueprint"
                        rm -rf "$BDIR/app/Console/Commands/BlueprintFramework"
                        rm -f "$BDIR/app/Services/Helpers/BlueprintExtensionLibrary.php"
                        rm -f "$BDIR/app/Services/Telemetry/RegisterBlueprintTelemetry.php"
                        rm -f "$BDIR/app/Services/Telemetry/BlueprintTelemetryCollectionService.php"
                        rm -f "$BDIR/database/Seeders/BlueprintSeeder.php"
                        rm -f "$BDIR/routes/blueprint.php"
                        rm -rf "$BDIR/routes/blueprint"
                        rm -rf "$BDIR/public/extensions/blueprint"
                        rm -rf "$BDIR/public/assets/extensions/blueprint"
                        rm -rf "$BDIR/resources/scripts/blueprint"
                        rm -rf "$BDIR/resources/views/blueprint"
                        rm -rf "$BDIR/scripts"
                        echo -e "  ${GREEN}[OK]${NC} All Blueprint files removed"
                        echo ""
                        : > "$BDIR/storage/logs/laravel.log" 2>/dev/null
                        echo -e "  ${CYAN}Restoring original Pterodactyl files...${NC}"
                        echo -e "  ${GRAY}->${NC} Downloading latest Pterodactyl release..."
                        curl -Lso /tmp/ptero-panel.tar.gz "https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz" 2>/dev/null
                        if [ -f "/tmp/ptero-panel.tar.gz" ] && [ "$(stat -c%s /tmp/ptero-panel.tar.gz 2>/dev/null)" -gt 10000 ]; then
                            echo -e "  ${GRAY}->${NC} Extracting stock files..."
                            tar -xzf /tmp/ptero-panel.tar.gz -C "$BDIR" 2>/dev/null
                            rm -f /tmp/ptero-panel.tar.gz
                            echo -e "  ${GRAY}->${NC} Restoring dependencies (this may take a minute)..."
                            chmod -R 755 storage/ bootstrap/cache/ 2>/dev/null
                            COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader 2>&1 | tail -5
                            echo -e "  ${GRAY}->${NC} Running migrations..."
                            php artisan migrate --force 2>&1 | tail -3
                            echo -e "  ${GREEN}->${NC} Core files restored"
                        else
                            rm -f /tmp/ptero-panel.tar.gz 2>/dev/null
                            echo -e "  ${YELLOW}->${NC} Download failed, cleaning config only"
                        fi
                        php artisan optimize:clear 2>&1 | tail -3
                        php artisan route:clear 2>/dev/null
                        chown -R www-data:www-data "$BDIR" 2>/dev/null
                        php artisan queue:restart 2>/dev/null
                        echo -e "  ${CYAN}Restarting PHP-FPM to clear opcache...${NC}"
                        systemctl restart php8.3-fpm 2>/dev/null || service php8.3-fpm restart 2>/dev/null || true
                        php artisan up 2>/dev/null
                        echo -e "  ${GREEN}[OK]${NC} Panel restored"
                        echo ""
                        if [ -s "$BDIR/storage/logs/laravel.log" ]; then
                            echo -e "  ${YELLOW}Last 20 lines of error log:${NC}"
                            tail -20 "$BDIR/storage/logs/laravel.log" 2>/dev/null | while IFS= read -r _line; do
                                echo -e "  ${RED}->${NC} ${_line:0:250}"
                            done
                        else
                            echo -e "  ${GREEN}No errors in log${NC}"
                        fi
                        echo -e "  ${GREEN}Blueprint fully removed!${NC}"
                    fi
                fi
                pause
                ;;
            3)
                clear
                echo -e "${YELLOW}Updating Blueprint Framework...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                elif [ ! -f "$BDIR/blueprint.sh" ]; then
                    echo -e "  ${YELLOW}Blueprint is not installed. Install it first.${NC}"
                else
                    BVERSION=$(select_blueprint_version)
                    cd "$BDIR" || exit
                    php artisan up 2>/dev/null
                    php artisan down 2>/dev/null
                    rm -f .blueprint/lock 2>/dev/null
                    rm -rf .blueprint/blueprint 2>/dev/null
                    echo -e "  ${CYAN}Installing dependencies...${NC}"
                    apt update -qq && apt install -y -qq zip unzip wget curl 2>/dev/null
                    echo -e "  ${CYAN}Downloading Blueprint ${WHITE}$BVERSION${CYAN}...${NC}"
                    if [ "$BVERSION" = "latest" ]; then
                        wget -q "https://github.com/BlueprintFramework/framework/releases/latest/download/release.zip" -O release.zip
                    else
                        wget -q "https://github.com/BlueprintFramework/framework/releases/download/${BVERSION}/release.zip" -O release.zip
                    fi
                    if [ ! -f "release.zip" ] || [ "$(stat -c%s release.zip 2>/dev/null)" -lt 1000 ]; then
                        echo -e "  ${RED}Download failed!${NC}"
                    else
                        unzip -o release.zip 2>/dev/null
                        rm -f release.zip
                        if [ ! -f "blueprint.sh" ]; then
                            echo -e "  ${RED}Extraction failed - blueprint.sh not found${NC}"
                        else
                            command -v yarn &>/dev/null || npm install -g yarn 2>/dev/null
                            echo -e "  ${CYAN}Installing npm packages...${NC}"
                            timeout 60 yarn install 2>&1 | tail -3
                            chmod -R 755 storage/ bootstrap/cache 2>/dev/null
                            chown -R www-data:www-data "$BDIR/storage" "$BDIR/bootstrap/cache" 2>/dev/null
                            echo -e "  ${CYAN}Rebuilding autoloader...${NC}"
                            composer dump-autoload 2>&1 | tail -5
                            echo -e "  ${CYAN}Setting up Blueprint database...${NC}"
                            php artisan migrate --force 2>&1 | tail -5
                            php artisan db:seed --class=BlueprintSeeder 2>&1 | tail -5
                            php artisan tinker --execute="
                                \$s = Illuminate\Support\Facades\Schema::class;
                                if (!\$s::hasTable('blueprint_settings')) {
                                    \$s::create('blueprint_settings', function (\$t) {
                                        \$t->string('key')->primary();
                                        \$t->text('value')->nullable();
                                        \$t->timestamps();
                                    });
                                    echo '[OK] blueprint_settings table created\n';
                                }
                                Illuminate\Support\Facades\DB::table('blueprint_settings')->updateOrInsert(
                                    ['key' => 'setup_finished'], ['value' => '1']
                                );
                                echo '[OK] setup_finished set\n';
                            " 2>&1
                            rm -f .blueprint/lock 2>/dev/null
                            local _bpcmd=""
                            if command -v blueprint &>/dev/null; then
                                _bpcmd="blueprint"
                            elif [ -f "blueprint/framework" ]; then
                                _bpcmd="./blueprint/framework"
                            elif [ -f "blueprint.sh" ]; then
                                _bpcmd="bash blueprint.sh"
                            fi
                            if [ -n "$_bpcmd" ]; then
                                yes | timeout -k 10 120 $_bpcmd -upgrade 2>&1
                                echo ""
                            fi
                            mkdir -p .blueprint/tmp .blueprint/extensions/blueprint/private/debug 2>/dev/null
                            if [ ! -f ".blueprintrc" ]; then
                                echo 'WEBUSER="www-data";OWNERSHIP="www-data:www-data";USERSHELL="/bin/bash";' > .blueprintrc
                                chown www-data:www-data .blueprintrc
                            fi
                            echo -e "  ${CYAN}Clearing caches...${NC}"
                            rm -rf bootstrap/cache/*.php storage/framework/cache/data/* 2>/dev/null
                            php artisan view:clear 2>&1 | tail -5
                            php artisan route:clear 2>&1 | tail -5
                            php artisan queue:restart 2>/dev/null
                            echo -e "  ${CYAN}Fixing permissions...${NC}"
                            chown -R www-data:www-data "$BDIR/storage" "$BDIR/bootstrap/cache" "$BDIR/.blueprint" 2>/dev/null
                            chmod -R 755 "$BDIR/storage" "$BDIR/bootstrap/cache" "$BDIR/.blueprint" 2>/dev/null
                            echo -e "  ${CYAN}Restarting PHP-FPM...${NC}"
                            systemctl restart php8.3-fpm 2>/dev/null || service php8.3-fpm restart 2>/dev/null || true
                            echo ""
                            echo -e "  ${GREEN}Blueprint Update Completed!${NC}"
                        fi
                    fi
                    php artisan up 2>/dev/null
                fi
                pause
                ;;
            4)
                clear
                echo -e "${YELLOW}Blueprint Status Check${NC}"
                echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ -f "$BDIR/blueprint.sh" ] && [ -d "$BDIR/blueprint" ]; then
                    echo -e "  ${GREEN}[INSTALLED]${NC} Blueprint framework"
                    echo -e "  ${GRAY}Script:${NC} $BDIR/blueprint.sh"
                    if [ -f "$BDIR/.blueprintrc" ]; then
                        echo -e "  ${GREEN}[OK]${NC} Configured (.blueprintrc found)"
                    else
                        echo -e "  ${YELLOW}[WARN]${NC} Not configured, run Install again"
                    fi
                    VER=$(grep -oP 'VERSION="\K[^"]+' "$BDIR/blueprint.sh" 2>/dev/null || echo "unknown")
                    echo -e "  ${GRAY}Version:${NC} $VER"
                elif [ -f "$BDIR/blueprint.sh" ]; then
                    echo -e "  ${YELLOW}[INCOMPLETE]${NC} blueprint.sh found but framework not extracted"
                    echo -e "  ${YELLOW}[ACTION]${NC} Run Install to complete setup"
                else
                    echo -e "  ${RED}[NOT INSTALLED]${NC} Blueprint not found"
                fi
                pause
                ;;
             5) blueprint_extensions_menu ;;
             6) blueprint_addons_menu ;;
             7) blueprint_fix ;;
             0) clear; return ;;
            *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

nooktheme_menu() {
    while true; do
        clear
        echo -e "${PURPLE}"
        echo -e "    ___        _ _  _   _           _           _    "
        echo -e "   / _ \ _ __ (_) || | | |__   ___ | |_   __ _ | |_  "
        echo -e "  | | | | '_ \| | || |_| '_ \ / _ \| __| / _\ | | __|"
        echo -e "  | |_| | | | | |__   _| |_) | (_) | |_ | (_| | | |_ "
        echo -e "   \___/|_| |_|_|  |_| |_.__/ \___/ \__| \__,_|_|\__|"
        echo -e "${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${GREEN}[1]${NC} Install"
        echo -e "  ${RED}[2]${NC} Uninstall (restore original panel)"
        echo -e "  ${CYAN}[3]${NC} Update"
        echo -e "  ${YELLOW}[4]${NC} Check Status"
        echo -e "  ${RED}[0]${NC} Back"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo ""
        echo -ne "  ${CYAN}Select Option [0-4]:${NC} "
        read p

        case $p in
            1)
                clear
                echo -e "${YELLOW}Installing NookTheme...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found at $BDIR${NC}"
                else
                    cd "$BDIR" || exit 1
                    echo -e "  ${CYAN}Entering maintenance mode...${NC}"
                    php artisan down 2>/dev/null
                    echo -e "  ${CYAN}Downloading NookTheme...${NC}"
                    curl -L "https://github.com/Nookure/NookTheme/releases/latest/download/panel.tar.gz" -o panel.tar.gz 2>/dev/null
                    if [ ! -f "panel.tar.gz" ] || [ "$(stat -c%s panel.tar.gz 2>/dev/null)" -lt 10000 ]; then
                        echo -e "  ${RED}Download failed!${NC}"
                        php artisan up 2>/dev/null
                    else
                        echo -e "  ${CYAN}Extracting...${NC}"
                        tar -xzf panel.tar.gz
                        rm -f panel.tar.gz
                        echo -e "  ${CYAN}Setting permissions...${NC}"
                        chmod -R 755 storage/ bootstrap/cache
                        echo -e "  ${CYAN}Updating dependencies...${NC}"
                        composer install --no-dev --optimize-autoloader 2>&1 | tail -3
                        echo -e "  ${CYAN}Clearing cache...${NC}"
                        php artisan view:clear 2>/dev/null
                        php artisan config:clear 2>/dev/null
                        echo -e "  ${CYAN}Running database migrations...${NC}"
                        php artisan migrate --seed --force 2>&1 | tail -3
                        echo -e "  ${CYAN}Setting ownership...${NC}"
                        chown -R www-data:www-data "$BDIR"
                        echo -e "  ${CYAN}Restarting queue worker...${NC}"
                        php artisan queue:restart 2>/dev/null
                        echo -e "  ${CYAN}Exiting maintenance mode...${NC}"
                        php artisan up 2>/dev/null
                        echo ""
                        echo -e "  ${GREEN}NookTheme Install Completed!${NC}"
                    fi
                fi
                pause
                ;;
            2)
                clear
                echo -e "${YELLOW}Uninstalling NookTheme - Restoring original panel...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found at $BDIR${NC}"
                else
                    cd "$BDIR" || exit 1
                    PVERSION=$(php -r "echo array_key_exists('fork-version', require 'config/app.php') ? (require 'config/app.php')['version'] : 'latest';" 2>/dev/null)
                    echo -e "  ${CYAN}Detected panel version: ${WHITE}$PVERSION${NC}"
                    echo -e "  ${YELLOW}WARNING: This will restore the original Pterodactyl panel, removing NookTheme.${NC}"
                    echo ""
                    echo -ne "  ${YELLOW}Continue? [y/N]:${NC} "
                    read confirm
                    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
                        echo -e "  ${YELLOW}Uninstall cancelled.${NC}"
                    else
                        echo -e "  ${CYAN}Entering maintenance mode...${NC}"
                        php artisan down 2>/dev/null
                        DLURL="https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz"
                        if [ "$PVERSION" != "latest" ]; then
                            DLURL="https://github.com/pterodactyl/panel/releases/download/v${PVERSION}/panel.tar.gz"
                        fi
                        echo -e "  ${CYAN}Downloading original Pterodactyl panel...${NC}"
                        curl -L "$DLURL" -o panel.tar.gz 2>/dev/null
                        if [ ! -f "panel.tar.gz" ] || [ "$(stat -c%s panel.tar.gz 2>/dev/null)" -lt 10000 ]; then
                            echo -e "  ${RED}Download failed! Trying latest release...${NC}"
                            curl -L "https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz" -o panel.tar.gz 2>/dev/null
                        fi
                        if [ -f "panel.tar.gz" ] && [ "$(stat -c%s panel.tar.gz 2>/dev/null)" -ge 10000 ]; then
                            echo -e "  ${CYAN}Extracting...${NC}"
                            tar -xzf panel.tar.gz
                            rm -f panel.tar.gz
                            echo -e "  ${CYAN}Updating dependencies...${NC}"
                            composer install --no-dev --optimize-autoloader 2>&1 | tail -3
                            echo -e "  ${CYAN}Clearing cache...${NC}"
                            php artisan view:clear 2>/dev/null
                            php artisan config:clear 2>/dev/null
                            echo -e "  ${CYAN}Running database migrations...${NC}"
                            php artisan migrate --seed --force 2>&1 | tail -3
                            echo -e "  ${CYAN}Setting ownership...${NC}"
                            chown -R www-data:www-data "$BDIR"
                            echo -e "  ${CYAN}Restarting queue worker...${NC}"
                            php artisan queue:restart 2>/dev/null
                            echo -e "  ${CYAN}Exiting maintenance mode...${NC}"
                            php artisan up 2>/dev/null
                            echo ""
                            echo -e "  ${GREEN}Original Pterodactyl panel restored! NookTheme removed.${NC}"
                        else
                            echo -e "  ${RED}Failed to download original panel. Your panel may be in maintenance mode.${NC}"
                            php artisan up 2>/dev/null
                        fi
                    fi
                fi
                pause
                ;;
            3)
                clear
                echo -e "${YELLOW}Updating NookTheme...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found at $BDIR${NC}"
                else
                    cd "$BDIR" || exit 1
                    echo -e "  ${CYAN}Entering maintenance mode...${NC}"
                    php artisan down 2>/dev/null
                    echo -e "  ${CYAN}Downloading latest NookTheme...${NC}"
                    curl -L "https://github.com/Nookure/NookTheme/releases/latest/download/panel.tar.gz" -o panel.tar.gz 2>/dev/null
                    if [ ! -f "panel.tar.gz" ] || [ "$(stat -c%s panel.tar.gz 2>/dev/null)" -lt 10000 ]; then
                        echo -e "  ${RED}Download failed!${NC}"
                        php artisan up 2>/dev/null
                    else
                        echo -e "  ${CYAN}Extracting...${NC}"
                        tar -xzf panel.tar.gz
                        rm -f panel.tar.gz
                        echo -e "  ${CYAN}Setting permissions...${NC}"
                        chmod -R 755 storage/ bootstrap/cache
                        echo -e "  ${CYAN}Updating dependencies...${NC}"
                        composer install --no-dev --optimize-autoloader 2>&1 | tail -3
                        echo -e "  ${CYAN}Clearing cache...${NC}"
                        php artisan view:clear 2>/dev/null
                        php artisan config:clear 2>/dev/null
                        echo -e "  ${CYAN}Running database migrations...${NC}"
                        php artisan migrate --seed --force 2>&1 | tail -3
                        echo -e "  ${CYAN}Setting ownership...${NC}"
                        chown -R www-data:www-data "$BDIR"
                        echo -e "  ${CYAN}Restarting queue worker...${NC}"
                        php artisan queue:restart 2>/dev/null
                        echo -e "  ${CYAN}Exiting maintenance mode...${NC}"
                        php artisan up 2>/dev/null
                        echo ""
                        echo -e "  ${GREEN}NookTheme Update Completed!${NC}"
                    fi
                fi
                pause
                ;;
            4)
                clear
                echo -e "${YELLOW}NookTheme Status Check${NC}"
                echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ -f "$BDIR/config/app.php" ]; then
                    HAS_FORK=$(php -r "
\$cfg = require '$BDIR/config/app.php';
echo array_key_exists('fork-version', \$cfg) ? 'yes' : 'no';
" 2>/dev/null)
                    if [ "$HAS_FORK" = "yes" ]; then
                        echo -e "  ${GREEN}[INSTALLED]${NC} NookTheme"
                        FVER=$(php -r "\$cfg = require '$BDIR/config/app.php'; echo \$cfg['fork-version'] ?? 'unknown';" 2>/dev/null)
                        PVER=$(php -r "\$cfg = require '$BDIR/config/app.php'; echo \$cfg['version'] ?? 'unknown';" 2>/dev/null)
                        echo -e "  ${GRAY}NookTheme Version:${NC} $FVER"
                        echo -e "  ${GRAY}Panel Version:${NC} $PVER"
                    else
                        echo -e "  ${YELLOW}[NOT INSTALLED]${NC} Original Pterodactyl panel"
                        PVER=$(php -r "\$cfg = require '$BDIR/config/app.php'; echo \$cfg['version'] ?? 'unknown';" 2>/dev/null)
                        echo -e "  ${GRAY}Panel Version:${NC} $PVER"
                    fi
                else
                    echo -e "  ${RED}[ERROR]${NC} Pterodactyl panel not found"
                fi
                pause
                ;;
            0) clear; return ;;
            *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

restore_original_panel() {
    BDIR="/var/www/pterodactyl"
    cd "$BDIR" || return 1
    PVERSION=$(php -r "\$cfg = require 'config/app.php'; echo \$cfg['version'] ?? 'latest';" 2>/dev/null)
    php artisan down 2>/dev/null
    DLURL="https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz"
    if [ -n "$PVERSION" ] && [ "$PVERSION" != "latest" ]; then
        DLURL="https://github.com/pterodactyl/panel/releases/download/v${PVERSION}/panel.tar.gz"
    fi
    echo -e "  ${CYAN}Downloading original Pterodactyl panel...${NC}"
    curl -L "$DLURL" -o panel.tar.gz 2>/dev/null
    if [ ! -f "panel.tar.gz" ] || [ "$(stat -c%s panel.tar.gz 2>/dev/null)" -lt 10000 ]; then
        echo -e "  ${RED}Download failed! Trying latest...${NC}"
        curl -L "https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz" -o panel.tar.gz 2>/dev/null
    fi
    if [ -f "panel.tar.gz" ] && [ "$(stat -c%s panel.tar.gz 2>/dev/null)" -ge 10000 ]; then
        echo -e "  ${CYAN}Extracting...${NC}"
        tar -xzf panel.tar.gz
        rm -f panel.tar.gz
        echo -e "  ${CYAN}Updating dependencies...${NC}"
        composer install --no-dev --optimize-autoloader 2>&1 | tail -3
        echo -e "  ${CYAN}Clearing cache...${NC}"
        php artisan view:clear 2>/dev/null
        php artisan config:clear 2>/dev/null
        echo -e "  ${CYAN}Running database migrations...${NC}"
        php artisan migrate --seed --force 2>&1 | tail -3
        echo -e "  ${CYAN}Setting ownership...${NC}"
        chown -R www-data:www-data "$BDIR"
        php artisan queue:restart 2>/dev/null
        php artisan up 2>/dev/null
        echo -e "  ${GREEN}[OK]${NC} Original panel restored"
        return 0
    fi
    php artisan up 2>/dev/null
    echo -e "  ${RED}[FAIL]${NC} Could not download original panel"
    return 1
}

install_css_theme() {
    local REPO="$1" CSSNAME="$2" THEMENAME="$3"
    shift 3
    local EXTRA=("$@")
    BDIR="/var/www/pterodactyl"
    cd "$BDIR" || return 1
    echo -e "  ${CYAN}Downloading ${THEMENAME}...${NC}"
    rm -rf "$CSSNAME"
    git clone --depth=1 "$REPO" "$CSSNAME" 2>/dev/null
    if [ ! -d "$CSSNAME" ]; then
        echo -e "  ${RED}Download failed!${NC}"
        return 1
    fi
    echo -e "  ${CYAN}Applying theme files...${NC}"
    cp "$CSSNAME/index.tsx" resources/scripts/index.tsx 2>/dev/null
    cp "$CSSNAME"/*.css resources/scripts/ 2>/dev/null
    for f in "${EXTRA[@]}"; do
        local SRC="${f%%:*}" DST="${f#*:}"
        if [ -f "$CSSNAME/$SRC" ]; then
            cp "$CSSNAME/$SRC" "$DST" 2>/dev/null
        fi
    done
    echo -e "  ${CYAN}Building assets...${NC}"
    npm i -g yarn 2>/dev/null
    yarn 2>&1 | tail -3
    export NODE_OPTIONS=--openssl-legacy-provider
    yarn build:production 2>&1 | tail -5
    php artisan optimize:clear 2>/dev/null
    rm -rf "$CSSNAME"
    echo -e "  ${GREEN}${THEMENAME} installed!${NC}"
}

css_theme_menu() {
    local REPO="$1" CSSNAME="$2" THEMENAME="$3"
    shift 3
    local EXTRA_FILES=("$@")
    while true; do
        clear
        echo -e "${PURPLE}"
        echo -e "  ${CYAN}${THEMENAME}${NC}"
        echo -e "${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${GREEN}[1]${NC} Install"
        echo -e "  ${RED}[2]${NC} Uninstall (restore original panel)"
        echo -e "  ${CYAN}[3]${NC} Update"
        echo -e "  ${YELLOW}[4]${NC} Check Status"
        echo -e "  ${RED}[0]${NC} Back"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo ""
        echo -ne "  ${CYAN}Select Option [0-4]:${NC} "
        read p
        case $p in
            1)
                clear
                echo -e "${YELLOW}Installing ${THEMENAME}...${NC}"
                echo ""
                if [ ! -d "/var/www/pterodactyl" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    cd /var/www/pterodactyl || return
                    install_css_theme "$REPO" "$CSSNAME" "$THEMENAME" "${EXTRA_FILES[@]}"
                fi
                pause
                ;;
            2)
                clear
                echo -e "${YELLOW}Uninstalling ${THEMENAME} - Restoring original panel...${NC}"
                echo ""
                if [ ! -d "/var/www/pterodactyl" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    echo -e "  ${YELLOW}WARNING: This will remove the theme and restore original panel.${NC}"
                    echo ""
                    echo -ne "  ${YELLOW}Continue? [y/N]:${NC} "
                    read confirm
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        restore_original_panel
                        if [ $? -eq 0 ]; then
                            echo -e "  ${GREEN}Original panel restored! ${THEMENAME} removed.${NC}"
                        else
                            echo -e "  ${RED}Failed to restore panel. Check internet connection.${NC}"
                        fi
                    else
                        echo -e "  ${YELLOW}Uninstall cancelled.${NC}"
                    fi
                fi
                pause
                ;;
            3)
                clear
                echo -e "${YELLOW}Updating ${THEMENAME}...${NC}"
                echo ""
                if [ ! -d "/var/www/pterodactyl" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    cd /var/www/pterodactyl || return
                    php artisan down 2>/dev/null
                    install_css_theme "$REPO" "$CSSNAME" "$THEMENAME" "${EXTRA_FILES[@]}"
                    php artisan up 2>/dev/null
                fi
                pause
                ;;
            4)
                clear
                echo -e "${YELLOW}${THEMENAME} Status${NC}"
                echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
                echo ""
                if [ -f "/var/www/pterodactyl/resources/scripts/${CSSNAME}.css" ]; then
                    echo -e "  ${GREEN}[INSTALLED]${NC} ${THEMENAME}"
                else
                    echo -e "  ${YELLOW}[NOT INSTALLED]${NC} ${THEMENAME}"
                fi
                pause
                ;;
            0) clear; return ;;
            *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

iceMinecraft_menu() {
    css_theme_menu \
        "https://github.com/Angelillo15/IceMinecraftTheme.git" \
        "IceMinecraftTheme" \
        "IceMinecraftTheme" \
        "IceMinecraftTheme.css:resources/scripts/IceMinecraftTheme.css" \
        "resources/scripts/components/server/console/Console.tsx:resources/scripts/components/server/console/Console.tsx"
}

minecraftPurple_menu() {
    css_theme_menu \
        "https://github.com/Angelillo15/MinecraftPurpleTheme.git" \
        "MinecraftPurpleTheme" \
        "Minecraft Purple Theme" \
        "MinecraftPurpleTheme.css:resources/scripts/MinecraftPurpleTheme.css"
}

nightDy_menu() {
    css_theme_menu \
        "https://github.com/mufniDev/nightDy.git" \
        "nightDy" \
        "NightDy" \
        "mufniDev.css:resources/scripts/mufniDev.css"
}

regged_menu() {
    while true; do
        clear
        echo -e "${PURPLE}"
        echo -e "   ____          _     _   ____          _   _                 _   "
        echo -e "  |  _ \ ___  __| | __| | |  _ \ ___  __| |_| |__   ___  _ __ | |_ "
        echo -e "  | |_) / _ \/ _\ |/ _\ | | |_) / _ \/ _\ | __| '_ \ / _ \| '_ \| __|"
        echo -e "  |  _ <  __/ (_| | (_| | |  __/  __/ (_| | |_| | | | (_) | | | | |_ "
        echo -e "  |_| \_\___|\__,_|\__,_| |_|   \___|\__,_|\__|_| |_|\___/|_| |_|\__|"
        echo -e "${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${GREEN}[1]${NC} Install"
        echo -e "  ${RED}[2]${NC} Uninstall (restore original panel)"
        echo -e "  ${CYAN}[3]${NC} Update"
        echo -e "  ${YELLOW}[4]${NC} Check Status"
        echo -e "  ${RED}[0]${NC} Back"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo ""
        echo -ne "  ${CYAN}Select Option [0-4]:${NC} "
        read p
        case $p in
            1)
                clear
                echo -e "${YELLOW}Installing Regged Theme...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    cd "$BDIR" || exit
                    echo -e "  ${CYAN}Downloading Regged Theme...${NC}"
                    rm -rf regged-tmp
                    git clone --depth=1 "https://github.com/Mubeen142/regged-pterodactyl.git" regged-tmp 2>/dev/null
                    if [ ! -d "regged-tmp" ]; then
                        echo -e "  ${RED}Download failed!${NC}"
                    else
                        echo -e "  ${CYAN}Applying theme files...${NC}"
                        mkdir -p config/themes public/themes/regged/css resources/views/templates 2>/dev/null
                        cp -r regged-tmp/pterodactyl/config/themes/* config/themes/ 2>/dev/null
                        cp -r regged-tmp/pterodactyl/public/themes/regged/* public/themes/regged/ 2>/dev/null
                        cp -r regged-tmp/pterodactyl/resources/views/templates/* resources/views/templates/ 2>/dev/null
                        cp regged-tmp/pterodactyl/tailwind.config.js tailwind.config.js 2>/dev/null
                        echo -e "  ${CYAN}Building assets...${NC}"
                        npm i -g yarn 2>/dev/null
                        yarn 2>&1 | tail -3
                        yarn build:production 2>&1 | tail -5
                        php artisan optimize:clear 2>/dev/null
                        rm -rf regged-tmp
                        echo ""
                        echo -e "  ${GREEN}Regged Theme Installed!${NC}"
                    fi
                fi
                pause
                ;;
            2)
                clear
                echo -e "${YELLOW}Uninstalling Regged Theme - Restoring original panel...${NC}"
                echo ""
                if [ ! -d "/var/www/pterodactyl" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    echo -e "  ${YELLOW}WARNING: This will remove the theme and restore original panel.${NC}"
                    echo ""
                    echo -ne "  ${YELLOW}Continue? [y/N]:${NC} "
                    read confirm
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        restore_original_panel
                        if [ $? -eq 0 ]; then
                            echo -e "  ${GREEN}Original panel restored! Regged theme removed.${NC}"
                        else
                            echo -e "  ${RED}Failed to restore panel. Check internet connection.${NC}"
                        fi
                    else
                        echo -e "  ${YELLOW}Uninstall cancelled.${NC}"
                    fi
                fi
                pause
                ;;
            3)
                clear
                echo -e "${YELLOW}Updating Regged Theme...${NC}"
                echo ""
                if [ ! -d "/var/www/pterodactyl" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    cd /var/www/pterodactyl || exit
                    php artisan down 2>/dev/null
                    echo -e "  ${CYAN}Downloading Regged Theme...${NC}"
                    rm -rf regged-tmp
                    git clone --depth=1 "https://github.com/Mubeen142/regged-pterodactyl.git" regged-tmp 2>/dev/null
                    if [ -d "regged-tmp" ]; then
                        mkdir -p config/themes public/themes/regged/css resources/views/templates 2>/dev/null
                        cp -r regged-tmp/pterodactyl/config/themes/* config/themes/ 2>/dev/null
                        cp -r regged-tmp/pterodactyl/public/themes/regged/* public/themes/regged/ 2>/dev/null
                        cp -r regged-tmp/pterodactyl/resources/views/templates/* resources/views/templates/ 2>/dev/null
                        cp regged-tmp/pterodactyl/tailwind.config.js tailwind.config.js 2>/dev/null
                        yarn 2>&1 | tail -3
                        yarn build:production 2>&1 | tail -5
                        php artisan optimize:clear 2>/dev/null
                        rm -rf regged-tmp
                        echo -e "  ${GREEN}Regged Theme updated!${NC}"
                    fi
                    php artisan up 2>/dev/null
                fi
                pause
                ;;
            4)
                clear
                echo -e "${YELLOW}Regged Theme Status${NC}"
                echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
                echo ""
                if [ -f "/var/www/pterodactyl/config/themes/regged.php" ]; then
                    echo -e "  ${GREEN}[INSTALLED]${NC} Regged Theme"
                else
                    echo -e "  ${YELLOW}[NOT INSTALLED]${NC} Regged Theme"
                fi
                pause
                ;;
             0) clear; return ;;
            *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

noobee_menu() {
    while true; do
        clear
        echo -e "${PURPLE}"
        echo -e "    _   _             ____            _           _    "
        echo -e "   | \ | | ___   ___ | __ )  ___  ___| |__   __ _| |_ "
        echo -e "   |  \| |/ _ \ / _ \|  _ \ / _ \/ _ \ '_ \ / _\ | __|"
        echo -e "   | |\  | (_) | (_) | |_) |  __/  __/ |_) | (_| | |_ "
        echo -e "   |_| \_|\___/ \___/|____/ \___|\___|_.__/ \__,_|\__|"
        echo -e "${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${GREEN}[1]${NC} Install"
        echo -e "  ${RED}[2]${NC} Uninstall (restore original panel)"
        echo -e "  ${CYAN}[3]${NC} Update"
        echo -e "  ${YELLOW}[4]${NC} Check Status"
        echo -e "  ${RED}[0]${NC} Back"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo ""
        echo -ne "  ${CYAN}Select Option [0-4]:${NC} "
        read p
        case $p in
            1)
                clear
                echo -e "${YELLOW}Installing Noobee Theme...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    cd "$BDIR" || exit
                    echo -e "  ${CYAN}Downloading Noobee Theme...${NC}"
                    wget -nv -O Noobee_v1.zip "https://api.akila.network/assets/Noobee_v1.zip" 2>/dev/null
                    if [ ! -f "Noobee_v1.zip" ] || [ "$(stat -c%s Noobee_v1.zip 2>/dev/null)" -lt 1000 ]; then
                        echo -e "  ${RED}Download failed! Check internet connection.${NC}"
                    else
                        echo -e "  ${CYAN}Extracting...${NC}"
                        apt install -y unzip 2>/dev/null
                        unzip -o Noobee_v1.zip -d /tmp/noobee_tmp 2>/dev/null
                        rm -f Noobee_v1.zip
                        if [ -d "/tmp/noobee_tmp/pterodactyl" ]; then
                            cp -r -f /tmp/noobee_tmp/pterodactyl/. "$BDIR/"
                            rm -rf /tmp/noobee_tmp
                            echo -e "  ${CYAN}Building assets...${NC}"
                            npm i -g yarn 2>/dev/null
                            yarn 2>&1 | tail -3
                            yarn build:production 2>&1 | tail -5
                            php artisan view:clear 2>/dev/null
                            touch "$BDIR/.noobee"
                            echo ""
                            echo -e "  ${GREEN}Noobee Theme Installed!${NC}"
                        else
                            echo -e "  ${RED}Extraction failed - unexpected archive structure${NC}"
                            rm -rf /tmp/noobee_tmp
                        fi
                    fi
                fi
                pause
                ;;
            2)
                clear
                echo -e "${YELLOW}Uninstalling Noobee Theme - Restoring original panel...${NC}"
                echo ""
                if [ ! -d "/var/www/pterodactyl" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    echo -e "  ${YELLOW}WARNING: This will remove the theme and restore original panel.${NC}"
                    echo ""
                    echo -ne "  ${YELLOW}Continue? [y/N]:${NC} "
                    read confirm
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        restore_original_panel
                        if [ $? -eq 0 ]; then
                            rm -f /var/www/pterodactyl/.noobee
                            echo -e "  ${GREEN}Original panel restored! Noobee removed.${NC}"
                        else
                            echo -e "  ${RED}Failed to restore panel. Check internet connection.${NC}"
                        fi
                    else
                        echo -e "  ${YELLOW}Uninstall cancelled.${NC}"
                    fi
                fi
                pause
                ;;
            3)
                clear
                echo -e "${YELLOW}Updating Noobee Theme...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    cd "$BDIR" || exit
                    php artisan down 2>/dev/null
                    wget -nv -O Noobee_v1.zip "https://api.akila.network/assets/Noobee_v1.zip" 2>/dev/null
                    if [ ! -f "Noobee_v1.zip" ] || [ "$(stat -c%s Noobee_v1.zip 2>/dev/null)" -lt 1000 ]; then
                        echo -e "  ${RED}Download failed!${NC}"
                        php artisan up 2>/dev/null
                    else
                        unzip -o Noobee_v1.zip -d /tmp/noobee_tmp 2>/dev/null
                        rm -f Noobee_v1.zip
                        if [ -d "/tmp/noobee_tmp/pterodactyl" ]; then
                            cp -r -f /tmp/noobee_tmp/pterodactyl/. "$BDIR/"
                            rm -rf /tmp/noobee_tmp
                            yarn 2>&1 | tail -3
                            yarn build:production 2>&1 | tail -5
                            php artisan view:clear 2>/dev/null
                            echo -e "  ${GREEN}Noobee Theme updated!${NC}"
                        else
                            echo -e "  ${RED}Extraction failed${NC}"
                            rm -rf /tmp/noobee_tmp
                        fi
                        php artisan up 2>/dev/null
                    fi
                fi
                pause
                ;;
            4)
                clear
                echo -e "${YELLOW}Noobee Theme Status${NC}"
                echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
                echo ""
                if [ -f "/var/www/pterodactyl/.noobee" ]; then
                    echo -e "  ${GREEN}[INSTALLED]${NC} Noobee Theme"
                else
                    echo -e "  ${YELLOW}[NOT INSTALLED]${NC} Noobee Theme"
                fi
                pause
                ;;
            0) clear; return ;;
            *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

nightadmin_menu() {
    while true; do
        clear
        echo -e "${PURPLE}"
        echo -e "    _   _ _        _           _           _           _    "
        echo -e "   | \ | (_)__ _  / \   __ _  | |__   __ _| |_  ___  __ _ "
        echo -e "   |  \| | / _\ |/ _ \ / _\ | | '_ \ / _\ | __|/ _ \/ _\ |"
        echo -e "   | |\  | | (_| / ___ \ (_| | | |_) | (_| | |_|  __/ (_| |"
        echo -e "   |_| \_|_|\__, \/_/   \_\__,_| |_.__/ \__,_|\__|\___|\__,_|"
        echo -e "            |_/                                              "
        echo -e "${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${GREEN}[1]${NC} Install"
        echo -e "  ${RED}[2]${NC} Uninstall (restore original panel)"
        echo -e "  ${CYAN}[3]${NC} Update"
        echo -e "  ${YELLOW}[4]${NC} Check Status"
        echo -e "  ${RED}[0]${NC} Back"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo ""
        echo -ne "  ${CYAN}Select Option [0-4]:${NC} "
        read p
        case $p in
            1)
                clear
                echo -e "${YELLOW}Installing Night Admin Theme...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found at $BDIR${NC}"
                elif [ ! -f "$BDIR/blueprint.sh" ]; then
                    echo -e "  ${YELLOW}Blueprint is not installed. Please install Blueprint first.${NC}"
                else
                    cd "$BDIR" || exit
                    php artisan down 2>/dev/null
                    echo -e "  ${CYAN}Installing Night Admin from Blueprint marketplace...${NC}"
                    if blueprint -install nightadmin 2>&1; then
                        php artisan up 2>/dev/null
                        echo ""
                        echo -e "  ${GREEN}Night Admin Theme installed!${NC}"
                    else
                        php artisan up 2>/dev/null
                        echo -e "  ${RED}Installation failed. Check Blueprint marketplace connectivity.${NC}"
                    fi
                fi
                pause
                ;;
            2)
                clear
                echo -e "${YELLOW}Uninstalling Night Admin Theme...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                elif [ ! -f "$BDIR/blueprint.sh" ]; then
                    echo -e "  ${YELLOW}Blueprint is not installed. Nothing to uninstall.${NC}"
                else
                    echo -e "  ${YELLOW}WARNING: This will remove the Night Admin extension.${NC}"
                    echo ""
                    echo -ne "  ${YELLOW}Continue? [y/N]:${NC} "
                    read confirm
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        cd "$BDIR" || exit
                        if blueprint -remove nightadmin 2>&1; then
                            echo -e "  ${GREEN}Night Admin Theme removed!${NC}"
                        else
                            echo -e "  ${YELLOW}Trying to restore original panel instead...${NC}"
                            restore_original_panel
                            if [ $? -eq 0 ]; then
                                echo -e "  ${GREEN}Original panel restored!${NC}"
                            else
                                echo -e "  ${RED}Failed. Check internet connection.${NC}"
                            fi
                        fi
                    else
                        echo -e "  ${YELLOW}Uninstall cancelled.${NC}"
                    fi
                fi
                pause
                ;;
            3)
                clear
                echo -e "${YELLOW}Updating Night Admin Theme...${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                elif [ ! -f "$BDIR/blueprint.sh" ]; then
                    echo -e "  ${YELLOW}Blueprint is not installed.${NC}"
                else
                    cd "$BDIR" || exit
                    php artisan down 2>/dev/null
                    echo -e "  ${CYAN}Upgrading Night Admin from Blueprint marketplace...${NC}"
                    if blueprint -upgrade nightadmin 2>&1; then
                        php artisan up 2>/dev/null
                        echo ""
                        echo -e "  ${GREEN}Night Admin Theme updated!${NC}"
                    else
                        php artisan up 2>/dev/null
                        echo -e "  ${RED}Update failed.${NC}"
                    fi
                fi
                pause
                ;;
            4)
                clear
                echo -e "${YELLOW}Night Admin Theme Status${NC}"
                echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
                echo ""
                BDIR="/var/www/pterodactyl"
                if [ -d "$BDIR/blueprint/extensions/nightadmin" ]; then
                    echo -e "  ${GREEN}[INSTALLED]${NC} Night Admin Theme"
                elif [ -d "$BDIR/.blueprint/extensions/nightadmin" ]; then
                    echo -e "  ${GREEN}[INSTALLED]${NC} Night Admin Theme"
                else
                    echo -e "  ${YELLOW}[NOT INSTALLED]${NC} Night Admin Theme"
                fi
                pause
                ;;
             0) clear; return ;;
             *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

blueprint_ext_menu() {
    local EXT_SLUG="$1"
    local EXT_NAME="$2"
    local BDIR="/var/www/pterodactyl"
    if [ ! -f "$BDIR/blueprint.sh" ]; then
        clear
        echo -e "${YELLOW}${EXT_NAME}${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${YELLOW}Blueprint is not installed.${NC}"
        echo -e "  ${YELLOW}Please install Blueprint first from the main menu.${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        pause
        return
    fi
    while true; do
        clear
        echo -e "${PURPLE}"
        echo -e "   ${EXT_NAME}"
        echo -e "${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${GREEN}[1]${NC} Install"
        echo -e "  ${RED}[2]${NC} Uninstall"
        echo -e "  ${CYAN}[3]${NC} Update"
        echo -e "  ${YELLOW}[4]${NC} Check Status"
        echo -e "  ${RED}[0]${NC} Back"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo ""
        echo -ne "  ${CYAN}Select Option [0-4]:${NC} "
        read p
        case $p in
            1)
                clear
                echo -e "${YELLOW}Installing ${EXT_NAME}...${NC}"
                echo ""
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found at $BDIR${NC}"
                else
                    cd "$BDIR" || exit
                    php artisan up 2>/dev/null
                    php artisan down 2>/dev/null
                    echo -e "  ${CYAN}Installing from Blueprint marketplace...${NC}"
                    rm -f .blueprint/lock 2>/dev/null
                    if timeout 30 blueprint -install "$EXT_SLUG" 2>&1; then
                        echo ""
                        echo -e "  ${GREEN}${EXT_NAME} installed!${NC}"
                    else
                        echo -e "  ${RED}Installation failed. Check Blueprint marketplace connectivity.${NC}"
                    fi
                    php artisan up 2>/dev/null
                    rm -f .blueprint/lock 2>/dev/null
                fi
                pause
                ;;
            2)
                clear
                echo -e "${YELLOW}Uninstalling ${EXT_NAME}...${NC}"
                echo ""
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    echo -ne "  ${YELLOW}Continue? [y/N]:${NC} "
                    read confirm
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        cd "$BDIR" || exit
                        rm -f .blueprint/lock 2>/dev/null
                        if timeout 30 blueprint -remove "$EXT_SLUG" 2>&1; then
                            echo -e "  ${GREEN}${EXT_NAME} removed!${NC}"
                        else
                            echo -e "  ${RED}Uninstall failed.${NC}"
                        fi
                    else
                        echo -e "  ${YELLOW}Uninstall cancelled.${NC}"
                    fi
                fi
                pause
                ;;
            3)
                clear
                echo -e "${YELLOW}Updating ${EXT_NAME}...${NC}"
                echo ""
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    cd "$BDIR" || exit
                    php artisan up 2>/dev/null
                    php artisan down 2>/dev/null
                    rm -f .blueprint/lock 2>/dev/null
                    if timeout 30 blueprint -upgrade "$EXT_SLUG" 2>&1; then
                        echo -e "  ${GREEN}${EXT_NAME} updated!${NC}"
                    else
                        echo -e "  ${RED}Update failed.${NC}"
                    fi
                    php artisan up 2>/dev/null
                    rm -f .blueprint/lock 2>/dev/null
                fi
                pause
                ;;
            4)
                clear
                echo -e "${YELLOW}${EXT_NAME} Status${NC}"
                echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
                echo ""
                if [ -d "$BDIR/blueprint/extensions/$EXT_SLUG" ] || [ -d "$BDIR/.blueprint/extensions/$EXT_SLUG" ]; then
                    echo -e "  ${GREEN}[INSTALLED]${NC} ${EXT_NAME}"
                else
                    echo -e "  ${YELLOW}[NOT INSTALLED]${NC} ${EXT_NAME}"
                fi
                pause
                ;;
             0) clear; return ;;
             *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

blueprint_extensions_menu() {
    while true; do
        clear
        echo -e "${PURPLE}"
        echo -e "    ____  _            _                _   "
        echo -e "   | __ )| |_   _  ___| |_   _ ___  ___| |_ "
        echo -e "   |  _ \| | | | |/ _ \ | | | / __|/ _ \ __|"
        echo -e "   | |_) | | |_| |  __/ | |_| \__ \  __/ |_ "
        echo -e "   |____/|_|\__,_|\___|_|\__,_|___/\___|\__|"
        echo -e "                                            "
        echo -e "   Extensions                               "
        echo -e "${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${CYAN}[1]${NC} Nebula                ${CYAN}[11]${NC} Slate"
        echo -e "  ${CYAN}[2]${NC} EuphoriaTheme         ${CYAN}[12]${NC} M3Dactyl"
        echo -e "  ${CYAN}[3]${NC} RefreshTheme          ${CYAN}[13]${NC} AbyssPurple"
        echo -e "  ${CYAN}[4]${NC} Night Admin           ${CYAN}[14]${NC} AmberAbyss"
        echo -e "  ${CYAN}[5]${NC} Darkenate             ${CYAN}[15]${NC} Catppuccindactyl"
        echo -e "  ${CYAN}[6]${NC} Recolor               ${CYAN}[16]${NC} CrimsonAbyss"
        echo -e "  ${CYAN}[7]${NC} BlueTables            ${CYAN}[17]${NC} EmeraldAbyss"
        echo -e "  ${CYAN}[8]${NC} BetterAdmin           ${CYAN}[18]${NC} Slice"
        echo -e "  ${CYAN}[9]${NC} UltraDarkAdmin        ${CYAN}[19]${NC} XLpanelTheme"
        echo -e "  ${CYAN}[10]${NC} LememTheme           ${CYAN}[20]${NC} KaelixPrime"
        echo -e "  ${RED}[0]${NC} Back"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo ""
        echo -ne "  ${CYAN}Select Extension [0-20]:${NC} "
        read p
        case $p in
            1) blueprint_ext_menu "nebula" "Nebula" ;;
            2) blueprint_ext_menu "euphoriatheme" "EuphoriaTheme" ;;
            3) blueprint_ext_menu "refreshtheme" "RefreshTheme" ;;
            4) blueprint_ext_menu "nightadmin" "Night Admin" ;;
            5) blueprint_ext_menu "darkenate" "Darkenate" ;;
            6) blueprint_ext_menu "recolor" "Recolor" ;;
            7) blueprint_ext_menu "bluetables" "BlueTables" ;;
            8) blueprint_ext_menu "BetterAdmin" "BetterAdmin" ;;
            9) blueprint_ext_menu "ultradarkadmin" "UltraDarkAdmin" ;;
            10) blueprint_ext_menu "lememtheme" "LememTheme" ;;
            11) blueprint_ext_menu "slate" "Slate" ;;
            12) blueprint_ext_menu "mthreedactyl" "M3Dactyl" ;;
            13) blueprint_ext_menu "abysspurple" "AbyssPurple" ;;
            14) blueprint_ext_menu "amberabyss" "AmberAbyss" ;;
            15) blueprint_ext_menu "catppuccindactyl" "Catppuccindactyl" ;;
            16) blueprint_ext_menu "crimsonabyss" "CrimsonAbyss" ;;
            17) blueprint_ext_menu "emeraldabyss" "EmeraldAbyss" ;;
            18) blueprint_ext_menu "slice" "Slice" ;;
            19) blueprint_ext_menu "xlpaneltheme" "XLpanelTheme" ;;
            20) blueprint_ext_menu "kaelixprime" "KaelixPrime" ;;
            0) clear; return ;;
            *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

blueprint_addon_action() {
    local ADDON_SLUG="$1"
    local ADDON_NAME="$2"
    local BDIR="/var/www/pterodactyl"
    local _b="aHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL3JveWFsZGV2bG9wbWVudHMvUm95YWwtRGV2bG9wbWVudHMvbWFpbi90aGFtZS9FeHRlbnNpb24v"
    if [ ! -f "$BDIR/blueprint.sh" ]; then
        clear
        echo -e "${YELLOW}${ADDON_NAME}${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${YELLOW}Blueprint is not installed.${NC}"
        echo -e "  ${YELLOW}Please install Blueprint first from the main menu.${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        pause
        return
    fi
    while true; do
        clear
        echo -e "${PURPLE}"
        echo -e "   ${ADDON_NAME}"
        echo -e "${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${GREEN}[1]${NC} Install"
        echo -e "  ${RED}[2]${NC} Uninstall"
        echo -e "  ${CYAN}[3]${NC} Update"
        echo -e "  ${YELLOW}[4]${NC} Check Status"
        echo -e "  ${RED}[0]${NC} Back"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo ""
        echo -ne "  ${CYAN}Select Option [0-4]:${NC} "
        read p
        case $p in
            1)
                clear
                echo -e "${YELLOW}Installing ${ADDON_NAME}...${NC}"
                echo ""
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found at $BDIR${NC}"
                else
                    set +o history 2>/dev/null
                    local _bu; _bu=$(echo -n "$_b" | base64 -d 2>/dev/null)
                    cd "$BDIR" || exit
                    php artisan up 2>/dev/null
                    php artisan down 2>/dev/null
                    echo -e "  ${CYAN}Downloading ${ADDON_NAME}...${NC}"
                    wget -q "$_bu$ADDON_SLUG.blueprint" -O "${ADDON_SLUG}.blueprint" 2>/dev/null
                    _bu=""
                    if [ -f "${ADDON_SLUG}.blueprint" ] && [ "$(stat -c%s "${ADDON_SLUG}.blueprint" 2>/dev/null)" -gt 100 ]; then
                        echo -e "  ${CYAN}Installing...${NC}"
                        rm -f .blueprint/lock 2>/dev/null
                        if timeout 30 blueprint -install "${ADDON_SLUG}.blueprint" 2>&1; then
                            echo ""
                            echo -e "  ${GREEN}${ADDON_NAME} installed!${NC}"
                        else
                            echo -e "  ${RED}Installation failed.${NC}"
                        fi
                    else
                        echo -e "  ${RED}Download failed. Check connectivity.${NC}"
                    fi
                    php artisan up 2>/dev/null
                    rm -f "${ADDON_SLUG}.blueprint" .blueprint/lock 2>/dev/null
                    history -c 2>/dev/null
                    set -o history 2>/dev/null
                fi
                pause
                ;;
            2)
                clear
                echo -e "${YELLOW}Uninstalling ${ADDON_NAME}...${NC}"
                echo ""
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    echo -ne "  ${YELLOW}Continue? [y/N]:${NC} "
                    read confirm
                    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                        cd "$BDIR" || exit
                        rm -f .blueprint/lock 2>/dev/null
                        if timeout 30 blueprint -remove "$ADDON_SLUG" 2>&1; then
                            echo -e "  ${GREEN}${ADDON_NAME} removed!${NC}"
                        else
                            echo -e "  ${RED}Uninstall failed.${NC}"
                        fi
                    else
                        echo -e "  ${YELLOW}Uninstall cancelled.${NC}"
                    fi
                fi
                pause
                ;;
            3)
                clear
                echo -e "${YELLOW}Updating ${ADDON_NAME}...${NC}"
                echo ""
                if [ ! -d "$BDIR" ]; then
                    echo -e "  ${RED}Pterodactyl panel not found${NC}"
                else
                    set +o history 2>/dev/null
                    local _bu; _bu=$(echo -n "$_b" | base64 -d 2>/dev/null)
                    cd "$BDIR" || exit
                    php artisan up 2>/dev/null
                    php artisan down 2>/dev/null
                    echo -e "  ${CYAN}Downloading update...${NC}"
                    wget -q "$_bu$ADDON_SLUG.blueprint" -O "${ADDON_SLUG}.blueprint" 2>/dev/null
                    _bu=""
                    if [ -f "${ADDON_SLUG}.blueprint" ] && [ "$(stat -c%s "${ADDON_SLUG}.blueprint" 2>/dev/null)" -gt 100 ]; then
                        rm -f .blueprint/lock 2>/dev/null
                        if timeout 30 blueprint -upgrade "${ADDON_SLUG}.blueprint" 2>&1; then
                            echo -e "  ${GREEN}${ADDON_NAME} updated!${NC}"
                        else
                            echo -e "  ${RED}Update failed.${NC}"
                        fi
                    else
                        echo -e "  ${RED}Download failed.${NC}"
                    fi
                    php artisan up 2>/dev/null
                    rm -f "${ADDON_SLUG}.blueprint" .blueprint/lock 2>/dev/null
                    history -c 2>/dev/null
                    set -o history 2>/dev/null
                fi
                pause
                ;;
            4)
                clear
                echo -e "${YELLOW}${ADDON_NAME} Status${NC}"
                echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
                echo ""
                if [ -d "$BDIR/blueprint/extensions/$ADDON_SLUG" ] || [ -d "$BDIR/.blueprint/extensions/$ADDON_SLUG" ]; then
                    echo -e "  ${GREEN}[INSTALLED]${NC} ${ADDON_NAME}"
                else
                    echo -e "  ${YELLOW}[NOT INSTALLED]${NC} ${ADDON_NAME}"
                fi
                pause
                ;;
             0) clear; return ;;
             *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

blueprint_addons_menu() {
    while true; do
        clear
        echo -e "${PURPLE}"
        echo -e "    ____  _            _                _   "
        echo -e "   | __ )| |_   _  ___| |_   _ ___  ___| |_ "
        echo -e "   |  _ \| | | | |/ _ \ | | | / __|/ _ \ __|"
        echo -e "   | |_) | | |_| |  __/ | |_| \__ \  __/ |_ "
        echo -e "   |____/|_|\__,_|\___|_|\__,_|___/\___|\__|"
        echo -e "                                            "
        echo -e "   Addons                                  "
        echo -e "${NC}"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo -e "  ${CYAN}[1]${NC} Activity Purges        ${CYAN}[34]${NC} Pterodactyl RAM Burst"
        echo -e "  ${CYAN}[2]${NC} Admin Audit Logs       ${CYAN}[35]${NC} Ptero Monaco"
        echo -e "  ${CYAN}[3]${NC} Auto Backups           ${CYAN}[36]${NC} Pull Files"
        echo -e "  ${CYAN}[4]${NC} Blue Announcements     ${CYAN}[37]${NC} Redirect"
        echo -e "  ${CYAN}[5]${NC} Config Editor          ${CYAN}[38]${NC} Resource Alerts"
        echo -e "  ${CYAN}[6]${NC} Console Logs           ${CYAN}[39]${NC} Resource Manager"
        echo -e "  ${CYAN}[7]${NC} Custom CSS             ${CYAN}[40]${NC} Saga Auto Suspension"
        echo -e "  ${CYAN}[8]${NC} Custom Server Sort     ${CYAN}[41]${NC} Saga Modpack Installer"
        echo -e "  ${CYAN}[9]${NC} Database Import/Export ${CYAN}[42]${NC} Server Backgrounds"
        echo -e "  ${CYAN}[10]${NC} Egg Changer           ${CYAN}[43]${NC} Server Icon Importer"
        echo -e "  ${CYAN}[11]${NC} Hux Register           ${CYAN}[44]${NC} Server ID"
        echo -e "  ${CYAN}[12]${NC} Laravel Logs           ${CYAN}[45]${NC} Server Importer"
        echo -e "  ${CYAN}[13]${NC} Loader                 ${CYAN}[46]${NC} Server Props Manager"
        echo -e "  ${CYAN}[14]${NC} Lyrdy Announce         ${CYAN}[47]${NC} Server Splitter"
        echo -e "  ${CYAN}[15]${NC} MC Logs                ${CYAN}[48]${NC} Show Node IDs"
        echo -e "  ${CYAN}[16]${NC} MCP                    ${CYAN}[49]${NC} Sidebar"
        echo -e "  ${CYAN}[17]${NC} MC Player              ${CYAN}[50]${NC} Simple Favicons"
        echo -e "  ${CYAN}[18]${NC} MC Plugins             ${CYAN}[51]${NC} Simple Footers"
        echo -e "  ${CYAN}[19]${NC} MC Tools               ${CYAN}[52]${NC} Snowflakes"
        echo -e "  ${CYAN}[20]${NC} Minecraft Mod Manager  ${CYAN}[53]${NC} Social Login"
        echo -e "  ${CYAN}[21]${NC} Minecraft Player Mgr   ${CYAN}[54]${NC} Startup Changer"
        echo -e "  ${CYAN}[22]${NC} Minecraft Plugin Mgr   ${CYAN}[55]${NC} Stats"
        echo -e "  ${CYAN}[23]${NC} Modrinth Browser       ${CYAN}[56]${NC} Stellar"
        echo -e "  ${CYAN}[24]${NC} Monaco Editor          ${CYAN}[57]${NC} Subdomain Manager"
        echo -e "  ${CYAN}[25]${NC} MOTD Maker             ${CYAN}[58]${NC} Subdomains"
        echo -e "  ${CYAN}[26]${NC} MySQL Auto Backup      ${CYAN}[59]${NC} Tawk.to"
        echo -e "  ${CYAN}[27]${NC} Node                   ${CYAN}[60]${NC} Translations"
        echo -e "  ${CYAN}[28]${NC} No Pagination          ${CYAN}[61]${NC} Trash Bin"
        echo -e "  ${CYAN}[29]${NC} Panel Address Override ${CYAN}[62]${NC} URL Downloader"
        echo -e "  ${CYAN}[30]${NC} Player Listing         ${CYAN}[63]${NC} Vanilla Tweaks"
        echo -e "  ${CYAN}[31]${NC} PStatistics            ${CYAN}[64]${NC} Version Changer"
        echo -e "  ${CYAN}[32]${NC} Pterodactyl CPU Burst  ${CYAN}[65]${NC} VM Info"
        echo -e "  ${CYAN}[33]${NC} Pterodactyl Panel Ban  ${CYAN}[66]${NC} Votifier Tester"
        echo -e "  ${RED}[0]${NC} Back"
        echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
        echo ""
        echo -ne "  ${CYAN}Select Addon [0-66]:${NC} "
        read p
        case $p in
             1) blueprint_addon_action "activitypurges" "Activity Purges" ;;
             2) blueprint_addon_action "adminauditlogs" "Admin Audit Logs" ;;
             3) blueprint_addon_action "autobackups" "Auto Backups" ;;
             4) blueprint_addon_action "blueannoucements" "Blue Announcements" ;;
             5) blueprint_addon_action "configeditor" "Config Editor" ;;
             6) blueprint_addon_action "consolelogs" "Console Logs" ;;
             7) blueprint_addon_action "customcss" "Custom CSS" ;;
             8) blueprint_addon_action "customserversort" "Custom Server Sort" ;;
             9) blueprint_addon_action "databaseimportexport" "Database Import/Export" ;;
            10) blueprint_addon_action "eggchanger" "Egg Changer" ;;
            11) blueprint_addon_action "huxregister" "Hux Register" ;;
            12) blueprint_addon_action "laravellogs" "Laravel Logs" ;;
            13) blueprint_addon_action "loader" "Loader" ;;
            14) blueprint_addon_action "lyrdyannounce" "Lyrdy Announce" ;;
            15) blueprint_addon_action "mclogs" "MC Logs" ;;
            16) blueprint_addon_action "mcp" "MCP" ;;
            17) blueprint_addon_action "mcplayer" "MC Player" ;;
            18) blueprint_addon_action "mcplugins" "MC Plugins" ;;
            19) blueprint_addon_action "mctools" "MC Tools" ;;
            20) blueprint_addon_action "minecraftmodmanager" "Minecraft Mod Manager" ;;
            21) blueprint_addon_action "minecraftplayermanager" "Minecraft Player Manager" ;;
            22) blueprint_addon_action "minecraftpluginmanager" "Minecraft Plugin Manager" ;;
            23) blueprint_addon_action "modrinthbrowser" "Modrinth Browser" ;;
            24) blueprint_addon_action "monacoeditor" "Monaco Editor" ;;
            25) blueprint_addon_action "motdmaker" "MOTD Maker" ;;
            26) blueprint_addon_action "mysqlautobackup" "MySQL Auto Backup" ;;
            27) blueprint_addon_action "node" "Node" ;;
            28) blueprint_addon_action "nopagination" "No Pagination" ;;
            29) blueprint_addon_action "paneladdressoverride" "Panel Address Override" ;;
            30) blueprint_addon_action "playerlisting" "Player Listing" ;;
            31) blueprint_addon_action "pstatistics" "PStatistics" ;;
            32) blueprint_addon_action "pterodactylcpuburst" "Pterodactyl CPU Burst" ;;
            33) blueprint_addon_action "pterodactylpanelban" "Pterodactyl Panel Ban" ;;
            34) blueprint_addon_action "pterodactylramburst" "Pterodactyl RAM Burst" ;;
            35) blueprint_addon_action "pteromonaco" "Ptero Monaco" ;;
            36) blueprint_addon_action "pullfiles" "Pull Files" ;;
            37) blueprint_addon_action "redirect" "Redirect" ;;
            38) blueprint_addon_action "resourcealerts" "Resource Alerts" ;;
            39) blueprint_addon_action "resourcemanager" "Resource Manager" ;;
            40) blueprint_addon_action "sagaautosuspension" "Saga Auto Suspension" ;;
            41) blueprint_addon_action "sagaminecraftmodpackinstaller" "Saga Modpack Installer" ;;
            42) blueprint_addon_action "serverbackgrounds" "Server Backgrounds" ;;
            43) blueprint_addon_action "servericonimporter" "Server Icon Importer" ;;
            44) blueprint_addon_action "serverid" "Server ID" ;;
            45) blueprint_addon_action "serverimporter" "Server Importer" ;;
            46) blueprint_addon_action "serverpropsmanager" "Server Props Manager" ;;
            47) blueprint_addon_action "serversplitter" "Server Splitter" ;;
            48) blueprint_addon_action "shownodeids" "Show Node IDs" ;;
            49) blueprint_addon_action "sidebar" "Sidebar" ;;
            50) blueprint_addon_action "simplefavicons" "Simple Favicons" ;;
            51) blueprint_addon_action "simplefooters" "Simple Footers" ;;
            52) blueprint_addon_action "snowflakes" "Snowflakes" ;;
            53) blueprint_addon_action "sociallogin" "Social Login" ;;
            54) blueprint_addon_action "startupchanger" "Startup Changer" ;;
            55) blueprint_addon_action "stats" "Stats" ;;
            56) blueprint_addon_action "stellar" "Stellar" ;;
            57) blueprint_addon_action "subdomainmanager" "Subdomain Manager" ;;
            58) blueprint_addon_action "subdomains" "Subdomains" ;;
            59) blueprint_addon_action "tawkto" "Tawk.to" ;;
            60) blueprint_addon_action "translations" "Translations" ;;
            61) blueprint_addon_action "trashbin" "Trash Bin" ;;
            62) blueprint_addon_action "urldownloader" "URL Downloader" ;;
            63) blueprint_addon_action "vanillatweaks" "Vanilla Tweaks" ;;
            64) blueprint_addon_action "versionchanger" "Version Changer" ;;
            65) blueprint_addon_action "vminfo" "VM Info" ;;
            66) blueprint_addon_action "votifiertester" "Votifier Tester" ;;
             0) clear; return ;;
             *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
        esac
    done
}

while true; do
    clear
    echo -e "${PURPLE}"
    echo -e "   ____      _ _           _ _                 _     "
    echo -e "  |  _ \ ___(_) |_ ___  __| (_) ___ _   _  ___| |__  "
    echo -e "  | |_) / _ \ | __/ _ \/ _\ | |/ __| | | |/ __| '_ \ "
    echo -e "  |  __/  __/ | ||  __/ (_| | | (__| |_| | (__| | | |"
    echo -e "  |_|   \___|_|\__\___|\__,_|_|\___|\__, |\___|_| |_|"
    echo -e "                                     |___/            "
    echo -e "${NC}"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo -e "  ${CYAN}[1]${NC} Blueprint"
    echo -e "  ${CYAN}[2]${NC} NookTheme"
    echo -e "  ${CYAN}[3]${NC} IceMinecraftTheme"
    echo -e "  ${CYAN}[4]${NC} Minecraft Purple Theme"
    echo -e "  ${CYAN}[5]${NC} NightDy"
    echo -e "  ${CYAN}[6]${NC} Regged Theme"
    echo -e "  ${CYAN}[7]${NC} Noobee Theme"
    echo -e "  ${CYAN}[8]${NC} Night Admin Theme"
    echo -e "  ${RED}[0]${NC} Back"
    echo -e "  ${GRAY}──────────────────────────────────────────────${NC}"
    echo ""
    echo -ne "  ${CYAN}Select Option [0-8]:${NC} "
    read p

    case $p in
        1) blueprint_menu ;;
        2) nooktheme_menu ;;
        3) iceMinecraft_menu ;;
        4) minecraftPurple_menu ;;
        5) nightDy_menu ;;
        6) regged_menu ;;
        7) noobee_menu ;;
        8) nightadmin_menu ;;
        0) clear; exit ;;
        *) echo -e "  ${RED}Invalid${NC}"; sleep 1 ;;
    esac
done


