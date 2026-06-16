#!/usr/bin/env bash
# ==========================================================
# ROYAL CLOUD SYSTEM | OBSIDIAN UPLINK
# ==========================================================
set -euo pipefail

# --- ROYAL THEME ---
R='\033[1;38;5;196m'
G='\033[1;38;5;82m'
Y='\033[1;38;5;220m'
C='\033[1;38;5;51m'
P='\033[1;38;5;141m'
VIOLET='\033[1;38;5;135m'
NEON='\033[1;38;5;198m'
W='\033[1;38;5;255m'
DG='\033[0;38;5;244m'
NC='\033[0m'

# --- CONFIG ---
GITHUB_RAW="https://raw.githubusercontent.com/royaldevlopments/Royal-Devlopments/main"
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
HOSTNAME="$(hostname)"

# --- VIP HEADER ---
render_header() {
    clear
    echo -e "${C}"
    cat << "EOF"
██████╗  ██████╗ ██╗   ██╗ █████╗ ██╗         ██████╗██╗      ██████╗ ██╗   ██╗██████╗
██╔══██╗██╔═══██╗╚██╗ ██╔╝██╔══██╗██║        ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
██████╔╝██║   ██║ ╚████╔╝ ███████║██║        ██║     ██║     ██║   ██║██║   ██║██║  ██║
██╔══██╗██║   ██║  ╚██╔╝  ██╔══██║██║        ██║     ██║     ██║   ██║██║   ██║██║  ██║
██║  ██║╚██████╔╝   ██║   ██║  ██║███████╗    ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
╚═╝  ╚═╝ ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚══════╝     ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝
EOF
    echo -e "${NC}"

    echo -e "${VIOLET}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${VIOLET}║${NC}               ${P}✦  ROYAL CLOUD UPLINK ${NEON}— ${Y}OBSIDIAN ENTERPRISE${NC}               ${VIOLET}║${NC}"
    echo -e "${VIOLET}║${NC}               ${DG}v1.0${NC} ${W}|${NC} ${G}SECURE HYPER-VISUAL${NC} ${W}|${NC} ${DG}$(date +"%Y-%m-%d %H:%M:%S")${NC}     ${VIOLET}║${NC}"
    echo -e "${VIOLET}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"

    echo -e "\n${Y}                  ✦✦✦ UPLINK PROTOCOL ACTIVATED ✦✦✦${NC}\n"
}

render_header

# --- NETWORK DIAGNOSTICS ---
echo -e " ${C}◉ SYSTEM DIAGNOSTICS${NC}"
echo -e " ${DG}├─ Hostname          :${NC} ${W}$HOSTNAME${NC}"
echo -e " ${DG}├─ Public IP         :${NC} ${W}$IP${NC}"
echo -e " ${DG}├─ OS                :${NC} ${W}$(cat /etc/os-release 2>/dev/null | grep -w PRETTY_NAME | cut -d= -f2 | tr -d '"')${NC}"
echo -e " ${DG}├─ Kernel            :${NC} ${W}$(uname -r)${NC}"
echo -e " ${DG}├─ Uplink Source     :${NC} ${W}GitHub Raw${NC}"
echo -e " ${DG}└─ Security          :${NC} ${G}SSL/TLS ${P}✦${NC}"
echo -e "${DG}──────────────────────────────────────────────────────────────────────────────${NC}"

# --- CONNECTION SEQUENCE ---
echo -e "\n ${Y}[1/2] CONNECTION SEQUENCE${NC}"
echo -ne " ${DG}├─ Resolving Uplink...${NC} "

if command -v curl &>/dev/null; then
    echo -e "${G}RESOLVED${NC} ${P}✓${NC}"
else
    echo -e "${R}FAILED${NC}"
    echo -e " ${DG}└─ Error:${NC} ${R}curl not found${NC}"
    exit 1
fi

echo -e "\n ${Y}[2/2] PAYLOAD ACQUISITION${NC}"
echo -ne " ${DG}├─ Fetching Installer...${NC} "

payload="$(mktemp)"
trap "rm -f $payload" EXIT

if curl -fsSL -A "Royal-Uplink-Agent" -o "$payload" "$GITHUB_RAW/installer.sh"; then
    echo -e "${G}ACQUIRED${NC} ${P}✦${NC}"
    echo -e " ${DG}└─ Package          :${NC} ${G}Royal Cloud Installer${NC}"

    echo -e "\n${DG}──────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}✦✦✦ UPLINK ESTABLISHED — EXECUTING PAYLOAD IN 1 SECOND ✦✦✦${NC}\n"

    echo -ne " ${W}Initiating in ${R}1${NC} "
    echo -ne "${R}●${NC}"
    sleep 1
    echo -e "\n"

    bash "$payload"
else
    echo -e "${R}FAILED${NC}"
    echo -e " ${DG}└─ Error:${NC} ${R}Could not reach GitHub Raw${NC}"
    echo -e "\n ${R}[!] CRITICAL:${NC} Uplink handshake failed. Check internet connection."
    exit 1
fi
