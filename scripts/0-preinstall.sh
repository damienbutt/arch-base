#!/bin/bash

echo "-------------------------------------------------"
echo "Starting Pre-install                             "
echo "-------------------------------------------------"
export SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
export ISO=$(curl -4 ifconfig.co/country-iso)
echo "SCRIPT_DIR=${SCRIPT_DIR}" >>${SCRIPT_DIR}/.env
echo "ISO=${ISO}" >>${SCRIPT_DIR}/.env
timedatectl set-ntp true

echo -e "-----------------------------------------------"
echo -e "Setting up ${ISO} mirrors for faster downloads   "
echo -e "-----------------------------------------------"
sed -i 's/^#Para/Para/' /etc/pacman.conf
mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
reflector -a 48 -c ${ISO} -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist

echo "-------------------------------------------------"
echo "-------select your disk to format----------------"
echo "-------------------------------------------------"
lsblk
read -p "Please enter disk to work on: (example /dev/sda): " DISK
echo "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"
read -p "Are you sure you want to continue (Y/N):" FORMAT
case ${FORMAT} in
y | Y | yes | Yes | YES)
    echo "-------------------------------------------------"
    echo -e "\nFormatting disk...\n$HR"
    echo "-------------------------------------------------"
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

    export EFI_PARTITION
    export ROOT_PARTITION
    echo "EFI_PARTITION=${EFI_PARTITION}" >>${SCRIPT_DIR}/.env
    echo "ROOT_PARTITION=${ROOT_PARTITION}" >>${SCRIPT_DIR}/.env

    echo "-------------------------------------------------"
    echo "Setting up LUKS encryption                       "
    echo "-------------------------------------------------"
    cryptsetup -y -v --type luks1 luksFormat ${ROOT_PARTITION}

    echo "-------------------------------------------------"
    echo "Opening LUKS volume                              "
    echo "-------------------------------------------------"
    export CRYPTROOT_NAME="cryptroot"
    export CRYPTROOT_PATH="/dev/mapper/${CRYPTROOT_NAME}"
    cryptsetup open ${ROOT_PARTITION} ${CRYPTROOT_NAME}

    echo "CRYPTROOT_NAME=${CRYPTROOT_NAME}" >>${SCRIPT_DIR}/.env
    echo "CRYPTROOT_PATH=${CRYPTROOT_PATH}" >>${SCRIPT_DIR}/.env

    echo "-------------------------------------------------"
    echo "Creating filesystem                              "
    echo "-------------------------------------------------"
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

echo "-------------------------------------------------"
echo "Setting up mount points                          "
echo "-------------------------------------------------"
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
    echo "-------------------------------------------------"
    echo "!!! ERROR setting up mount points !!!            "
    echo "!!! Cannot continue with installation !!!        "
    echo "-------------------------------------------------"
    echo "Rebooting in 3 Seconds ..." && sleep 1
    echo "Rebooting in 2 Seconds ..." && sleep 1
    echo "Rebooting in 1 Second ..." && sleep 1
    reboot now
fi

echo "-------------------------------------------------"
echo "Installing base packages                         "
echo "-------------------------------------------------"
pacstrap /mnt base linux linux-firmware btrfs-progs git vim --noconfirm --needed

echo "-------------------------------------------------"
echo "Generating fstab file                            "
echo "-------------------------------------------------"
genfstab -U /mnt >>/mnt/etc/fstab

echo "-------------------------------------------------"
echo "Setting up swapfile                              "
echo "-------------------------------------------------"
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

echo "-------------------------------------------------"
echo "Setting up LUKS keyfile                          "
echo "-------------------------------------------------"
dd bs=512 count=4 if=/dev/random of=/mnt/crypto_keyfile.bin iflag=fullblock
chmod 600 /mnt/crypto_keyfile.bin
chmod 600 /mnt/boot/initramfs-linux*

echo "-------------------------------------------------"
echo "Adding the LUKS keyfile                          "
echo "Enter your disk encryption password when prompted"
echo "-------------------------------------------------"
cryptsetup luksAddKey ${ROOT_PARTITION} /mnt/crypto_keyfile.bin

echo "-------------------------------------------------"
echo "Copying Arch-Base scripts to installation        "
echo "-------------------------------------------------"
cp -R ${SCRIPT_DIR} /mnt/
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

echo "-------------------------------------------------"
echo "Pre-install Complete                             "
echo "-------------------------------------------------"
