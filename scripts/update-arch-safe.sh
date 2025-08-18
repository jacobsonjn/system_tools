#!/bin/bash
set -e
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root.${NC}"
   exit 1
fi
echo -e "${YELLOW}Check https://archlinux.org/news/ for critical updates before proceeding. Continue? [y/N]${NC}"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    exit 0
fi
echo -e "${GREEN}Starting Arch Linux update...${NC}"
pacman -S --needed archlinux-keyring
pacman -Syu
if command -v yay >/dev/null 2>&1; then
    echo -e "${YELLOW}Update AUR packages with yay? [y/N]${NC}"
    read -r aur_response
    if [[ "$aur_response" =~ ^[Yy]$ ]]; then
        sudo -u "$SUDO_USER" yay -Syu
    fi
fi
if ls /etc/*.pacnew >/dev/null 2>&1; then
    echo -e "${RED}Found .pacnew files. Review and merge manually:${NC}"
    ls -l /etc/*.pacnew
    echo -e "${YELLOW}Use 'pacdiff' or 'meld' to merge.${NC}"
fi
pacman -S --needed linux # Adjust for your kernel
if [[ -d /boot/grub ]]; then
    grub-mkconfig -o /boot/grub/grub.cfg
fi
paccache -r
if pacman -Qtdq >/dev/null; then
    pacman -Rns $(pacman -Qtdq)
fi
echo -e "${GREEN}Update completed! Check for reboot if kernel updated.${NC}"
