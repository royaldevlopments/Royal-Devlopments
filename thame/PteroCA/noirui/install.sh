#!/bin/bash

# NoirUI Theme Installer for PteroCA
# This script installs the NoirUI theme to your PteroCA installation

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default PteroCA directory
DEFAULT_PTEROCA_DIR="/var/www/pteroca"
PTEROCA_DIR=""

# Script directory (where the theme package is)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Print colored messages
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════${NC}"
    echo -e "${BLUE}  NoirUI Theme Installer for PteroCA${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════${NC}\n"
}

# Check if running as root or with sudo
check_permissions() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "This script must be run as root or with sudo"
        print_info "Please run: sudo $0"
        exit 1
    fi
}

# Detect PteroCA installation directory
detect_pteroca_dir() {
    print_info "Detecting PteroCA installation..."
    
    # Check default location
    if [ -d "$DEFAULT_PTEROCA_DIR" ] && [ -f "$DEFAULT_PTEROCA_DIR/composer.json" ]; then
        PTEROCA_DIR="$DEFAULT_PTEROCA_DIR"
        print_success "Found PteroCA at: $PTEROCA_DIR"
        return 0
    fi
    
    # Check common alternative locations
    COMMON_PATHS=(
        "/var/www/html/pteroca"
        "/home/pteroca"
        "/opt/pteroca"
        "/usr/share/nginx/html/pteroca"
    )
    
    for path in "${COMMON_PATHS[@]}"; do
        if [ -d "$path" ] && [ -f "$path/composer.json" ]; then
            PTEROCA_DIR="$path"
            print_success "Found PteroCA at: $PTEROCA_DIR"
            return 0
        fi
    done
    
    return 1
}

# Prompt for PteroCA directory
prompt_pteroca_dir() {
    echo ""
    read -p "Enter PteroCA installation path [$DEFAULT_PTEROCA_DIR]: " input_dir
    PTEROCA_DIR="${input_dir:-$DEFAULT_PTEROCA_DIR}"
    
    # Validate directory
    if [ ! -d "$PTEROCA_DIR" ]; then
        print_error "Directory does not exist: $PTEROCA_DIR"
        return 1
    fi
    
    if [ ! -f "$PTEROCA_DIR/composer.json" ]; then
        print_error "Invalid PteroCA installation (composer.json not found)"
        return 1
    fi
    
    print_success "Using PteroCA directory: $PTEROCA_DIR"
    return 0
}

# Create backup of existing theme (if exists)
create_backup() {
    print_info "Checking for existing NoirUI theme..."
    
    local backup_created=false
    local backup_dir="$PTEROCA_DIR/backups/noirui-theme-$(date +%Y%m%d-%H%M%S)"
    
    if [ -d "$PTEROCA_DIR/themes/noirui" ] || [ -d "$PTEROCA_DIR/public/assets/theme/noirui" ]; then
        print_success "Found theme folders, updating theme files for NoirUI"
        read -p "Create backup before updating? [Y/n]: " create_backup
        create_backup="${create_backup:-Y}"
        
        if [[ "$create_backup" =~ ^[Yy]$ ]]; then
            print_info "Creating backup..."
            mkdir -p "$backup_dir"
            
            if [ -d "$PTEROCA_DIR/themes/noirui" ]; then
                cp -r "$PTEROCA_DIR/themes/noirui" "$backup_dir/"
                print_success "Backed up themes/noirui"
                backup_created=true
            fi
            
            if [ -d "$PTEROCA_DIR/public/assets/theme/noirui" ]; then
                mkdir -p "$backup_dir/public/assets/theme"
                cp -r "$PTEROCA_DIR/public/assets/theme/noirui" "$backup_dir/public/assets/theme/"
                print_success "Backed up public/assets/theme/noirui"
                backup_created=true
            fi
            
            if [ "$backup_created" = true ]; then
                print_success "Backup created at: $backup_dir"
            fi
        fi
    else
        print_warning "No existing NoirUI theme found, performing fresh installation"
    fi
}

# Install theme files
install_theme() {
    print_info "Installing NoirUI theme files..."
    
    # Create directories if they don't exist
    mkdir -p "$PTEROCA_DIR/themes"
    mkdir -p "$PTEROCA_DIR/public/assets/theme"
    
    # Copy theme templates
    print_info "Copying theme templates..."
    cp -r "$SCRIPT_DIR/themes/noirui" "$PTEROCA_DIR/themes/"
    print_success "Theme templates installed"
    
    # Copy theme assets
    print_info "Copying theme assets..."
    cp -r "$SCRIPT_DIR/public/assets/theme/noirui" "$PTEROCA_DIR/public/assets/theme/"
    print_success "Theme assets installed"
}

# Set proper permissions
set_permissions() {
    print_info "Setting file permissions..."
    
    # Detect web server user
    local web_user="www-data"
    
    if id "nginx" &>/dev/null; then
        web_user="nginx"
    elif id "apache" &>/dev/null; then
        web_user="apache"
    fi
    
    print_info "Using web server user: $web_user"
    
    # Set ownership
    chown -R "$web_user:$web_user" "$PTEROCA_DIR/themes/noirui" 2>/dev/null || {
        print_warning "Could not set ownership (non-critical)"
    }
    chown -R "$web_user:$web_user" "$PTEROCA_DIR/public/assets/theme/noirui" 2>/dev/null || {
        print_warning "Could not set ownership (non-critical)"
    }
    
    # Set file permissions
    find "$PTEROCA_DIR/themes/noirui" -type f -exec chmod 644 {} \; 2>/dev/null
    find "$PTEROCA_DIR/themes/noirui" -type d -exec chmod 755 {} \; 2>/dev/null
    find "$PTEROCA_DIR/public/assets/theme/noirui" -type f -exec chmod 644 {} \; 2>/dev/null
    find "$PTEROCA_DIR/public/assets/theme/noirui" -type d -exec chmod 755 {} \; 2>/dev/null
    
    print_success "Permissions set successfully"
}

# Clear cache
clear_cache() {
    print_info "Clearing application cache..."
    
    cd "$PTEROCA_DIR"
    
    # Clear Symfony cache
    if [ -f "bin/console" ]; then
        print_info "Clearing Symfony cache..."
        php bin/console cache:clear --no-warmup 2>/dev/null && print_success "Symfony cache cleared" || {
            print_warning "Could not clear Symfony cache automatically"
        }
        
        # Warm up cache for better performance
        print_info "Warming up cache..."
        php bin/console cache:warmup 2>/dev/null && print_success "Cache warmed up" || {
            print_warning "Could not warm up cache"
        }
    else
        print_warning "Console command not found"
    fi
    
    # Clear var/cache directory
    if [ -d "var/cache" ]; then
        print_info "Clearing var/cache directory..."
        rm -rf var/cache/* 2>/dev/null && print_success "var/cache cleared" || {
            print_warning "Could not clear var/cache directory"
        }
    fi
    
    # Clear OPcache (PHP opcode cache)
    print_info "Clearing PHP OPcache..."
    if command -v systemctl &> /dev/null; then
        # Try to restart PHP-FPM to clear OPcache
        for service in php8.3-fpm php8.2-fpm php8.1-fpm php-fpm; do
            if systemctl is-active --quiet "$service" 2>/dev/null; then
                systemctl reload "$service" 2>/dev/null && {
                    print_success "PHP OPcache cleared (reloaded $service)"
                    break
                } || print_warning "Could not reload $service"
            fi
        done
    else
        print_warning "systemctl not found, cannot automatically clear PHP OPcache"
        print_info "Please restart your PHP-FPM service manually"
    fi
    
    # Clear Twig cache specifically
    if [ -d "var/cache/prod/twig" ]; then
        print_info "Clearing Twig template cache..."
        rm -rf var/cache/prod/twig/* 2>/dev/null && print_success "Twig cache cleared"
    fi
    
    if [ -d "var/cache/dev/twig" ]; then
        rm -rf var/cache/dev/twig/* 2>/dev/null
    fi
    
    print_success "All caches cleared successfully"
}

# Print installation summary
print_summary() {
    echo -e "\n${GREEN}═══════════════════════════════════════════${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════${NC}\n"
    
    print_info "Theme installed to:"
    echo "  • $PTEROCA_DIR/themes/noirui"
    echo "  • $PTEROCA_DIR/public/assets/theme/noirui"
    
    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo "  1. Go to Admin Panel > Settings > Theme Settings"
    echo "  2. Select 'NoirUI' from the theme dropdown"
    echo "  3. Save changes"
    echo "  4. Refresh your browser"
    
    echo -e "\n${BLUE}Documentation:${NC}"
    echo "  • Theme Guide: https://docs.pteroca.com/for-developers/themes/getting-started"
    echo "  • README: $SCRIPT_DIR/README.md"
    
    echo ""
}

# Main installation flow
main() {
    print_header
    
    # Check permissions
    check_permissions
    
    # Detect or prompt for PteroCA directory
    if ! detect_pteroca_dir; then
        print_warning "Could not auto-detect PteroCA installation"
        if ! prompt_pteroca_dir; then
            print_error "Installation cancelled"
            exit 1
        fi
    fi
    
    # Confirm installation
    echo ""
    print_info "Installation Summary:"
    echo "  • PteroCA Directory: $PTEROCA_DIR"
    echo "  • Theme Package: $SCRIPT_DIR"
    echo ""
    read -p "Proceed with installation? [Y/n]: " confirm
    confirm="${confirm:-Y}"
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_error "Installation cancelled by user"
        exit 0
    fi
    
    echo ""
    
    # Create backup
    create_backup
    
    # Install theme
    install_theme
    
    # Set permissions
    set_permissions
    
    # Clear cache
    clear_cache
    
    # Print summary
    print_summary
}

# Run main function
main "$@"
