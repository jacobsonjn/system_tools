#!/bin/bash

# Script to update an Arch Linux system
# Run as root or with sudo

# Exit on any error
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}This script must be run as root (use sudo).${NC}"
   exit 1
fi

echo -e "${GREEN}Starting Arch Linux update process...${NC}"

# Step 1: Update the Arch keyring first
echo -e "${YELLOW}Updating archlinux-keyring...${NC}"
pacman -S --needed archlinux-keyring

# Step 2: Sync package database and update system
echo -e "${YELLOW}Updating system packages...${NC}"
pacman -Syyu --noconfirm

# Step 3: Check for AUR updates if yay is installed
if command -v yay >/dev/null 2>&1; then
    echo -e "${YELLOW}Updating AUR packages with yay...${NC}"
    su -c "yay -Syu --noconfirm" $SUDO_USER || echo -e "${RED}AUR update failed. Check manually.${NC}"
else
    echo -e "${YELLOW}yay not found. Skipping AUR updates.${NC}"
fi

# Step 4: Check for .pacnew files
echo -e "${YELLOW}Checking for .pacnew files...${NC}"
if ls /etc/*.pacnew >/dev/null 2>&1; then
    echo -e "${RED}Found .pacnew files. Please review and merge manually:${NC}"
    ls -l /etc/*.pacnew
    echo -e "${YELLOW}Use 'diff' or 'meld' to compare and merge (e.g., sudo diff /etc/file.pacnew /etc/file).${NC}"
else
    echo -e "${GREEN}No .pacnew files found.${NC}"
fi

# Step 5: Ensure kernel is up to date
echo -e "${YELLOW}Checking kernel updates...${NC}"
pacman -S --needed linux linux-lts

# Step 6: Update GRUB configuration if needed
if [[ -d /boot/grub ]]; then
    echo -e "${YELLOW}Updating GRUB configuration...${NC}"
    grub-mkconfig -o /boot/grub/grub.cfg
else
    echo -e "${YELLOW}GRUB not detected. Skipping GRUB update.${NC}"
fi

# Step 7: Clean package cache
echo -e "${YELLOW}Cleaning package cache...${NC}"
pacman -Sc --noconfirm
# Remove orphaned packages
if pacman -Qtdq >/dev/null; then
    pacman -Rns $(pacman -Qtdq) --noconfirm
else
    echo -e "${GREEN}No orphaned packages to remove.${NC}"
fi

# Step 8: Check Arch news (if archnews is installed)
if command -v archnews >/dev/null 2>&1; then
    echo -e "${YELLOW}Checking Arch Linux news...${NC}"
    archnews
else
    echo -e "${YELLOW}archnews not installed. Visit https://archlinux.org/news/ for updates.${NC}"
fi

# Step 9: Check if reboot is required
if [[ -f /var/run/reboot-required ]]; then
    echo -e "${RED}Reboot required to apply updates. Run 'sudo reboot' when ready.${NC}"
else
    echo -e "${GREEN}No reboot required.${NC}"
fi

echo -e "${GREEN}Arch Linux update process completed!${NC}"