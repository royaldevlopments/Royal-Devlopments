#!/bin/bash
# PteroCA Installation Script
# Authors:
# - l3oncoder (https://github.com/l3oncoder)
# - ksroga (https://github.com/ksroga)
# Version: 1.1.9 (Fixed MySQL/MariaDB client detection for Debian 13+ and RHEL package names) [2026-02-09]

set -e

# Defaults
NONINTERACTIVE=false
STAGING=false
GENERATE_SSL=""
INSTALL_PTERODACTYL=false
PTERODACTYL_SUBDOMAIN=""
PTERODACTYL_ADMIN_EMAIL=""
PTERODACTYL_ADMIN_USERNAME=""
PTERODACTYL_ADMIN_PASSWORD=""
TELEMETRY_ENABLED=true
TELEMETRY_SOURCE="pteroca_installer"
INSTALLER_VERSION="1.1.9"

# Service detection variables
MYSQL_INSTALLED=false
NGINX_INSTALLED=false
PHP_INSTALLED=false
COMPOSER_INSTALLED=false
DOCKER_INSTALLED=false

# parse CLI args
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--php-version)
      PHP_VERSION="$2"
      shift 2
      ;;
    -d|--domain)
      DOMAIN="$2"
      shift 2
      ;;
    -m|--config-method)
      SETUP_METHOD="$2"  # expected "web" or "cli"
      shift 2
      ;;
    --yes|-y)
      NONINTERACTIVE=true
      shift
      ;;
    --staging)
      STAGING=true
      shift
      ;;
    --ssl)
      GENERATE_SSL=true
      shift
      ;;
    --no-ssl)
      GENERATE_SSL=false
      shift
      ;;
    --install-pterodactyl)
      INSTALL_PTERODACTYL=true
      shift
      ;;
    --pterodactyl-subdomain)
      PTERODACTYL_SUBDOMAIN="$2"
      shift 2
      ;;
    --pterodactyl-admin-email)
      PTERODACTYL_ADMIN_EMAIL="$2"
      shift 2
      ;;
    --pterodactyl-admin-username)
      PTERODACTYL_ADMIN_USERNAME="$2"
      shift 2
      ;;
    --pterodactyl-admin-password)
      PTERODACTYL_ADMIN_PASSWORD="$2"
      shift 2
      ;;
    --disable-telemetry)
      TELEMETRY_ENABLED=false
      shift
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if $NONINTERACTIVE; then
  if [[ -z "$PHP_VERSION" || -z "$DOMAIN" || -z "$SETUP_METHOD" ]]; then
    echo "Running in non-interactive mode, but required args (--php-version, --domain, --config-method) are missing."
    exit 1
  fi
fi

if [[ "$STAGING" = true ]]; then
  STAGING_FLAG="--staging"
else
  STAGING_FLAG=""
fi

# Colors for pretty output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Telemetry initialization
if [ "$TELEMETRY_ENABLED" = true ]; then
    if source <(curl -fsSL https://pteroca.com/scripts/telemetry.sh) 2>/dev/null; then
        TELEMETRY_LOADED=true
    else
        TELEMETRY_LOADED=false
    fi
else
    TELEMETRY_LOADED=false
fi

# Display telemetry notice
[ "$TELEMETRY_LOADED" = true ] && telemetry_display_notice || true

# Error handler with telemetry support
exit_with_error() {
    local error_message="$1"
    local error_code="${2:-1}"

    # Display FULL error to user (with colors)
    echo -e "${RED}ERROR: ${error_message}${NC}"
    echo ""
    echo -e "${BLUE}Need help? Join our Discord community: https://discord.com/invite/Gz5phhuZym${NC}"
    echo ""

    # Send error to telemetry (automatic truncation happens in telemetry.sh)
    if [ "$TELEMETRY_LOADED" = true ]; then
        telemetry_installation_error "$TELEMETRY_SOURCE" "$error_message" "$INSTALLER_VERSION" "$error_code"
    fi

    exit "$error_code"
}

# Trap handler for unexpected errors (catches errors not explicitly handled)
error_trap_handler() {
    local exit_code=$?
    local line_number=$1

    # Only handle actual errors (not normal exits)
    if [ $exit_code -ne 0 ] && [ "$TELEMETRY_LOADED" = true ]; then
        # Generic error message for unexpected errors
        telemetry_installation_error "$TELEMETRY_SOURCE" "Unexpected error at line $line_number" "$INSTALLER_VERSION" "$exit_code"
    fi
}

# Set up error trap to catch unexpected failures
trap 'error_trap_handler $LINENO' ERR

# Print PteroCA banner
echo -e "${BLUE}"
cat << "EOF"
 ____  _                    ____    _
|  _ \| |_ ___ _ __ ___   / ___|  / \
| |_) | __/ _ \ '__/ _ \ | |     / _ \
|  __/| ||  __/ | | (_) || |___ / ___ \
|_|    \__\___|_|  \___/  \____/_/   \_\

EOF
echo -e "${NC}"

echo -e "${GREEN}PteroCA Installation Script${NC}"
echo -e "${BLUE}Copyright © 2025 PteroCA. All rights reserved.${NC}"
echo "--------------------------------------------"
echo -e "${BLUE}⭐ Enjoying PteroCA? Star us on GitHub: ${GREEN}https://github.com/PteroCA-Org/panel${NC}"
echo ""

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
    exit_with_error "Please run as root"
fi

# Function to generate random password
generate_password() {
    openssl rand -hex 16  # Generates 32 character hex string
}

# Detect OS and version
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION_ID=$VERSION_ID

        # Convert version strings to normalized format
        case $OS in
            ubuntu)
                if [[ $VERSION_ID == "22.04" ]]; then
                    OS_VERSION="jammy"
                elif [[ $VERSION_ID == "24.04" ]]; then
                    OS_VERSION="noble"
                else
                    exit_with_error "Unsupported Ubuntu version: $VERSION_ID"
                fi
                ;;
            debian)
                if [[ $VERSION_ID == "11" ]]; then
                    OS_VERSION="bullseye"
                elif [[ $VERSION_ID == "12" ]]; then
                    OS_VERSION="bookworm"
                elif [[ $VERSION_ID == "13" ]]; then
                    OS_VERSION="trixie"
                else
                    exit_with_error "Unsupported Debian version: $VERSION_ID"
                fi
                ;;
            rocky|almalinux)
                if [[ $VERSION_ID == "8"* ]]; then
                    OS_VERSION="8"
                elif [[ $VERSION_ID == "9"* ]]; then
                    OS_VERSION="9"
                elif [[ $VERSION_ID == "10"* ]]; then
                    OS_VERSION="10"
                else
                    exit_with_error "Unsupported $OS version: $VERSION_ID"
                fi
                ;;
            centos)
                if [[ $VERSION_ID == "9"* ]]; then
                    OS_VERSION="9"
                elif [[ $VERSION_ID == "10"* ]]; then
                    OS_VERSION="10"
                else
                    exit_with_error "Unsupported $OS version: $VERSION_ID"
                fi
                ;;
            *)
                exit_with_error "Unsupported operating system: $OS"
                ;;
        esac
    else
        exit_with_error "Unable to detect operating system"
    fi

    echo -e "${GREEN}Detected OS: $OS $VERSION_ID ($OS_VERSION)${NC}"
}

set_web_user() {
    case $OS in
        ubuntu|debian)
            WEB_USER="www-data"
            ;;
        centos|rocky|almalinux)
            WEB_USER="apache"
            ;;
    esac
    echo -e "${GREEN}Using web server user: $WEB_USER${NC}"
}

# Set PHP binary path based on OS
set_php_bin() {
    case $OS in
        ubuntu|debian)
            PHP_BIN="/usr/bin/php${PHP_VERSION}"
            ;;
        centos|rocky|almalinux)
            PHP_BIN="/usr/bin/php"
            ;;
    esac
    echo -e "${GREEN}Using PHP binary: $PHP_BIN${NC}"
}

# Service detection functions
check_mysql_installed() {
    if systemctl is-enabled --quiet mariadb 2>/dev/null || systemctl is-enabled --quiet mysql 2>/dev/null; then
        MYSQL_INSTALLED=true
        echo -e "${GREEN}MariaDB/MySQL already installed${NC}"
    elif command -v mysql &> /dev/null || command -v mariadb &> /dev/null; then
        MYSQL_INSTALLED=true
        echo -e "${GREEN}MariaDB/MySQL already installed${NC}"
    else
        MYSQL_INSTALLED=false
        echo -e "${YELLOW}MariaDB/MySQL not detected${NC}"
    fi
}

check_nginx_installed() {
    if systemctl is-enabled --quiet nginx 2>/dev/null; then
        NGINX_INSTALLED=true
        echo -e "${GREEN}Nginx already installed${NC}"
    elif command -v nginx &> /dev/null; then
        NGINX_INSTALLED=true
        echo -e "${GREEN}Nginx already installed${NC}"
    else
        NGINX_INSTALLED=false
        echo -e "${YELLOW}Nginx not detected${NC}"
    fi
}

check_php_installed() {
    case $OS in
        ubuntu|debian)
            if dpkg -l | grep -q "php${PHP_VERSION}-fpm" && command -v "php${PHP_VERSION}" &> /dev/null; then
                PHP_INSTALLED=true
                echo -e "${GREEN}PHP ${PHP_VERSION} already installed${NC}"
            else
                PHP_INSTALLED=false
                echo -e "${YELLOW}PHP ${PHP_VERSION} not detected${NC}"
            fi
            ;;
        centos|rocky|almalinux)
            if rpm -qa | grep -q "php-fpm" && command -v php &> /dev/null; then
                INSTALLED_PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
                if [[ "$INSTALLED_PHP_VERSION" == "$PHP_VERSION" ]]; then
                    PHP_INSTALLED=true
                    echo -e "${GREEN}PHP ${PHP_VERSION} already installed${NC}"
                else
                    PHP_INSTALLED=false
                    echo -e "${YELLOW}PHP ${PHP_VERSION} not detected (found ${INSTALLED_PHP_VERSION})${NC}"
                fi
            else
                PHP_INSTALLED=false
                echo -e "${YELLOW}PHP ${PHP_VERSION} not detected${NC}"
            fi
            ;;
    esac
}

check_composer_installed() {
    if command -v composer &> /dev/null; then
        COMPOSER_INSTALLED=true
        echo -e "${GREEN}Composer already installed${NC}"
    else
        COMPOSER_INSTALLED=false
        echo -e "${YELLOW}Composer not detected${NC}"
    fi
}

check_docker_installed() {
    if systemctl is-enabled --quiet docker 2>/dev/null; then
        DOCKER_INSTALLED=true
        echo -e "${GREEN}Docker already installed${NC}"
    elif command -v docker &> /dev/null; then
        DOCKER_INSTALLED=true
        echo -e "${GREEN}Docker already installed${NC}"
    else
        DOCKER_INSTALLED=false
        echo -e "${YELLOW}Docker not detected${NC}"
    fi
}

# Function to detect all services
detect_services() {
    echo -e "\n${BLUE}Detecting installed services...${NC}"
    check_mysql_installed
    check_nginx_installed
    check_php_installed
    check_composer_installed
    check_docker_installed
}

# Function to validate PHP version
validate_php_version() {
    case $1 in
        8.2|8.3|8.4)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Function to select PHP version
select_php_version() {
    if [[ -n "$PHP_VERSION" ]]; then
      echo -e "${GREEN}Using PHP version from CLI: $PHP_VERSION${NC}"
      if ! validate_php_version "$PHP_VERSION"; then
        exit_with_error "Invalid PHP version: $PHP_VERSION"
      fi
      return
    fi

    echo -e "\n${BLUE}Available PHP versions:${NC}"
    echo "1) PHP 8.2"
    echo "2) PHP 8.3"
    echo "3) PHP 8.4"

    while true; do
        read -p "Select PHP version [1-3]: " php_choice
        case $php_choice in
            1) PHP_VERSION="8.2"; break;;
            2) PHP_VERSION="8.3"; break;;
            3) PHP_VERSION="8.4"; break;;
            *) echo -e "${RED}Invalid selection${NC}";;
        esac
    done

    echo -e "${GREEN}Selected PHP version: $PHP_VERSION${NC}"
}

# Function to get configuration values
get_config_values() {
    echo -e "\n${BLUE}Basic Configuration${NC}"
    if [[ -z "$DOMAIN" ]]; then
      read -p "Enter your domain (e.g., pteroca.example.com) [leave empty for port 80]: " DOMAIN
    else
      echo -e "${GREEN}Using domain from CLI: $DOMAIN${NC}"
    fi

    # Ask if user wants to generate SSL certificate (only if domain is set and SSL not set via CLI)
    if [[ -z "$GENERATE_SSL" ]]; then
        if [[ -n "$DOMAIN" ]]; then
            echo -e "\n${BLUE}SSL Certificate Configuration${NC}"
            echo "Do you want to generate an SSL certificate for domain $DOMAIN?"
            echo -e "${YELLOW}WARNING: This requires a real domain pointing to this server.${NC}"
            echo "If you don't have a real domain or are testing locally, choose 'n'."
            read -p "Generate SSL certificate? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                GENERATE_SSL=true
                echo -e "${GREEN}SSL certificate will be generated for domain $DOMAIN${NC}"
            else
                GENERATE_SSL=false
                echo -e "${YELLOW}Skipping SSL certificate generation. Application will run without SSL.${NC}"
            fi
        else
            GENERATE_SSL=false
            echo -e "\n${BLUE}SSL Certificate Configuration${NC}"
            echo -e "${YELLOW}No domain set, skipping SSL.${NC}"
        fi
    else
        echo -e "\n${BLUE}SSL Certificate Configuration${NC}"
        if [[ "$GENERATE_SSL" == true ]]; then
            echo -e "${GREEN}SSL certificate generation enabled via CLI parameter${NC}"
        else
            echo -e "${YELLOW}SSL certificate generation disabled via CLI parameter${NC}"
        fi
    fi

    # Generate random passwords
    MYSQL_ROOT_PASSWORD=$(generate_password)
    DB_PASSWORD=$(generate_password)

    # Set database configuration
    DB_NAME="pteroca"
    DB_USER="pteroca"
    DB_HOST="localhost"

    echo -e "\n${GREEN}Generated Credentials:${NC}"
    echo -e "MySQL Root Password: ${MYSQL_ROOT_PASSWORD}"
    echo -e "Database User: ${DB_USER}"
    echo -e "Database Password: ${DB_PASSWORD}"
}

# Function to validate domain format and conflicts
validate_domain() {
    # Skip validation if no domain provided (use port 80)
    if [[ -z "$DOMAIN" ]]; then
        echo -e "${GREEN}No domain provided, PteroCA will use port 80 as default host${NC}"
        return 0
    fi
    
    # Allow subdomains, different TLDs, and more flexible domain formats
    if [[ ! $DOMAIN =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z0-9-]+$ ]]; then
        exit_with_error "Invalid domain format. Please enter a valid domain (e.g., example.com or pteroca.example.com)"
    fi
}

# Function to validate domain conflicts with Pterodactyl
validate_domain_conflicts() {
    if [[ "$INSTALL_PTERODACTYL" == true && -n "$DOMAIN" && -n "$PTERODACTYL_SUBDOMAIN" ]]; then
        if [[ "$DOMAIN" == "$PTERODACTYL_SUBDOMAIN" ]]; then
            echo -e "${RED}Domain conflict detected!${NC}"
            echo -e "${RED}PteroCA domain: $DOMAIN${NC}"
            echo -e "${RED}Pterodactyl domain: $PTERODACTYL_SUBDOMAIN${NC}"
            echo -e "${RED}Both applications cannot use the same domain.${NC}"
            echo ""
            echo -e "${YELLOW}Please choose different domains for each application.${NC}"
            echo "Example:"
            echo "- PteroCA: pteroca.example.com"
            echo "- Pterodactyl: panel.example.com"
            echo ""
            exit_with_error "Domain conflict: Both PteroCA and Pterodactyl cannot use the same domain"
        fi
    fi
    
    if [[ "$INSTALL_PTERODACTYL" == true && -n "$DOMAIN" && -z "$PTERODACTYL_SUBDOMAIN" ]]; then
        echo -e "${YELLOW}Configuration notice:${NC}"
        echo -e "PteroCA will use domain: $DOMAIN"
        echo -e "Pterodactyl will use port 8000 (no domain conflict)"
    fi
}

# Function to add PHP repository based on OS
add_php_repository() {
    echo -e "\n${BLUE}Adding PHP repository...${NC}"
    case $OS in
        ubuntu)
            # Add Ondrej PHP repository for Ubuntu
            apt -y install software-properties-common curl apt-transport-https ca-certificates gnupg
            LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
            ;;
        debian)
            # Add Sury PHP repository for Debian
            apt -y install ca-certificates curl gnupg
            curl -fsSL https://packages.sury.org/php/apt.gpg -o /etc/apt/trusted.gpg.d/php.gpg
            echo "deb https://packages.sury.org/php/ ${OS_VERSION} main" > /etc/apt/sources.list.d/php.list
            # Remove any Ubuntu PPA if it exists
            rm -f /etc/apt/sources.list.d/ondrej-*
            ;;
        centos|rocky|almalinux)
            # Add EPEL and Remi repositories for RHEL-based systems
            dnf -y install epel-release

            # Install Remi repository based on OS version
            if [ "$OS_VERSION" == "8" ]; then
                dnf -y install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
            elif [ "$OS_VERSION" == "9" ]; then
                dnf -y install https://rpms.remirepo.net/enterprise/remi-release-9.rpm
            elif [ "$OS_VERSION" == "10" ]; then
                dnf -y install https://rpms.remirepo.net/enterprise/remi-release-10.rpm
            fi
            ;;
    esac
}

# Function to add MariaDB repository
add_mariadb_repository() {
    echo -e "\n${BLUE}Adding MariaDB repository...${NC}"
    case $OS in
        ubuntu|debian)
            # Install prerequisites
            apt-get install -y apt-transport-https curl gnupg

            # Add MariaDB signing key
            curl -o /etc/apt/trusted.gpg.d/mariadb_release_signing_key.asc \
                "https://mariadb.org/mariadb_release_signing_key.asc"

            # Add repository based on OS and version
            if [ "$OS" = "ubuntu" ]; then
                echo "deb [signed-by=/etc/apt/trusted.gpg.d/mariadb_release_signing_key.asc] https://dlm.mariadb.com/repo/mariadb-server/11.8/repo/ubuntu ${OS_VERSION} main" \
                    > /etc/apt/sources.list.d/mariadb.list
            else
                echo "deb [signed-by=/etc/apt/trusted.gpg.d/mariadb_release_signing_key.asc] https://dlm.mariadb.com/repo/mariadb-server/11.8/repo/debian ${OS_VERSION} main" \
                    > /etc/apt/sources.list.d/mariadb.list
            fi
            ;;

        centos|rocky|almalinux)
            # Add MariaDB repository for RHEL-based systems
            cat > /etc/yum.repos.d/MariaDB.repo <<EOF
[mariadb]
name = MariaDB
baseurl = https://rpm.mariadb.org/10.11/rhel/\$releasever/x86_64
gpgkey = https://rpm.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck = 1
enabled = 1
module_hotfixes = 1
EOF
            ;;
    esac
}

# Function to update package manager
update_packages() {
    echo -e "\n${BLUE}Updating package manager...${NC}"
    case $OS in
        ubuntu)
            apt update
            apt-add-repository universe
            apt update  # Update again after adding universe
            ;;
        debian)
            # Debian already includes most packages, no need for universe
            apt update
            ;;
        centos|rocky|almalinux)
            dnf clean all
            dnf makecache
            dnf -y update
            ;;
    esac
}

# Function to install dependencies based on OS
install_dependencies() {
    echo -e "\n${BLUE}Installing dependencies...${NC}"

    # Set non-interactive mode to prevent installation prompts on Debian/Ubuntu
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        export DEBIAN_FRONTEND=noninteractive
    fi

    case $OS in
        ubuntu|debian)
            # Install MariaDB server and client
            apt -y install mariadb-server mariadb-client

            # Install PHP and other dependencies
            apt -y install php$PHP_VERSION \
                php$PHP_VERSION-{cli,common,ctype,curl,fpm,gd,iconv,intl,mbstring,mysql,pdo,pgsql,posix,simplexml,sqlite3,tokenizer,xml,zip} \
                nginx tar unzip git certbot python3-certbot-nginx curl

            # Install additional recommended packages
            apt -y install supervisor expect
            ;;

        centos|rocky|almalinux)
            # Install MariaDB server first
            dnf -y install MariaDB-server

            # Enable PHP Remi module
            dnf -y module enable php:remi-$PHP_VERSION

            # Install PHP and required extensions
            dnf -y install php php-{cli,common,ctype,curl,fpm,gd,iconv,intl,mbstring,mysqlnd,pdo,pgsql,posix,simplexml,sqlite3,tokenizer,xml,zip} \
                nginx tar unzip git certbot python3-certbot-nginx curl

            # Install additional recommended packages
            dnf -y install supervisor expect
            ;;
    esac

    # Verify mysql/mariadb client is available
    # Refresh bash command cache after package installation
    hash -r

    # Check if mysql or mariadb command exists
    if ! command -v mysql &> /dev/null && ! command -v mariadb &> /dev/null; then
        echo -e "${YELLOW}MySQL/MariaDB client not found, attempting to install...${NC}"
        if [ "$OS" = "ubuntu" ] || [ "$OS" = "debian" ]; then
            apt -y install mariadb-client
        elif [ "$OS" = "centos" ] || [ "$OS" = "rocky" ] || [ "$OS" = "almalinux" ]; then
            dnf -y install mysql
        fi

        # Refresh command cache and verify again
        hash -r

        # Check if either mysql or mariadb command is now available
        if ! command -v mysql &> /dev/null && ! command -v mariadb &> /dev/null; then
            exit_with_error "MySQL/MariaDB client is required but could not be installed"
        fi

        echo -e "${GREEN}MySQL/MariaDB client installed successfully${NC}"
    fi

    # Create mysql symlink if it doesn't exist but mariadb does (for Laravel compatibility)
    if ! command -v mysql &> /dev/null && command -v mariadb &> /dev/null; then
        echo -e "${YELLOW}Creating mysql symlink for Laravel compatibility...${NC}"
        ln -sf "$(command -v mariadb)" /usr/bin/mysql
        hash -r
        echo -e "${GREEN}MySQL symlink created: /usr/bin/mysql -> $(command -v mariadb)${NC}"
    fi

    # Enable and start MariaDB
    systemctl enable mariadb
    systemctl start mariadb

    # Check MariaDB status
    if ! systemctl is-active --quiet mariadb; then
        exit_with_error "MariaDB failed to start"
    fi

    echo -e "${GREEN}MariaDB installed and started successfully${NC}"
}

# Function to install Composer
install_composer() {
    echo -e "\n${BLUE}Installing Composer...${NC}"

    # Download and install Composer
    EXPECTED_CHECKSUM="$(php -r 'copy("https://composer.github.io/installer.sig", "php://stdout");')"
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
    ACTUAL_CHECKSUM="$(php -r "echo hash_file('sha384', 'composer-setup.php');")"

    if [ "$EXPECTED_CHECKSUM" != "$ACTUAL_CHECKSUM" ]; then
        rm composer-setup.php
        exit_with_error "Composer installer checksum verification failed"
    fi

    php composer-setup.php --quiet --install-dir=/usr/local/bin --filename=composer
    RESULT=$?
    rm composer-setup.php

    if [ $RESULT -ne 0 ]; then
        exit_with_error "Failed to install Composer"
    fi

    # Verify installation
    if ! command -v composer &> /dev/null; then
        exit_with_error "Composer installation verification failed"
    fi

    echo -e "${GREEN}Composer installed successfully${NC}"
}

# Function to configure services based on OS
configure_services() {
    echo -e "\n${BLUE}Configuring services...${NC}"
    case $OS in
        ubuntu|debian)
            systemctl enable --now php$PHP_VERSION-fpm
            systemctl enable --now nginx
            systemctl enable --now supervisor
            ;;

        centos|rocky|almalinux)
            systemctl enable --now php-fpm
            systemctl enable --now nginx
            systemctl enable --now supervisord

            # Configure SELinux if enabled
            if command -v semanage &> /dev/null; then
                echo -e "\n${BLUE}Configuring SELinux policies...${NC}"
                setsebool -P httpd_can_network_connect 1
                setsebool -P httpd_execmem 1
                setsebool -P httpd_unified 1
                semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/pteroca/storage(/.*)?"
                semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/pteroca/bootstrap/cache(/.*)?"
                restorecon -R /var/www/pteroca || true
            fi
            ;;
    esac
}

# Function to secure MariaDB installation
secure_mysql() {
    echo -e "\n${BLUE}Securing MariaDB installation...${NC}"

    # Check which secure installation script is available
    SECURE_SCRIPT="mysql_secure_installation"

    if ! command -v $SECURE_SCRIPT &> /dev/null; then
        # Try MariaDB specific script for newer versions
        SECURE_SCRIPT="mariadb-secure-installation"

        if ! command -v $SECURE_SCRIPT &> /dev/null; then
            echo -e "${YELLOW}Warning: Neither mysql_secure_installation nor mariadb-secure-installation found.${NC}"
            echo -e "${YELLOW}Manual MariaDB security setup will be performed.${NC}"

            # Fallback: Set root password directly and perform basic security operations
            echo -e "${BLUE}Setting MariaDB root password...${NC}"
            TEMP_OUTPUT=$(mktemp)
            mariadb <<EOF 2>&1 | tee "$TEMP_OUTPUT"
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%';
FLUSH PRIVILEGES;
EOF
            MARIADB_EXIT_CODE=${PIPESTATUS[0]}

            if [ $MARIADB_EXIT_CODE -ne 0 ]; then
                exit_with_error "Failed to secure MariaDB.

MariaDB output:
$(cat "$TEMP_OUTPUT")"
            fi
            rm -f "$TEMP_OUTPUT"

            echo -e "${GREEN}MariaDB secured directly.${NC}"

            # Skip the rest of the function since we've done it manually
            # Update MariaDB configuration for remote access
            configure_mariadb_remote_access
            return
        fi
    fi

    # Create expect script for automated secure installation
    cat > /tmp/mysql_secure.exp <<EOF
#!/usr/bin/expect -f
set timeout 10
spawn $SECURE_SCRIPT

expect {
    "Enter current password for root (enter for none):" {
        send "\r"
        exp_continue
    }
    "Switch to unix_socket authentication" {
        send "n\r"
        exp_continue
    }
    "Change the root password?" {
        send "y\r"
        exp_continue
    }
    "New password:" {
        send "${MYSQL_ROOT_PASSWORD}\r"
        exp_continue
    }
    "Re-enter new password:" {
        send "${MYSQL_ROOT_PASSWORD}\r"
        exp_continue
    }
    "Remove anonymous users?" {
        send "y\r"
        exp_continue
    }
    "Disallow root login remotely?" {
        send "n\r"
        exp_continue
    }
    "Remove test database and access to it?" {
        send "y\r"
        exp_continue
    }
    "Reload privilege tables now?" {
        send "y\r"
        exp_continue
    }
    eof
}
EOF

    # Make expect script executable
    chmod +x /tmp/mysql_secure.exp

    # Check if expect is installed
    if ! command -v expect &> /dev/null; then
        echo -e "${YELLOW}Expect not found. Installing...${NC}"

        case $OS in
            ubuntu|debian)
                apt -y install expect
                ;;
            centos|rocky|almalinux)
                dnf -y install expect
                ;;
        esac
    fi

    # Run the expect script
    /tmp/mysql_secure.exp

    # Remove the expect script
    rm -f /tmp/mysql_secure.exp

    # Configure remote access
    configure_mariadb_remote_access
}

# Extract MariaDB remote access configuration to a separate function
configure_mariadb_remote_access() {
    # Update MariaDB configuration for remote access
    case $OS in
        ubuntu|debian)
            MYSQL_CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
            ;;
        centos|rocky|almalinux)
            MYSQL_CONF="/etc/my.cnf.d/server.cnf"
            ;;
    esac

    # Backup original config
    cp "${MYSQL_CONF}" "${MYSQL_CONF}.bak"

    # Update or add bind-address
    if grep -q "^bind-address" "${MYSQL_CONF}"; then
        sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "${MYSQL_CONF}"
    else
        sed -i '/\[mysqld\]/a bind-address = 0.0.0.0' "${MYSQL_CONF}"
    fi

    # Restart MariaDB to apply configuration changes
    systemctl restart mariadb

    # Enable remote root access - capture both stdout and stderr
    TEMP_OUTPUT=$(mktemp)
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF 2>&1 | tee "$TEMP_OUTPUT"
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF
    MARIADB_EXIT_CODE=${PIPESTATUS[0]}

    if [ $MARIADB_EXIT_CODE -ne 0 ]; then
        exit_with_error "Failed to configure MariaDB remote access.

MariaDB output:
$(cat "$TEMP_OUTPUT")"
    fi
    rm -f "$TEMP_OUTPUT"

    # Save the root password
    echo "MariaDB root password: ${MYSQL_ROOT_PASSWORD}" > /root/.pteroca_mysql
    chmod 600 /root/.pteroca_mysql

    echo -e "${GREEN}MariaDB security setup and remote access configuration completed successfully${NC}"
}

# Function to create database and user
setup_database() {
    echo -e "\n${BLUE}Setting up database...${NC}"

    # Create database and user with verification - capture both stdout and stderr
    TEMP_OUTPUT=$(mktemp)
    mariadb -u root -p"${MYSQL_ROOT_PASSWORD}" <<MYSQL_SCRIPT 2>&1 | tee "$TEMP_OUTPUT"
-- First drop users if they exist
DROP USER IF EXISTS '${DB_USER}'@'localhost';
DROP USER IF EXISTS '${DB_USER}'@'%';

-- Create database
CREATE DATABASE IF NOT EXISTS ${DB_NAME};

-- Create users
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';

-- Grant privileges
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%';

-- Reload privileges
FLUSH PRIVILEGES;

-- Verify user creation
SELECT User, Host FROM mysql.user WHERE User = '${DB_USER}';

-- Verify grants
SHOW GRANTS FOR '${DB_USER}'@'localhost';
SHOW GRANTS FOR '${DB_USER}'@'%';
MYSQL_SCRIPT
    MARIADB_EXIT_CODE=${PIPESTATUS[0]}

    if [ $MARIADB_EXIT_CODE -ne 0 ]; then
        exit_with_error "Failed to create database and user.

MariaDB output:
$(cat "$TEMP_OUTPUT")"
    fi
    rm -f "$TEMP_OUTPUT"

    # Verify connection with new user
    if ! mariadb -u "${DB_USER}" -p"${DB_PASSWORD}" -e "USE ${DB_NAME}; SELECT 1;" >/dev/null 2>&1; then
        exit_with_error "Failed to verify database connection"
    fi

    echo -e "${GREEN}Database setup completed successfully${NC}"
}

# Function to set up PteroCA application
setup_application() {
    echo -e "\n${BLUE}Setting up PteroCA application...${NC}"

    # Create and setup PteroCA directory
    mkdir -p /var/www/pteroca
    cd /var/www/pteroca || exit 1

    # Clone repository - capture both stdout and stderr
    echo -e "${BLUE}Cloning PteroCA repository...${NC}"
    TEMP_OUTPUT=$(mktemp)
    git clone https://github.com/PteroCA-Org/panel.git ./ 2>&1 | tee "$TEMP_OUTPUT"
    GIT_EXIT_CODE=${PIPESTATUS[0]}

    if [ $GIT_EXIT_CODE -ne 0 ]; then
        exit_with_error "Failed to clone PteroCA repository.

Git output:
$(cat "$TEMP_OUTPUT")"
    fi
    rm -f "$TEMP_OUTPUT"

    git config --system --add safe.directory /var/www/pteroca

    # Generate APP_SECRET
    APP_SECRET=$(openssl rand -hex 32)

    # Copy and modify .env.SAMPLE file
    echo -e "${BLUE}Creating environment configuration...${NC}"
    if [ -f /var/www/pteroca/.env.SAMPLE ]; then
        cp /var/www/pteroca/.env.SAMPLE /var/www/pteroca/.env

        # Update environment values
        sed -i "s#APP_ENV=.*#APP_ENV=prod#" /var/www/pteroca/.env
        sed -i "s#APP_DEBUG=.*#APP_DEBUG=0#" /var/www/pteroca/.env
        sed -i "s#APP_SECRET=.*#APP_SECRET=${APP_SECRET}#" /var/www/pteroca/.env

        # Update database configuration
        # Ensure proper escaping of special characters in passwords
        DB_PASSWORD_ESCAPED=$(echo "${DB_PASSWORD}" | sed 's/[\/&]/\\&/g')
        sed -i "s#DATABASE_URL=.*#DATABASE_URL=mysql://${DB_USER}:${DB_PASSWORD_ESCAPED}@${DB_HOST}:3306/${DB_NAME}?serverVersion=11.6.2-MariaDB\&charset=utf8mb4#" /var/www/pteroca/.env

        # Update additional configuration
        if [[ "$GENERATE_SSL" == true ]]; then
            sed -i "s#APP_URL=.*#APP_URL=https://${DOMAIN}#" /var/www/pteroca/.env
        else
            sed -i "s#APP_URL=.*#APP_URL=http://${DOMAIN}#" /var/www/pteroca/.env
        fi
        sed -i "s#APP_TIMEZONE=.*#APP_TIMEZONE=UTC#" /var/www/pteroca/.env
        sed -i "s#APP_LOCALE=.*#APP_LOCALE=en#" /var/www/pteroca/.env
    else
        exit_with_error ".env.SAMPLE file not found. Please check the repository"
    fi

    # Verify .env file exists and has proper permissions
    if [ ! -f /var/www/pteroca/.env ]; then
        exit_with_error "Failed to create application .env file"
    fi

    # Set proper permissions for .env file
    chmod 640 /var/www/pteroca/.env
    chown $WEB_USER:$WEB_USER /var/www/pteroca/.env

    # Create required directories for panel
    echo -e "${BLUE}Creating panel directory structure...${NC}"

    # Core Symfony directories
    mkdir -p /var/www/pteroca/var/{cache,log,sessions,tmp}

    # Upload directories (general)
    mkdir -p /var/www/pteroca/public/uploads

    # Plugin and theme directories
    mkdir -p /var/www/pteroca/plugins
    mkdir -p /var/www/pteroca/themes
    mkdir -p /var/www/pteroca/public/plugins
    mkdir -p /var/www/pteroca/public/assets/theme

    # Temporary upload directories
    mkdir -p /var/www/pteroca/var/tmp/plugin-uploads
    mkdir -p /var/www/pteroca/var/tmp/theme-uploads

    echo -e "${GREEN}Panel directory structure created successfully${NC}"

    # Install dependencies - capture both stdout and stderr
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  ⭐ While you wait, support PteroCA by starring us on GitHub!${NC}"
    echo -e "${GREEN}     https://github.com/PteroCA-Org/panel${NC}"
    echo -e "${BLUE}  Your star helps the project grow and improve! ❤️${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Installing Composer dependencies...${NC}"
    TEMP_OUTPUT=$(mktemp)
    COMPOSER_ALLOW_SUPERUSER=1 ${PHP_BIN} /usr/local/bin/composer install --no-dev --optimize-autoloader --no-interaction --no-scripts 2>&1 | tee "$TEMP_OUTPUT"
    COMPOSER_EXIT_CODE=${PIPESTATUS[0]}

    if [ $COMPOSER_EXIT_CODE -ne 0 ]; then
        exit_with_error "Failed to install Composer dependencies.

Composer output:
$(cat "$TEMP_OUTPUT")"
    fi
    rm -f "$TEMP_OUTPUT"

    # Verify database connection
    echo -e "${BLUE}Verifying database connection...${NC}"
    if ! ${PHP_BIN} bin/console doctrine:query:sql "SELECT 1" > /dev/null 2>&1; then
        echo -e "${RED}Current settings:${NC}"
        echo -e "Database User: ${DB_USER}"
        echo -e "Database Host: ${DB_HOST}"
        echo -e "Database Name: ${DB_NAME}"
        exit_with_error "Database connection test failed. Please check credentials"
    fi

    run_migrations

    # Cache clear & install assets
    ${PHP_BIN} bin/console cache:clear --no-warmup
    ${PHP_BIN} bin/console assets:install public
}

run_migrations() {
  echo -e "\n${BLUE}Executing PteroCA Database Migrations...${NC}"

  if ! ${PHP_BIN} bin/console doctrine:migrations:migrate --no-interaction; then
    exit_with_error "Failed to execute database migrations"
  fi

  echo -e "${GREEN}Database migrations executed successfully${NC}"
}

configure_application() {
    echo -e "\n${BLUE}Configuring PteroCA application...${NC}"

    if [[ -n "$SETUP_METHOD" ]]; then
      case "$SETUP_METHOD" in
        web)
          SETUP_URL="https://${DOMAIN}/first-configuration"
          echo -e "${GREEN}Web Wizard forced by CLI. Visit: ${SETUP_URL}${NC}"
          return
          ;;
        cli)
          echo -e "${GREEN}CLI configuration forced by CLI flag.${NC}"
          ${PHP_BIN} bin/console app:configure-system
          return
          ;;
        *)
          exit_with_error "Invalid --config-method: $SETUP_METHOD (must be 'web' or 'cli')"
          ;;
      esac
    fi

    echo -e "\n${YELLOW}Select the initial configuration method:${NC}"
    echo "1) Web Wizard (recommended)"
    echo "2) CLI"

    while true; do
        read -p "Enter your choice [1-2]: " config_choice
        case $config_choice in
            1)
                SETUP_METHOD="web"
                SETUP_URL="https://${DOMAIN}/first-configuration"
                echo -e "\n${GREEN}Web Wizard selected. Please complete the configuration via the web interface.${NC}"
                echo -e "${YELLOW}Open your browser and navigate to: ${SETUP_URL}${NC}"
                return
                ;;
            2)
                SETUP_METHOD="cli"
                echo -e "\n${GREEN}CLI configuration selected. Running system configuration command...${NC}"
                ${PHP_BIN} bin/console app:configure-system
                return
                ;;
            *)
                echo -e "${RED}Invalid choice. Please select 1 or 2.${NC}"
                ;;
        esac
    done
}

# Function to configure PHP-FPM
configure_php_fpm() {
    echo -e "\n${BLUE}Configuring PHP-FPM...${NC}"

    # First find the actual PHP-FPM configuration path
    echo -e "${BLUE}Looking for PHP-FPM configuration...${NC}"

    case $OS in
        ubuntu|debian)
            # List possible FPM pool paths
            possible_paths=(
                "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"
                "/etc/php-fpm.d/www.conf"
                "/etc/php/${PHP_VERSION}/fpm/php-fpm.conf"
                "/etc/php-fpm.conf"
            )

            PHP_FPM_SERVICE="php${PHP_VERSION}-fpm"

            # Find the first existing config file
            for path in "${possible_paths[@]}"; do
                if [ -f "$path" ]; then
                    PHP_FPM_POOL="$path"
                    echo -e "${GREEN}Found PHP-FPM configuration at: $PHP_FPM_POOL${NC}"
                    break
                fi
            done
            ;;

        centos|rocky|almalinux)
            PHP_FPM_POOL="/etc/php-fpm.d/www.conf"
            PHP_FPM_SERVICE="php-fpm"
            ;;
    esac

    # Check if we found a configuration file
    if [ -z "$PHP_FPM_POOL" ] || [ ! -f "$PHP_FPM_POOL" ]; then
        echo -e "${RED}PHP-FPM configuration file not found${NC}"
        echo -e "${RED}Searched in:${NC}"
        for path in "${possible_paths[@]}"; do
            echo -e "${RED}- $path${NC}"
        done
        echo -e "${YELLOW}Attempting to continue without modifying PHP-FPM configuration...${NC}"
        return 0
    fi

  # Check if file was already modified by PteroCA or Pterodactyl to avoid conflicts
  if grep -q "; PteroCA configured\|; Pterodactyl configured" "$PHP_FPM_POOL"; then
    echo -e "${YELLOW}PHP-FPM already configured by PteroCA or Pterodactyl, skipping modification${NC}"
    return 0
  fi

    # Backup original configuration
    cp "$PHP_FPM_POOL" "${PHP_FPM_POOL}.bak"

    # Update PHP-FPM configuration with PteroCA marker
    sed -i 's/pm.max_children = .*/pm.max_children = 50/' "$PHP_FPM_POOL"
    sed -i 's/pm.start_servers = .*/pm.start_servers = 5/' "$PHP_FPM_POOL"
    sed -i 's/pm.min_spare_servers = .*/pm.min_spare_servers = 5/' "$PHP_FPM_POOL"
    sed -i 's/pm.max_spare_servers = .*/pm.max_spare_servers = 35/' "$PHP_FPM_POOL"
    
  # Add marker to prevent conflicts with Pterodactyl installer
  echo "; PteroCA configured PHP-FPM settings" >> "$PHP_FPM_POOL"

    # Verify PHP-FPM service exists
    if ! systemctl list-unit-files | grep -q "$PHP_FPM_SERVICE"; then
        exit_with_error "PHP-FPM service not found: $PHP_FPM_SERVICE"
    fi

    # Restart PHP-FPM
    systemctl restart "$PHP_FPM_SERVICE"

    # Verify service is running
    if ! systemctl is-active --quiet "$PHP_FPM_SERVICE"; then
        exit_with_error "Failed to start PHP-FPM service"
    fi

    echo -e "${GREEN}PHP-FPM configured successfully${NC}"
}

# Function to configure NGINX
configure_nginx() {
    echo -e "\n${BLUE}Configuring NGINX...${NC}"

    # Create sites-available directory if it doesn't exist (for RHEL-based systems)
    mkdir -p /etc/nginx/sites-available
    mkdir -p /etc/nginx/sites-enabled

    # Determine PHP-FPM socket location based on OS
    case $OS in
        ubuntu|debian)
            PHP_FPM_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"
            ;;
        centos|rocky|almalinux)
            PHP_FPM_SOCKET="/run/php-fpm/www.sock"
            ;;
    esac

    # Prepare server_name line - only include it if domain is provided
    if [[ -n "$DOMAIN" ]]; then
        SERVER_NAME_LINE="    server_name ${DOMAIN};"
    else
        SERVER_NAME_LINE=""
    fi

    # Create nginx config based on SSL choice
    if [[ "$GENERATE_SSL" == true ]]; then
        # Basic HTTP config that will be updated after SSL setup
        cat > /etc/nginx/sites-available/pteroca.conf <<EOF
server {
    listen 80;
${SERVER_NAME_LINE}
    root /var/www/pteroca/public;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:${PHP_FPM_SOCKET};
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF
    else
        # Configuration without SSL - final version
        cat > /etc/nginx/sites-available/pteroca.conf <<EOF
server {
    listen 80;
${SERVER_NAME_LINE}
    root /var/www/pteroca/public;
    index index.php;

    # Client body settings
    client_max_body_size 100m;
    client_body_timeout 120s;

    # Security headers (without HTTPS-specific ones)
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options nosniff;
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header Referrer-Policy same-origin;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:${PHP_FPM_SOCKET};
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \\n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    # Deny access to sensitive files
    location ~ /\.ht {
        deny all;
    }

    # Deny access to sensitive directories
    location ~ ^/(config|storage|vendor|scripts|database)/ {
        deny all;
    }
}
EOF
    fi

    # Add include for sites-enabled in nginx.conf if it doesn't exist (for RHEL-based systems)
    if ! grep -q "include /etc/nginx/sites-enabled/\*" /etc/nginx/nginx.conf; then
        sed -i '/http {/a \    include /etc/nginx/sites-enabled/*;' /etc/nginx/nginx.conf
    fi

    # Create symbolic link and remove default config
    ln -sf /etc/nginx/sites-available/pteroca.conf /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    rm -f /etc/nginx/conf.d/default.conf

    # Test NGINX configuration - capture both stdout and stderr
    TEMP_OUTPUT=$(mktemp)
    nginx -t 2>&1 | tee "$TEMP_OUTPUT"
    NGINX_EXIT_CODE=${PIPESTATUS[0]}

    if [ $NGINX_EXIT_CODE -ne 0 ]; then
        exit_with_error "NGINX configuration test failed.

Nginx output:
$(cat "$TEMP_OUTPUT")"
    fi
    rm -f "$TEMP_OUTPUT"

    # Reload NGINX
    systemctl reload nginx
}

# Function to setup SSL with Let's Encrypt
setup_ssl() {
    echo -e "\n${BLUE}Setting up SSL certificate...${NC}"

    # Get the certificate using certbot - capture both stdout and stderr
    TEMP_OUTPUT=$(mktemp)
    certbot certonly --nginx ${STAGING_FLAG} -d ${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN} 2>&1 | tee "$TEMP_OUTPUT"
    CERTBOT_EXIT_CODE=${PIPESTATUS[0]}

    if [ $CERTBOT_EXIT_CODE -ne 0 ]; then
        exit_with_error "Failed to obtain SSL certificate from Let's Encrypt.

Certbot output:
$(cat "$TEMP_OUTPUT")"
    fi
    rm -f "$TEMP_OUTPUT"

    # Prepare server_name line for SSL config - only include it if domain is provided
    if [[ -n "$DOMAIN" ]]; then
        SERVER_NAME_LINE="    server_name ${DOMAIN};"
    else
        SERVER_NAME_LINE=""
    fi

    # Update NGINX configuration with SSL
    cat > /etc/nginx/sites-available/pteroca.conf <<EOF
server {
    listen 80;
${SERVER_NAME_LINE}
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
${SERVER_NAME_LINE}

    root /var/www/pteroca/public;
    index index.php;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:50m;
    ssl_session_tickets off;

    # Modern configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Content-Type-Options nosniff;
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header Referrer-Policy same-origin;

    # Client body settings
    client_max_body_size 100m;
    client_body_timeout 120s;

    # Application locations
    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:${PHP_FPM_SOCKET};
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    # Deny access to sensitive files
    location ~ /\.ht {
        deny all;
    }

    # Deny access to sensitive directories
    location ~ ^/(config|storage|vendor|scripts|database)/ {
        deny all;
    }
}
EOF

    # Setup auto-renewal
    echo "0 0,12 * * * root python -c 'import random; import time; time.sleep(random.random() * 3600)' && certbot renew -q" > /etc/cron.d/certbot

    # Test and reload NGINX - capture both stdout and stderr
    TEMP_OUTPUT=$(mktemp)
    nginx -t 2>&1 | tee "$TEMP_OUTPUT"
    NGINX_TEST_EXIT_CODE=${PIPESTATUS[0]}

    if [ $NGINX_TEST_EXIT_CODE -ne 0 ]; then
        exit_with_error "NGINX configuration test failed after SSL setup.

Nginx output:
$(cat "$TEMP_OUTPUT")"
    fi
    rm -f "$TEMP_OUTPUT"

    TEMP_OUTPUT=$(mktemp)
    systemctl reload nginx 2>&1 | tee "$TEMP_OUTPUT"
    NGINX_RELOAD_EXIT_CODE=${PIPESTATUS[0]}

    if [ $NGINX_RELOAD_EXIT_CODE -ne 0 ]; then
        exit_with_error "Failed to reload NGINX after SSL configuration.

Systemctl output:
$(cat "$TEMP_OUTPUT")"
    fi
    rm -f "$TEMP_OUTPUT"
}

# Function to ask about Pterodactyl installation
ask_pterodactyl_installation() {
    if [[ "$INSTALL_PTERODACTYL" != true ]] && ! $NONINTERACTIVE; then
        echo -e "\n${BLUE}Pterodactyl Integration${NC}"
        echo "Do you want to install Pterodactyl Panel alongside PteroCA?"
        echo -e "${YELLOW}This will install Pterodactyl accessible via port 8000 or subdomain.${NC}"
        read -p "Install Pterodactyl? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            INSTALL_PTERODACTYL=true
            
            # Ask for subdomain or port
            echo -e "\n${BLUE}Pterodactyl Configuration${NC}"
            echo "Choose how to configure Pterodactyl access:"
            echo "1) Use subdomain (if you have one configured)"
            echo "2) Use port 8000 (accessible via IP:8000)"
            
            while true; do
                read -p "Enter your choice [1-2]: " pterodactyl_choice
                case $pterodactyl_choice in
                    1)
                        read -p "Enter Pterodactyl subdomain (optional, leave empty to skip): " PTERODACTYL_SUBDOMAIN
                        if [[ -z "$PTERODACTYL_SUBDOMAIN" ]]; then
                            echo -e "${YELLOW}No subdomain provided. Pterodactyl will use port 8000.${NC}"
                        fi
                        break
                        ;;
                    2)
                        PTERODACTYL_SUBDOMAIN=""
                        echo -e "${GREEN}Pterodactyl will be configured on port 8000${NC}"
                        break
                        ;;
                    *)
                        echo -e "${RED}Invalid choice. Please select 1 or 2.${NC}"
                        ;;
                esac
            done
        else
            INSTALL_PTERODACTYL=false
        fi
    fi
}

# Function to install Pterodactyl
install_pterodactyl() {
    if [[ "$INSTALL_PTERODACTYL" == true ]]; then
        echo -e "\n${BLUE}Installing Pterodactyl Panel...${NC}"
        
        # Check if local pterodactyl installer exists (for testing)
        if [ -f "/root/scripts/pterodactyl_installer.sh" ]; then
            echo -e "${BLUE}Using local Pterodactyl installer...${NC}"
            cp /root/scripts/pterodactyl_installer.sh /tmp/pterodactyl_installer.sh
        else
            # Download pterodactyl installer
            echo -e "${BLUE}Downloading Pterodactyl installer...${NC}"
            if ! curl -fsSL https://pteroca.com/scripts/pterodactyl_installer.sh -o /tmp/pterodactyl_installer.sh; then
                exit_with_error "Failed to download Pterodactyl installer"
            fi
        fi

        chmod +x /tmp/pterodactyl_installer.sh
        
        # Prepare parameters based on detected services
        params="--yes --php-version $PHP_VERSION"
        
        if [[ "$MYSQL_INSTALLED" == true ]]; then
            params+=" --reuse-mysql"
        fi
        
        if [[ "$NGINX_INSTALLED" == true ]]; then
            params+=" --reuse-nginx"
        fi
        
        if [[ "$PHP_INSTALLED" == true ]]; then
            params+=" --reuse-php $PHP_VERSION"
        fi
        
        if [[ "$COMPOSER_INSTALLED" == true ]]; then
            params+=" --reuse-composer"
        fi
        
        if [[ "$DOCKER_INSTALLED" == true ]]; then
            params+=" --reuse-docker"
        fi
        
        # Configure domain/port
        if [[ -n "$PTERODACTYL_SUBDOMAIN" ]]; then
            # User explicitly provided a Pterodactyl subdomain
            params+=" --domain $PTERODACTYL_SUBDOMAIN"
            if [[ "$GENERATE_SSL" == true ]]; then
                params+=" --ssl"
            else
                params+=" --no-ssl"
            fi
        else
            # No subdomain - use port 8000 and pass empty domain to skip domain prompt
            params+=" --domain \"\" --port 8000"
        fi
        
        # Add admin credentials if provided
        if [[ -n "$PTERODACTYL_ADMIN_EMAIL" ]]; then
            params+=" --admin-email $PTERODACTYL_ADMIN_EMAIL"
        fi
        
        if [[ -n "$PTERODACTYL_ADMIN_USERNAME" ]]; then
            params+=" --admin-username $PTERODACTYL_ADMIN_USERNAME"
        fi
        
        if [[ -n "$PTERODACTYL_ADMIN_PASSWORD" ]]; then
            params+=" --admin-password $PTERODACTYL_ADMIN_PASSWORD"
        fi
        
        # Add export credentials flag
        params+=" --export-credentials"

        # Add telemetry flag if disabled
        if [[ "$TELEMETRY_ENABLED" == false ]]; then
            params+=" --disable-telemetry"
        fi

        echo -e "${BLUE}Running Pterodactyl installer with parameters: $params${NC}"
        
        # Run pterodactyl installer
        if ! /tmp/pterodactyl_installer.sh $params; then
            rm -f /tmp/pterodactyl_installer.sh
            exit_with_error "Pterodactyl installation script failed"
        fi
        
        # Store Pterodactyl credentials for later import (after PteroCA installation)
        if [[ -f /tmp/pterodactyl_install_data.txt ]]; then
            source /tmp/pterodactyl_install_data.txt
            echo -e "${GREEN}Pterodactyl credentials stored for import${NC}"
        fi
        
        # Cleanup
        rm -f /tmp/pterodactyl_installer.sh
        
        echo -e "${GREEN}Pterodactyl installation completed successfully!${NC}"
    fi
}

# Function to setup CRON jobs
setup_cron() {
    echo -e "\n${BLUE}Setting up CRON jobs...${NC}"

    # Add PteroCA CRON job
    echo "* * * * * $WEB_USER ${PHP_BIN} /var/www/pteroca/bin/console app:cron-job-schedule >> /dev/null 2>&1" > /etc/cron.d/pteroca

    # Add daily backup CRON
    echo "0 2 * * * root /usr/local/bin/pteroca-backup >> /var/log/pteroca-backup.log 2>&1" > /etc/cron.d/pteroca-backup

    # Create backup script
    cat > /usr/local/bin/pteroca-backup <<'EOF'
#!/bin/bash
BACKUP_DIR="/var/backups/pteroca"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p ${BACKUP_DIR}

# Backup database
mysqldump --single-transaction pteroca > ${BACKUP_DIR}/pteroca_db_${TIMESTAMP}.sql

# Backup files
tar -czf ${BACKUP_DIR}/pteroca_files_${TIMESTAMP}.tar.gz -C /var/www pteroca

# Keep only last 7 days of backups
find ${BACKUP_DIR} -type f -mtime +7 -delete
EOF

    chmod +x /usr/local/bin/pteroca-backup
}

# Import Pterodactyl credentials to PteroCA database
import_pterodactyl_credentials() {
    if [[ -n "$PTERODACTYL_PANEL_URL" && -n "$PTERODACTYL_API_KEY" ]]; then
        echo -e "${BLUE}Updating PteroCA settings with Pterodactyl credentials...${NC}"
        
        cd /var/www/pteroca || exit 1
        
        # Update pterodactyl_url setting
        ${PHP_BIN} bin/console dbal:run-sql "UPDATE setting SET value = '${PTERODACTYL_PANEL_URL}' WHERE name = 'pterodactyl_url'" || true
        
        # Update pterodactyl_api_key setting
        ${PHP_BIN} bin/console dbal:run-sql "UPDATE setting SET value = '${PTERODACTYL_API_KEY}' WHERE name = 'pterodactyl_api_key'" || true
        
        # Clear cache
        ${PHP_BIN} bin/console cache:clear --no-warmup
        
        # Fix permissions after cache clear
        chown -R $WEB_USER:$WEB_USER /var/www/pteroca/var
        chmod -R 755 /var/www/pteroca/var
        
        echo -e "${GREEN}PteroCA settings updated with Pterodactyl credentials${NC}"
        
        # Cleanup temporary file
        rm -f /tmp/pterodactyl_install_data.txt
    fi
}

# Function to perform final checks
perform_final_checks() {
    echo -e "\n${BLUE}Performing final checks...${NC}"

    # Set supervisor service name based on OS
    case $OS in
        ubuntu|debian)
            SUPERVISOR_SERVICE="supervisor"
            ;;
        centos|rocky|almalinux)
            SUPERVISOR_SERVICE="supervisord"
            ;;
    esac

    # Check services
    services=("nginx" "${PHP_FPM_SERVICE}" "mariadb" "${SUPERVISOR_SERVICE}")
    for service in "${services[@]}"; do
        if ! systemctl is-active --quiet $service; then
            echo -e "${RED}Service $service is not running${NC}"
            systemctl start $service
        fi
    done

    # Check file permissions
    if [ ! -w "/var/www/pteroca/var" ]; then
        echo -e "${RED}Incorrect permissions on /var/www/pteroca/var${NC}"
        chmod -R 755 /var/www/pteroca/var
    fi

    # Set proper permissions
    echo -e "${BLUE}Setting file permissions...${NC}"

    # Full ownership to web user
    chown -R $WEB_USER:$WEB_USER /var/www/pteroca

    # Core Symfony directories - 755 for read/write/execute
    chmod -R 755 /var/www/pteroca/var

    # Upload directories - 755 for file uploads
    chmod -R 755 /var/www/pteroca/public/uploads

    # Plugin and theme directories - 755
    chmod -R 755 /var/www/pteroca/plugins
    chmod -R 755 /var/www/pteroca/themes
    chmod -R 755 /var/www/pteroca/public/plugins
    chmod -R 755 /var/www/pteroca/public/assets/theme

    # Temporary upload directories - 775 for write operations
    chmod -R 775 /var/www/pteroca/var/tmp

    echo -e "${GREEN}Permissions set successfully${NC}"

    # Check database connection
    if ! ${PHP_BIN} /var/www/pteroca/bin/console doctrine:query:sql "SELECT 1" > /dev/null 2>&1; then
        exit_with_error "Final database connection check failed"
    fi
    
    # Import Pterodactyl credentials if they exist
    import_pterodactyl_credentials
}

# Main installation process
echo -e "\n${BLUE}Starting PteroCA installation...${NC}"

# Send telemetry: installation start
[ "$TELEMETRY_LOADED" = true ] && telemetry_installation_start "$TELEMETRY_SOURCE" "$INSTALLER_VERSION" || true

# Initialize
detect_os
select_php_version
get_config_values
validate_domain
set_web_user
set_php_bin

# Detect existing services before asking about Pterodactyl
detect_services

# Ask about Pterodactyl installation
ask_pterodactyl_installation

# Validate domain conflicts after all configuration is gathered
validate_domain_conflicts

# Install Pterodactyl if requested
install_pterodactyl

# Repository and package setup
add_php_repository
add_mariadb_repository
update_packages
install_dependencies
install_composer
configure_services

# Database and application setup
secure_mysql
setup_database
setup_application

# Web server and SSL setup
configure_php_fpm
configure_nginx
if [[ "$GENERATE_SSL" == true ]]; then
    setup_ssl
else
    echo -e "${YELLOW}Skipping SSL configuration...${NC}"
fi
setup_cron

# Configure PteroCA application
configure_application

# Final checks
perform_final_checks

# Display installation summary
echo -e "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  ✅ Installation Complete! Thank you for choosing PteroCA!${NC}"
echo -e "${BLUE}  ⭐ Show your support by starring our GitHub repository:${NC}"
echo -e "${GREEN}     https://github.com/PteroCA-Org/panel${NC}"
echo -e "${YELLOW}  Every star helps us improve and reach more users! 🚀${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
echo -e "\n${GREEN}PteroCA installation completed successfully!${NC}"
echo -e "\n${BLUE}Installation Summary:${NC}"
echo -e "Domain: ${DOMAIN:-"(none - using port 80)"}"
echo -e "PHP Version: ${PHP_VERSION}"
echo -e "OS: ${OS} ${VERSION_ID}"

# Construct Panel URL based on domain availability
if [[ -n "$DOMAIN" ]]; then
    if [[ "$GENERATE_SSL" == true ]]; then
        echo -e "Panel URL: https://${DOMAIN}"
    else
        echo -e "Panel URL: http://${DOMAIN}"
    fi
else
    # No domain configured, use IP for Panel URL
    SERVER_IP=$(hostname -I | awk '{print $1}')
    if [[ -n "$SERVER_IP" ]]; then
        if [[ "$GENERATE_SSL" == true ]]; then
            echo -e "Panel URL: https://${SERVER_IP}"
        else
            echo -e "Panel URL: http://${SERVER_IP}"
        fi
    else
        echo -e "Panel URL: http://YOUR_SERVER_IP (replace with actual server IP)"
    fi
fi

if [[ "$INSTALL_PTERODACTYL" == true ]]; then
    echo -e "\n${BLUE}Pterodactyl Integration:${NC}"
    if [[ -n "$PTERODACTYL_SUBDOMAIN" ]]; then
        if [[ "$GENERATE_SSL" == true ]]; then
            echo -e "Pterodactyl URL: https://${PTERODACTYL_SUBDOMAIN}"
        else
            echo -e "Pterodactyl URL: http://${PTERODACTYL_SUBDOMAIN}"
        fi
    else
        SERVER_IP=$(hostname -I | awk '{print $1}')
        echo -e "Pterodactyl URL: http://${SERVER_IP}:8000"
        if [[ -n "$DOMAIN" ]]; then
            echo -e "Alternative URL: http://${DOMAIN}:8000"
        fi
    fi
    
    # Display Pterodactyl credentials if they were imported
    if [[ -n "$PTERODACTYL_ADMIN_EMAIL" ]]; then
        echo -e "\n${YELLOW}Pterodactyl Credentials:${NC}"
        echo -e "Panel URL: ${PTERODACTYL_PANEL_URL}"
        echo -e "API Key: ${PTERODACTYL_API_KEY}"
        echo -e "Admin Email: ${PTERODACTYL_ADMIN_EMAIL}"
        echo -e "Admin Username: ${PTERODACTYL_ADMIN_USERNAME}"
        echo -e "Admin Password: ${PTERODACTYL_ADMIN_PASSWORD}"
        
        echo -e "\n${YELLOW}Pterodactyl Database:${NC}"
        echo -e "Database Name: ${PTERODACTYL_DATABASE_NAME}"
        echo -e "Database User: ${PTERODACTYL_DATABASE_USER}"
        echo -e "Database Password: ${PTERODACTYL_DATABASE_PASSWORD}"
    fi
    
    echo -e "${GREEN}Pterodactyl Panel installed successfully!${NC}"
fi

echo -e "\n${YELLOW}PteroCA Database Credentials:${NC}"
echo -e "Database Name: ${DB_NAME}"
echo -e "Database User: ${DB_USER}"
echo -e "Database Password: ${DB_PASSWORD}"
echo -e "Database Host: ${DB_HOST}"
echo -e "MySQL Root Password: ${MYSQL_ROOT_PASSWORD}"

echo -e "\n${YELLOW}PteroCA Credential Files:${NC}"
echo -e "MySQL Root Password: /root/.pteroca_mysql"
echo -e "Environment File: /var/www/pteroca/.env"

if [[ "$SETUP_METHOD" == "web" ]]; then
    echo -e "\n${YELLOW}Next Steps: Complete the Initial Configuration${NC}"
    echo -e "The installation is complete, but you still need to configure your PteroCA instance."
    echo -e "To finalize the setup, please visit the Web Wizard and follow the instructions:"
    
    # Get server IP for URL construction
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    # Determine protocol
    if [[ "$GENERATE_SSL" == true ]]; then
        PROTOCOL="https"
    else
        PROTOCOL="http"
    fi
    
    # Construct URL based on domain availability
    if [[ -n "$DOMAIN" ]]; then
        SETUP_URL="${PROTOCOL}://${DOMAIN}/first-configuration"
        echo -e "${GREEN}Open your browser and go to: ${SETUP_URL}${NC}"
        
        # Provide IP alternative only if domain is configured
        if [[ -n "$SERVER_IP" ]]; then
            echo -e "${BLUE}If your domain is not yet configured or doesn't resolve to this server,"
            echo -e "you can also try: ${PROTOCOL}://${SERVER_IP}/first-configuration${NC}"
        fi
    else
        # No domain configured, use IP as primary URL
        if [[ -n "$SERVER_IP" ]]; then
            SETUP_URL="${PROTOCOL}://${SERVER_IP}/first-configuration"
            echo -e "${GREEN}Open your browser and go to: ${SETUP_URL}${NC}"
        else
            echo -e "${RED}Warning: Could not detect server IP address."
            echo -e "Please access the configuration at: ${PROTOCOL}://YOUR_SERVER_IP/first-configuration${NC}"
        fi
    fi
fi

if [[ "$GENERATE_SSL" == false ]]; then
    echo -e "\n${YELLOW}Security Notice:${NC}"
    echo -e "Application is running without SSL encryption. In production environment,"
    echo -e "it is strongly recommended to configure SSL certificate for security."
fi

echo -e "\n${YELLOW}Important:${NC}"
echo -e "1. Save these credentials in a secure location"
echo -e "2. Configure your firewall to allow ports 80 and 443 (if needed)"
echo -e "3. Install PteroCA Pterodactyl Plugin (Read more: https://docs.pteroca.com/guidebook/pteroca-pterodactyl-addon)"
echo -e "4. ${YELLOW}Cloudflare Users:${NC} If your panel is behind Cloudflare, you must configure"
echo -e "   trusted proxies and trusted hosts to avoid CSRF and other issues."
echo -e "   More info: ${BLUE}https://docs.pteroca.com/getting-started/installation/basic-configuration#csrf-and-cloudflare${NC}"

echo -e "\n${GREEN}Thank you for installing PteroCA!${NC}"

# Send telemetry: installation complete
[ "$TELEMETRY_LOADED" = true ] && telemetry_installation_complete "$TELEMETRY_SOURCE" "$INSTALLER_VERSION" "$SECONDS" || true
