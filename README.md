### Introduction

This is my installer for Arch Linux. It sets up a BTRFS system with encrypted `/boot` and full snapper support (both snapshotting and rollback work!). It also includes various system hardening configurations.

The script is based on [Arch-Setup-Script](https://github.com/TommyTran732/Arch-Setup-Script), which is based on [easy-arch](https://github.com/classy-giraffe/easy-arch), which diverges significantly from the original easy-arch project and does not follow its development. My fork does not follow the development of Arch-Setup-Script either. It is exactly the same script as Arch-Setup-Script (even most of the README is the same) with many things removed, added or changed to make it better for (my) daily use and note down issues I had to fix. Many, and I mean MANY, things still need to be set up after installation, but it works really well after that. You should probably use "Arch-Setup-Script" and not my version. My version is less secure (because the "Arch-Setup-Script" is extremely secure) and more optimised for my use.

---

I also made all the files they linked in the script local. I'm not a fan of fetching files for things like installing configs. They are also changed to work better for me.

Files:

```

https://raw.githubusercontent.com/secureblue/secureblue/live/files/system/etc/modprobe.d/blacklist.conf

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/sysctl.d/99-server.conf

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/sysctl.d/99-workstation.conf

https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/chrony.conf

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/sysconfig/chronyd

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/ssh/ssh_config.d/10-custom.conf

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/ssh/sshd_config.d/10-custom.conf

https://raw.githubusercontent.com/GrapheneOS/infrastructure/main/systemd/system/sshd.service.d/local.conf

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/security/limits.d/30-disable-coredump.conf

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/systemd/coredump.conf.d/disable.conf

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/systemd/user/org.gnome.Shell%40wayland.service.d/override.conf

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/locks/automount-disable

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/locks/privacy

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/adw-gtk3-dark

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/automount-disable

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/button-layout

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/prefer-dark

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/privacy

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/dconf/db/local.d/touchpad

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/systemd/zram-generator.conf

https://raw.githubusercontent.com/TommyTran732/Arch-Setup-Script/main/etc/unbound/unbound.conf

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/NetworkManager/conf.d/00-macrandomize.conf

https://raw.githubusercontent.com/TommyTran732/Linux-Setup-Scripts/main/etc/NetworkManager/conf.d/01-transient-hostname.conf

https://gitlab.com/divested/brace/-/raw/master/brace/usr/lib/systemd/system/NetworkManager.service.d/99-brace.conf

```

Sources:

Apache-2.0 license:

```

https://github.com/secureblue/secureblue

https://github.com/tommytran732/Linux-Setup-Scripts

https://github.com/tommytran732/Arch-Setup-Script

```

MIT:

```

https://github.com/GrapheneOS/infrastructure

```

GNU AGPLv3:

```

https://gitlab.com/divested/brace

```

---

### How to use it?
1. Download an Arch Linux ISO from [here](https://archlinux.org/download/)
2. Flash the ISO onto an [USB Flash Drive](https://wiki.archlinux.org/index.php/USB_flash_installation_medium).
3. Boot the live environment.
4. Connect to the internet.
5. Make sure your are in /root. Check with "pwd"
6. `git clone https://github.com/CatWithCode/Arch-Linux-BTRFS-CWC/`
7. `cd Arch-Linux-BTRFS-CWC`
8. `chmod u+x ./install.sh`
9. `./install.sh`
10. I would recommend installing the normal Kernel / Zen Kernel. The hardened Kernel is nice, but breaks some things you would not expect (Install the normal/Zen Kernel, reboot, uninstall the hardened Kernel, reboot).
---

### Snapper behavior
The partition layout I use allows us to replicate the behavior found in openSUSE 🦎
1. Snapper rollback <number> works! You will no longer need to manually rollback from a live USB like you would with the @ and @home layout suggested in the Arch Wiki.
2. You can boot into a readonly snapshot! GDM and other services will start normally so you can get in and verify that everything works before rolling back.
3. Automatic snapshots on pacman install/update/remove operations
4. Directories such as `/boot`, `/boot/efi`, `/var/log`, `/var/crash`, `/var/tmp`, `/var/spool`, /`var/lib/libvirt/images` are excluded from the snapshots as they either should be persistent or are just temporary files. `/cryptkey` is excluded as we do not want the encryption key to be included in the snapshots, which could be sent to another device as a backup.
5. GRUB will boot into the default BTRFS snapshot set by snapper. Like on openSUSE, your running system will always be a read-write snapshot in `@/.snapshots/X/snapshot`. 

---

### Security considerations

Since this is an encrypted `/boot` setup, GRUB will prompt you for your encryption password and decrypt the drive so that it can access the kernel and initramfs. I am unaware of any way to make it use a TPM + PIN setup.

The implication of this is that an attacker can change your secure boot state with a programmer, replace your grubx64.efi and it will not be detected until its too late.

This type of attack can theoratically be solved by splitting /boot out to a seperate partition and encrypt the root filesystem separately. The key protector for the root filesystem can then be sealed to a TPM with PCR 0+1+2+3+5+7+14. It is a bit more complicated to set up so my installer does not support this (yet!).

---

### How to fix GRUB after an BIOS Update:

I know a lot of people know this and it seems obvious to them, but fixing boot is often very scary and I want to make sure I never get it wrong. This also happens with normal Arch installs, but this is written specifically for THIS type of installation:

### How to fix it?
1. Download an Arch Linux ISO from [here](https://archlinux.org/download/)
2. Flash the ISO onto an [USB Flash Drive](https://wiki.archlinux.org/index.php/USB_flash_installation_medium).
3. Boot the live environment.
4. Connect to the internet.
5. Now you need to chroot into your install. To make this work do the following:  
    1. fdisk -l
    2. Find your drive (For example: "/dev/nvme0n1")
    3. It will have two partitions: "/dev/nvme0n1p1" for "/boot/EFI" or "/boot/efi" (FAT32 dose not care) and "/dev/nvme0n1p2" and for the root in my case. (You will not be able to access any files at home because of the btrfs mappings).
    4. Decryption your root with `cryptsetup luksOpen /dev/nvme0n1p2 openRoot`.
    5. Now you can mount it with `mount /dev/mapper/openRoot /mnt`.
    6. Now mount boot inside of /boot/EFI or /boot/efi `mount /dev/nvme0n1p1 /mnt/boot/EFI` or `mount /dev/nvme0n1p1 /mnt/boot/efi`.
    7. `git clone https://github.com/CatWithCode/Arch-Linux-BTRFS-CWC/`
    7. `cd Arch-Linux-BTRFS-CWC`
    8. Move `update_grub_live.sh` to somewhere inside the mounted root. For this example `/mnt/usr/share/icons/`
    9. Now chroot into your mounted Install: `chroot /mnt`
6. Make the Script executable with `chmod +x /mnt/usr/share/icons/update_grub_live.sh`.
7. Execute: `/mnt/usr/share/icons/update_grub_live.sh`.
8. If done correctly, this should fix everything with GRUB and UEFI. One way to avoid this after some BIOS updates is to do the BIOS-Update in Linux and then run the Script before rebooting, but this is rarely supported.

If grub is realy fucked it can somtimes work to change the update_grub_live.sh to point to boot and then to /boot/EFI or /boot/efi. BUT this must be fixed by the user later in the OS with a fresh grub install to /boot/EFI or /boot/efi! Else it causes confusion when fixing boot at some point later!

---

### Fixing Broken SNAPPER function:

This happened to me on my first install, but unfortunately I have never been able to reproduce it since. Everything worked BUT the final install would not take snapshots (even after reinstalling). I had to unmount all mappings, remove the config, create the config, remount the mappings, reboot and it worked. No matter if in a VM, on real hardware or even on the hardware it happened on, I can no longer reproduce it, even though the scripts are the same. If I ever run into this problem again, I will document it, but I cannot figure out how to fix it without knowing what it was in the first place. SORRY!
