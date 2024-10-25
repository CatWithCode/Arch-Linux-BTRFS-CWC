#!/bin/bash
# UPDATER with FIXES:

# Update (YES NEEDED, BECAUSE SYSTEM):
sudo pacman -Syu

# Chipset-Fix:
# HERE YOUR FIXES!
cd '/home/YOUR_USER/nct6687d/'
sudo make dkms/install

sleep 10

# MAKING SURE BOOT WORKS:
sudo bash /home/YOUR_USER/update_grub_live.sh
