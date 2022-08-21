#!/bin/bash

set -u

abort() {
    printf "%s\n" "$@" >&2
    exit 1
}

# Fail fast with a concise message when not using bash
# Single brackets are needed here for POSIX compatibility
if [ -z "${BASH_VERSION:-}" ]; then
    abort "Bash is required to interpret this script."
fi

# First check OS.
OS="$(uname)"
if [[ "${OS}" != "Linux" ]]; then
    abort "Arch Linux can only be installed on Linux! Duh."
fi

# String Formatters
if [[ -t 1 ]]; then
    tty_escape() { printf "\033[%sm" "$1"; }
else
    tty_escape() { :; }
fi

tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

# Check cURL is installed
if ! command -v curl &>/dev/null; then
    abort "$(
        cat <<EOABORT
You must install cURL before running this script. Run the following command:
  ${tty_underline}pacman -S curl${tty_reset}
EOABORT
    )"
fi

# Download dependencies
curl -fsSL https://raw.githubusercontent.com/damienbutt/arch-base/HEAD/scripts/arch-chroot-setup.sh >arch-chroot-setup.sh
curl -fsSL https://raw.githubusercontent.com/damienbutt/arch-base/HEAD/scripts/arch-chroot-user.sh >arch-chroot-user.sh
curl -fsSL https://raw.githubusercontent.com/damienbutt/arch-base/HEAD/scripts/arch-chroot-postsetup.sh >arch-chroot-postsetup.sh
chmod +x *.sh

curl -fsSL https://raw.githubusercontent.com/damienbutt/arch-base/HEAD/scripts/install-arch-base-utils.sh >install-arch-base-utils.sh
curl -fsSL https://raw.githubusercontent.com/damienbutt/arch-base/HEAD/scripts/.bashrc >.bashrc
source install-arch-base-utils.sh

# Start the actual installation
clear
ohai "Starting Arch-Base installation"

SCRIPT_DIR="$(cd -- "$(dirname -- "")" &>/dev/null && pwd)"

# Update the system clock
ohai "Setting up NTP"
timedatectl set-ntp true

# Setup mirrors
ohai "Detecting your country"
save_var ISO "$(curl -s ifconfig.co/country-iso)"

ohai "Setting up ${ISO} mirrors for faster downloads"
if [[ -f /etc/pacman.d/mirrorlist ]]; then
    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
fi
reflector -a 48 -c ${ISO} -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist &>/dev/null
pacman -Syyy --noconfirm &>/dev/null

# Enable parallel downloads
sed -i 's/^#Para/Para/' /etc/pacman.conf

# Parition and format the disk
clear
ohai "Select the disk to format"
lsblk

echo
for (( ; ; )); do
    read -p "Please enter disk to install Arch-Base on: (example /dev/sda): " DISK

    if ! [ -b ${DISK} ]; then
        echo "Disk ${DISK} does not exist. Please try again..."
        continue
    fi

    break
done

echo
ohai "Disk ${DISK} selected"
warn "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"

echo
read -p "Are you sure you want to continue (y/N):" FORMAT
case ${FORMAT} in
y | Y | yes | Yes | YES)
    echo
    ohai "Partitioning the disk"
    sgdisk -Z ${DISK}
    sgdisk -a 2048 -o ${DISK}
    sgdisk -n 1::+260M --typecode=1:ef00 ${DISK}
    sgdisk -n 2::-0 --typecode=2:8300 ${DISK}

    if [[ ${DISK} =~ "nvme" ]]; then
        save_var EFI_PARTITION "${DISK}p1"
        save_var ROOT_PARTITION "${DISK}p2"
    else
        save_var EFI_PARTITION "${DISK}1"
        save_var ROOT_PARTITION "${DISK}2"
    fi

    ohai "Setting up LUKS encryption"
    cryptsetup -y -v --type luks1 luksFormat ${ROOT_PARTITION}

    if [ $? -ne 0 ]; then
        abort "Error creating LUKS conatiner. Aborting..."
    fi

    echo
    ohai "Opening LUKS volume"
    save_var CRYPTROOT_NAME "cryptroot"
    save_var CRYPTROOT_PATH "/dev/mapper/${CRYPTROOT_NAME}"
    cryptsetup open ${ROOT_PARTITION} ${CRYPTROOT_NAME}

    echo
    ohai "Formatting the partitions"
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
*)
    echo
    abort "Aboring installation..."
    ;;
esac

# Mount the filesystems
ohai "Mounting the filesystems"
mount -o noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@ ${CRYPTROOT_PATH} /mnt
mkdir -p /mnt/boot/efi
mkdir -p /mnt/{home,swap,.snapshots}
mkdir -p /mnt/var/{log,cache}
mount -o noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@home ${CRYPTROOT_PATH} /mnt/home
mount -o noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@log ${CRYPTROOT_PATH} /mnt/var/log
mount -o noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@cache ${CRYPTROOT_PATH} /mnt/var/cache
mount -o noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@swap ${CRYPTROOT_PATH} /mnt/swap
mount -o noatime,compress=zstd,space_cache=v2,ssd,discard=async,subvol=@snapshots ${CRYPTROOT_PATH} /mnt/.snapshots
mount ${EFI_PARTITION} /mnt/boot/efi

if ! mounts_success; then
    abort "An error occurred while mounting the filesystems. Aborting..."
fi

# Install essential packages
ohai "Installing essential packages"
pacstrap /mnt base linux linux-firmware btrfs-progs git vim --noconfirm --needed

#Fstab
ohai "Generating fstab"
genfstab -U /mnt >>/mnt/etc/fstab

# Setup swapfile
ohai "Creating swapfile"
save_var TOTAL_MEM "$(awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo)"
save_var SWAPFILE_SIZE "$((${TOTAL_MEM} + 2048))"
chattr +C /mnt/swap/
truncate -s 0 /mnt/swap/swapfile
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=${SWAPFILE_SIZE} status=progress
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon /mnt/swap/swapfile
echo "/swap/swapfile none swap defaults 0 0" >>/mnt/etc/fstab

# Setup LUKS keyfile
ohai "Setting up LUKS keyfile"
dd bs=512 count=4 if=/dev/random of=/mnt/crypto_keyfile.bin iflag=fullblock &>/dev/null
chmod 600 /mnt/crypto_keyfile.bin
chmod 600 /mnt/boot/initramfs-linux*

ohai "Adding the LUKS keyfile" "Enter your disk encryption password when prompted"
cryptsetup luksAddKey ${ROOT_PARTITION} /mnt/crypto_keyfile.bin

echo
ohai "Preparing for arch-chroot"
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
cp install-arch-base-utils.sh /mnt/
cp arch-chroot-setup.sh /mnt/
cp arch-chroot-user.sh /mnt/
cp arch-chroot-postsetup.sh /mnt/
cp .env /mnt/
cp .bashrc /mnt/root/

# Chroot
ohai "arch-chroot"
arch-chroot /mnt /arch-chroot-setup.sh
source /mnt/.env
arch-chroot /mnt /usr/bin/runuser -u ${USERNAME} -- /home/${USERNAME}/arch-chroot-user.sh
arch-chroot /mnt /arch-chroot-postsetup.sh

ohai "Cleaning up"
rm /mnt/install-arch-base-utils.sh
rm /mnt/arch-chroot-setup.sh
rm /mnt/arch-chroot-user.sh
rm /mnt/arch-chroot-postsetup.sh
mv /mnt/.env /mnt/home/${USERNAME}/
rm /mnt/home/${USERNAME}/install-arch-base-utils.sh
rm /mnt/home/${USERNAME}/arch-chroot-user.sh
cleanup

umount -a &>/dev/null

ohai "Arch-Base installation successful!"

ohai "Next steps:"
cat <<EOS
    - Run ${tty_bold}reboot${tty_reset} to get started
EOS
echo
