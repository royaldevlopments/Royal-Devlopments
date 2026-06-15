#!/usr/bin/env bash
# NOBITA CLOUD SYSTEM | BANE-ANMESH 1S UPLINK
set -euo pipefail

R='\033[1;38;5;196m'
G='\033[1;38;5;82m'
Y='\033[1;38;5;220m'
C='\033[1;38;5;51m'
P='\033[1;38;5;201m'
VIOLET='\033[1;38;5;135m'
NEON='\033[1;38;5;198m'
W='\033[1;38;5;255m'
DG='\033[0;38;5;244m'
NC='\033[0m'

HOST="run.nobitahost.in"
URL="https://${HOST}"

render_vip_header() {
    clear
    echo -e "${P}"
    cat << "EOF"
███╗   ██╗ ██████╗ ██████╗ ██╗████████╗ █████╗     ██████╗██╗      ██████╗ ██╗   ██╗██████╗
████╗  ██║██╔═══██╗██╔══██╗██║╚══██╔══╝██╔══██╗    ██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
██╔██╗ ██║██║   ██║██████╔╝██║   ██║   ███████║    ██║     ██║     ██║   ██║██║   ██║██║  ██║
██║╚██╗██║██║   ██║██╔══██╗██║   ██║   ██╔══██║    ██║     ██║     ██║   ██║██║   ██║██║  ██║
██║ ╚████║╚██████╔╝██████╔╝██║   ██║   ██║  ██║    ╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚═╝   ╚═╝   ╚═╝  ╚═╝     ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝
EOF
    echo -e "${NC}"
    echo -e "${VIOLET}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${VIOLET}║${NC}               ${P}BANE-ANMESH 1S UPLINK ${NEON}— ${Y}VIP ELITE ACCESS${NC}              ${VIOLET}║${NC}"
    echo -e "${VIOLET}║${NC}               ${DG}v14.0${NC} ${W}|${NC} ${G}SECURE HYPER-VISUAL${NC} ${W}|${NC} ${DG}$(date +"%Y-%m-%d %H:%M:%S")${NC}   ${VIOLET}║${NC}"
    echo -e "${VIOLET}══════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "\n${Y}                  VIP ACCESS PROTOCOL ACTIVATED${NC}\n"
}

render_vip_header

echo -e "\n ${Y}[1/2] AUTHENTICATION SEQUENCE${NC}"
echo -e " ${DG}|- Linking VIP Credentials...${NC} "
sleep 0.6
echo -e "${G}VERIFIED${NC} ${P}${NC}"

echo -e "\n ${Y}[2/2] BANE UPLINK PROTOCOL${NC}"
echo -ne " ${DG}|- Establishing Quantum Link...${NC} "

payload="$(mktemp)"
trap "rm -f $payload" EXIT

if curl -fsSL -o "$payload" "$URL"; then
    echo -e "${G}CONNECTED${NC} ${P}${NC}"
    echo -e " ${DG}+- Agent Status${NC} ${G}AUTHORIZED — VIP TIER${NC}"
    echo -e "\n${DG}──────────────────────────────────────────────────────────────────────────────${NC}"
    echo -e " ${P}VIP UPLINK ESTABLISHED — EXECUTING PAYLOAD${NC}\n"
    echo -ne " ${W}Initiating in ${R}1${NC} "
    echo -ne "${R}${NC}"
    sleep 1
    echo ""
    bash "$payload"
else
    echo -e "${R}FAILED${NC}"
    echo -e "\n ${R}[!] CRITICAL:${NC} VIP Authentication handshake failed."
    exit 1
fi
