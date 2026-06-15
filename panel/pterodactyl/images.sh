#!/bin/bash

CYAN='\033[38;5;51m'; PURPLE='\033[38;5;141m'; GRAY='\033[38;5;242m'
WHITE='\033[1;38;5;255m'; GREEN='\033[38;5;82m'; RED='\033[38;5;196m'; GOLD='\033[38;5;220m'; NC='\033[0m'

DRIVE="https://drive.google.com/file/d"

declare -A IMGS
IMGS[1]="Mockup|1kbpVtSaJPRBMUhVBQ_iUxji0Fjwx9gMO"
IMGS[2]="Dashboard|1q1RKMnDEXumSZ6JKM9CLA9cLyR0VQAew"
IMGS[3]="Server List|1PYSRAHER7zIewMHHvtU3uEyTsuvzDu7q"
IMGS[4]="Server Console|1NyLxpCRwmoxzWrYkLuezW6FrO_N28DXE"
IMGS[5]="File Manager|1MD2QFIzenO-sCjziSBgkx31v20-nxLVD"
IMGS[6]="Database Manager|1VF1dgbthbtFEhP7q8n8h4KiLPBmJwi75"
IMGS[7]="Screenshot 6|1kmRV9NCZHwIhhQBMHuL7ZjfW_EYfi1VR"
IMGS[8]="Screenshot 7|1714vJVhtVo1-DGnWRjsYUbLR_7BkcLF7"
IMGS[9]="Screenshot 8|1LyM5UOFfSIj7c-ZQzpvW5nbSzQPOfZT4"
IMGS[10]="Screenshot 9|1GodbRQw2L6pI0-44haXBbjRZPddHd2k9"
IMGS[11]="Screenshot 10|1V04yiwwH4pztDpgitrsGwcVRd1We2QdL"
IMGS[12]="Screenshot 11|1qFFUnlr-oG0IwoJtSOGASDR_Ut2Ezhm3"

while true; do
    clear
    echo -e "${PURPLE}┌──────────────────────────────────────────────────────────┐${NC}"
    echo -e "${PURPLE}│${NC}  ${CYAN}PTERODACTYL SCREENSHOTS${NC}               ${GRAY}$(date +"%H:%M")${NC}  ${PURPLE}│${NC}"
    echo -e "${PURPLE}└──────────────────────────────────────────────────────────┘${NC}"
    echo ""
    echo -e "  ${WHITE}Select:${NC}"
    echo -e "  ${GREEN}[1]${NC} Mockup    ${GREEN}[2]${NC} Dashboard    ${GREEN}[3]${NC} Server List"
    echo -e "  ${GREEN}[4]${NC} Console   ${GREEN}[5]${NC} File Manager ${GREEN}[6]${NC} DB Manager"
    echo -e "  ${GREEN}[7]${NC} All Links"
    echo -e "  ${GREEN}[8]${NC} Custom Link"
    echo -e "  ${RED}[0]${NC} Back"
    echo ""
    echo -ne "  ${CYAN}Select [0-8]:${NC} "
    read opt

    case $opt in
        [1-6])
            IFS='|' read -r label fid <<< "${IMGS[$opt]}"
            echo -e "\n  ${GOLD}━━━ $label ━━━${NC}"
            echo -e "\n  ${CYAN}$DRIVE/$fid/view${NC}"
            ;;
        7)
            echo ""
            for k in $(printf '%s\n' "${!IMGS[@]}" | sort -n); do
                IFS='|' read -r label fid <<< "${IMGS[$k]}"
                echo -e "  ${GREEN}[$k]${NC} $DRIVE/$fid/view  ${GRAY}$label${NC}"
            done
            ;;
        8)
            echo ""; echo -ne "  ${CYAN}Google Drive file ID:${NC} "; read u
            [ -n "$u" ] && echo -e "\n  ${CYAN}$DRIVE/$u/view${NC}"
            ;;
        0) clear; exit 0 ;;
        *) echo -e "  ${RED}Invalid${NC}"; sleep 1; continue ;;
    esac
    echo ""
    read -p "  Press Enter..."
done
