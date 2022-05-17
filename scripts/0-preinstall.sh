#!/bin/bash

source .env
source env.sh

print_header "Starting Pre-install"
save ISO "$(curl -4 ifconfig.co/country-iso)"
timedatectl set-ntp true

print_header "Setting up ${ISO} mirrors for faster downloads"
sed -i 's/^#Para/Para/' /etc/pacman.conf
if [[ -f /etc/pacman.d/mirrorlist ]]; then
    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
fi
reflector -a 48 -c ${ISO} -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

print_header "Select your disk to format"
lsblk
read -p "Please enter disk to work on: (example /dev/sda): " DISK
echo "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
read -p "Are you sure you want to continue (Y/N):" FORMAT
case ${FORMAT} in
y | Y | yes | Yes | YES)
    print_header "\nFormatting disk...\n$HR"
    sgdisk -Z ${DISK}
    sgdisk -a 2048 -o ${DISK}
    sgdisk -n 1::+260M --typecode=1:ef00 ${DISK}
    sgdisk -n 2::-0 --typecode=2:8300 ${DISK}

    if [[ ${DISK} =~ "nvme" ]]; then
        EFI_PARTITION="${DISK}p1"
        ROOT_PARTITION="${DISK}p2"
    else
        EFI_PARTITION="${DISK}1"
        ROOT_PARTITION="${DISK}2"
    fi

    save EFI_PARTITION ${EFI_PARTITION}
    save ROOT_PARTITION ${ROOT_PARTITION}

    print_header "Setting up LUKS encryption"
    cryptsetup -y -v --type luks1 luksFormat ${ROOT_PARTITION}

    print_header "Opening LUKS volume"
    save CRYPTROOT_NAME "cryptroot"
    save CRYPTROOT_PATH "/dev/mapper/${CRYPTROOT_NAME}"
    cryptsetup open ${ROOT_PARTITION} ${CRYPTROOT_NAME}

    print_header "Creating filesystem"
    mkfs.fat -F32 ${EFI_PARTITION}
    mkfs.btrfs ${CRYPTROOT_PATH}
    mount ${CRYPTROOT_PATH} /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@snapshots
    btrfs subvolume create /mnt/@log
    btrfs subvolume create /mnt/@cache
    btrfs subvolume create /mnt/@swap
    umount /mnt
    ;;
esac

print_header "Setting up mount points"
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@ ${CRYPTROOT_PATH} /mnt
mkdir -p /mnt/boot/efi
mkdir -p /mnt/{home,swap,.snapshots}
mkdir -p /mnt/var/{log,cache}
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@home ${CRYPTROOT_PATH} /mnt/home
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@log ${CRYPTROOT_PATH} /mnt/var/log
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@cache ${CRYPTROOT_PATH} /mnt/var/cache
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@swap ${CRYPTROOT_PATH} /mnt/swap
mount -o noatime,compress=zstd,space_cache,discard=async,subvol=@snapshots ${CRYPTROOT_PATH} /mnt/.snapshots
mount ${EFI_PARTITION} /mnt/boot/efi

if ! grep -qs '/mnt' /proc/mounts; then
    print_header "!!! ERROR setting up mount points !!!" "!!! Cannot continue with installation !!!"
    reboot_after_delay 10
fi

print_header "Installing base packages"
pacstrap /mnt base linux linux-firmware btrfs-progs git vim --noconfirm --needed

print_header "Generating fstab file"
genfstab -U /mnt >>/mnt/etc/fstab

print_header "Setting up swapfile"
TOTAL_MEM=$(awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo)
SWAPFILE_SIZE=$((${TOTAL_MEM} + 2048))
truncate -s 0 /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile
btrfs property set /mnt/swap/swapfile compression none
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=${SWAPFILE_SIZE} status=progress
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon /mnt/swap/swapfile
echo "/swap/swapfile none swap defaults 0 0" >>/mnt/etc/fstab

print_header "Setting up LUKS keyfile"
dd bs=512 count=4 if=/dev/random of=/mnt/crypto_keyfile.bin iflag=fullblock
chmod 600 /mnt/crypto_keyfile.bin
chmod 600 /mnt/boot/initramfs-linux*

print_header "Adding the LUKS keyfile" "Enter your disk encryption password when prompted"
cryptsetup luksAddKey ${ROOT_PARTITION} /mnt/crypto_keyfile.bin

print_header "Copying Arch-Base scripts to installation"
cp -R ${REPO_DIR} /mnt/
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

print_header "Pre-install complete"
