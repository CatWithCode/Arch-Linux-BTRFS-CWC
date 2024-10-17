### STILL WRITING AND EDITING! NOT DONE!

### Introduction

This is my installer for Arch Linux. It sets up a BTRFS system with encrypted `/boot` and full snapper support (both snapshotting and rollback work!). It also includes various system hardening configurations.

The script is based on [Arch-Setup-Script](https://github.com/TommyTran732/Arch-Setup-Script) which is based on [easy-arch](https://github.com/classy-giraffe/easy-arch) which diverges substantially from the original easy-arch project does not follow its development. My fork dose, again, not follow Arch-Setup-Script development. It is just the same script as Arch-Setup-Script with many parts removed or changed to make it better for (my) daily use. Many, and I mean MANY things still need setup after installation but it works realy good after that.

### How to use it?
1. Download an Arch Linux ISO from [here](https://archlinux.org/download/)
2. Flash the ISO onto an [USB Flash Drive](https://wiki.archlinux.org/index.php/USB_flash_installation_medium).
3. Boot the live environment.
4. Connect to the internet.
5. `git clone https://github.com/tommytran732/Arch-Setup-Script/`
6. `cd Arch-Setup-Script`
7. `chmod u+x ./install.sh`
8. `./install.sh`

### Snapper behavior
The partition layout I use allows us to replicate the behavior found in openSUSE 🦎
1. Snapper rollback <number> works! You will no longer need to manually rollback from a live USB like you would with the @ and @home layout suggested in the Arch Wiki.
2. You can boot into a readonly snapshot! GDM and other services will start normally so you can get in and verify that everything works before rolling back.
3. Automatic snapshots on pacman install/update/remove operations
4. Directories such as `/boot`, `/boot/efi`, `/var/log`, `/var/crash`, `/var/tmp`, `/var/spool`, /`var/lib/libvirt/images` are excluded from the snapshots as they either should be persistent or are just temporary files. `/cryptkey` is excluded as we do not want the encryption key to be included in the snapshots, which could be sent to another device as a backup.
5. GRUB will boot into the default BTRFS snapshot set by snapper. Like on openSUSE, your running system will always be a read-write snapshot in `@/.snapshots/X/snapshot`. 

### Security considerations

Since this is an encrypted `/boot` setup, GRUB will prompt you for your encryption password and decrypt the drive so that it can access the kernel and initramfs. I am unaware of any way to make it use a TPM + PIN setup.

The implication of this is that an attacker can change your secure boot state with a programmer, replace your grubx64.efi and it will not be detected until its too late.

This type of attack can theoratically be solved by splitting /boot out to a seperate partition and encrypt the root filesystem separately. The key protector for the root filesystem can then be sealed to a TPM with PCR 0+1+2+3+5+7+14. It is a bit more complicated to set up so my installer does not support this (yet!).

### How to fix an Arch Linux Install with BTRFS and full disk encryption

This expects to that Arch was Installed with this scropt (https://github.com/TommyTran732/Arch-Setup-Script). I foked from it for my fix Repo so it is clear that "TommyTran732 - Tommy" did all the work! I just note down how I fixed my Install after a BIOS update.

I know many people know this and it seems to be obvious to them but fixing boot is often very scary and i want to make sure i dont do it wrong ever.

### How to fix it?
1. Download an Arch Linux ISO from [here](https://archlinux.org/download/)
2. Flash the ISO onto an [USB Flash Drive](https://wiki.archlinux.org/index.php/USB_flash_installation_medium).
3. Boot the live environment.
4. Connect to the internet.
5. Now you need to chroot into your install. To make this work do the following:
    
    1. fdisk -l
    2. Find your drive (For example: "/dev/nvme0n1")
    3. It will have two partitions: "/dev/nvme0n1p1" for "/boot" and "/dev/nvme0n1p2" and for the rest. You will not be able to acces any files in home because of the btrfs mappings.
    4. Now get the "update_grub.sh" file from this or "TommyTran732" Reposetory.
