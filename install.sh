#!/usr/bin/env bash

# Cleaning the TTY.
clear

# Exit on STDERR.
set -e

kernel_options() {
    echo "Which kernel flavor would you want?"
    echo "[1] Stable — Vanilla Linux kernel and modules, with a few patches applied."
    echo "[2] Hardened — A security-focused Linux kernel applying a set of hardening patches to mitigate kernel and userspace exploits. It also enables more upstream kernel hardening features than Stable."
    echo "[3] Longterm — Long-term support (LTS) Linux kernel and modules."
    echo "[4] Zen Kernel — Result of a collaborative effort of kernel hackers to provide the best Linux kernel possible for everyday systems. Some more details can be found on https://liquorix.net (which provides kernel binaries based on Zen for Debian)."
    echo ""
    read choice
    case $choice in
        1 ) KERNEL=linux
            echo "You have selected to install the vanilla Linux kernel."
            echo ""
            ;;
        2 ) KERNEL=linux-hardened
            echo "You have selected to install the hardened kernel."
            echo ""
            ;;
        3 ) KERNEL=linux-lts
            echo "You have selected to install the long term kernel."
            echo ""
            ;;
        4 ) KERNEL=linux-zen
            echo "You have selected to install the Zen kernel."
            echo ""
            ;;
        * ) echo "You did not enter a valid selection."
            kernel_options
    esac
}

cpu_options() {
    echo "Which brand is your CPU?"
    echo "[1] Intel"
    echo "[2] AMD"
    echo ""
    read choice
    case $choice in
        1 ) CPU=intel-ucode
            echo "Intel microcode will be installed."
            echo ""
            ;;
        2 ) CPU=amd-ucode
            echo "AMD microcode will be installed."
            echo ""
            ;;
        * ) echo "You did not enter a valid selection."
            cpu_options
    esac
}

# Selecting the target for the installation.
PS3="Select the disk where Arch Linux is going to be installed: "
select ENTRY in $(lsblk -dpnoNAME|grep -P "/dev/sd|nvme");
do
    DISK=$ENTRY
    echo "Installing Arch Linux on $DISK."
    break
done

# Deleting old partition scheme.
read -r -p "This will delete the current partition table on $DISK. Do you agree [y/N]? " response
response=${response,,}
if [[ "$response" =~ ^(yes|y)$ ]]
then
    wipefs -af $DISK &>/dev/null
    sgdisk -Zo $DISK &>/dev/null
else
    echo "Quitting."
    exit
fi

# Creating a new partition scheme.
echo "Creating new partition scheme on $DISK."
parted -s $DISK \
    mklabel gpt \
    mkpart ESP fat32 1MiB 301MiB \
    mkpart cryptroot 301MiB 100% \

ESP="/dev/disk/by-partlabel/ESP"
Cryptroot="/dev/disk/by-partlabel/cryptroot"

# Informing the Kernel of the changes.
echo "Informing the Kernel about the disk changes."
partprobe $DISK

# Formatting the ESP as FAT32.
echo "Formatting the EFI Partition as FAT32."
mkfs.fat -F 32 $ESP &>/dev/null

# Creating a LUKS Container for the root partition.
echo "Creating LUKS Container for the root partition."
cryptsetup --type luks1 luksFormat $Cryptroot
echo "Opening the newly created LUKS Container."
cryptsetup open $Cryptroot cryptroot
BTRFS="/dev/mapper/cryptroot"

# Formatting the LUKS Container as BTRFS.
echo "Formatting the LUKS container as BTRFS."
mkfs.btrfs $BTRFS &>/dev/null
mount $BTRFS /mnt

# Creating BTRFS subvolumes.
echo "Creating BTRFS subvolumes."
btrfs su cr /mnt/@ &>/dev/null
btrfs su cr /mnt/@boot &>/dev/null
btrfs su cr /mnt/@home &>/dev/null
btrfs su cr /mnt/@snapshots &>/dev/null
btrfs su cr /mnt/@var &>/dev/null

# Mounting the newly created subvolumes.
umount /mnt
echo "Mounting the newly created subvolumes."
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@ $BTRFS /mnt
mkdir -p /mnt/{home,.snapshots,var,boot}
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@boot $BTRFS /mnt/boot
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@home $BTRFS /mnt/home
mount -o ssd,noatime,space_cache,compress=zstd,subvol=@snapshots $BTRFS /mnt/.snapshots
mount -o ssd,noatime,space_cache,nodatacow,subvol=@var $BTRFS /mnt/var/
mkdir -p /mnt/boot/efi
mount $ESP /mnt/boot/efi

kernel_options
cpu_options

# Pacstrap (setting up a base sytem onto the new root).
echo "Installing the base system (it may take a while)."
pacstrap /mnt base base-devel ${KERNEL} ${KERNEL}-headers ${CPU} linux-firmware btrfs-progs grub grub-btrfs efibootmgr sudo networkmanager wpa_supplicant apparmor &>/dev/null nano gnome-shell gdm gnome-control-center gnome-terminal gnome-software gnome-tweaks nautilus flatpak xdg-user-dirs firewalld

# Generating /etc/fstab.
echo "Generating a new fstab."
genfstab -U /mnt >> /mnt/etc/fstab

# Setting hostname.
read -r -p "Please enter the hostname: " hostname
echo $hostname > /mnt/etc/hostname

# Setting up locales.
read -r -p "Please insert the locale you use in this format (xx_XX): " locale
echo "$locale.UTF-8 UTF-8"  > /mnt/etc/locale.gen
echo "LANG=$locale.UTF-8" > /mnt/etc/locale.conf

# Setting up keyboard layout.
read -r -p "Please insert the keyboard layout you use: " kblayout
echo "KEYMAP=$kblayout" > /mnt/etc/vconsole.conf

# Setting hosts file.
echo "Setting hosts file."
cat > /mnt/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   $hostname.localdomain   $hostname
EOF

# Configuring /etc/mkinitcpio.conf
echo "Configuring /etc/mkinitcpio for ZSTD compression and LUKS hook."
sed -i -e 's,#COMPRESSION="zstd",COMPRESSION="zstd",g' /mnt/etc/mkinitcpio.conf
sed -i -e 's,modconf block filesystems keyboard,keyboard keymap modconf block encrypt filesystems,g' /mnt/etc/mkinitcpio.conf

# Enabling LUKS in GRUB and setting the UUID of the LUKS container.
UUID=$(blkid $Cryptroot | cut -f2 -d'"')
sed -i 's/#\(GRUB_ENABLE_CRYPTODISK=y\)/\1/' /mnt/etc/default/grub
sed -i -e "s,quiet,quiet cryptdevice=UUID=$UUID:cryptroot root=$BTRFS,g" /mnt/etc/default/grub
sed -i -e "s#root=/dev/mapper/cryptroot#oot=/dev/mapper/cryptroot lsm=lockdown,yama,apparmor,bpf#g" /mnt/etc/default/grub
echo "" >> /mnt/etc/default/grub
echo "# Booting with BTRFS subvolume" >> /mnt/etc/default/grub
echo "GRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION=true" >> /mnt/etc/default/grub

# Configuring the system.    
arch-chroot /mnt /bin/bash -e <<EOF
    
    # Setting up clock.
    hwclock --systohc

    # Generating locales.
    echo "Generating locales."
    locale-gen &>/dev/null

    # Generating a new initramfs.
    echo "Creating a new initramfs."
    mkinitcpio -P &>/dev/null

    # Snapper configuration
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots &>/dev/null
    mkdir /.snapshots
    mount -a
    chmod 750 /.snapshots

    # Installing GRUB.
    echo "Installing GRUB on /boot."
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB &>/dev/null

    # Creating grub config file.
    echo "Creating GRUB config file."
    grub-mkconfig -o /boot/grub/grub.cfg &>/dev/null

EOF

# Setting root password.
echo "Setting root password."
arch-chroot /mnt /bin/passwd

# Enabling auto-trimming service.
echo "Enabling auto-trimming."
systemctl enable fstrim.timer --root=/mnt &>/dev/null

# Enabling NetworkManager service.
echo "Enabling NetworkManager."
systemctl enable NetworkManager --root=/mnt &>/dev/null

# Enabling GDM
systemctl enable gdm --root=/mnt &>/dev/null

# Enabling AppArmor
systemctl enable apparmor --root=/mnt &>/dev/null

# Enabling Firewalld
systemctl enable firewalld --root=/mnt &>/dev/null

# Setting umask to 077
sed -i 's/022/077/g' /etc/profile
echo "" >> /etc/bash.bashrc
echo "umask 077" >> /etc/bash.bashrc

# Enabling Snapper automatic snapshots.
echo "Enabling Snapper."
systemctl enable snapper-timeline.timer --root=/mnt &>/dev/null
systemctl enable snapper-cleanup.timer --root=/mnt &>/dev/null

echo "Done, you may now wish to reboot (further changes can be done by chrooting into /mnt)."
exit
