#!/bin/bash
# Nobita-Cloud Installer
# Usage: bash <(curl -s https://ptero.nobitahost.in)

export GITHUB_RAW="https://raw.githubusercontent.com/nobita329/Nobita-Cloud/main"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

# Detect if running via curl pipe or locally
if [ -z "$BASH_EXECUTION_STRING" ] && [ -t 0 ]; then
    SCRIPT_MODE="local"
else
    SCRIPT_MODE="remote"
fi

run_script() {
    local script="$1"
    if [ "$SCRIPT_MODE" = "local" ]; then
        bash "$SCRIPT_DIR/$script"
    else
        bash <(curl -s "$GITHUB_RAW/$script")
    fi
}

bash "$SCRIPT_DIR/menu/UI.sh"
