#!/bin/bash
# Royal-Devlopments Installer
# Usage: bash <(curl -s https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main/installer.sh)

export GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"
SCRIPT_DIR="$(dirname "$(readlink -f "$0")" 2>/dev/null)"

if [ -f "$SCRIPT_DIR/menu/UI.sh" ]; then
    bash "$SCRIPT_DIR/menu/UI.sh"
else
    bash <(curl -s "$GITHUB_RAW/menu/UI.sh")
fi
