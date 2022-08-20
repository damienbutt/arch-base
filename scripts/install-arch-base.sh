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
if ! command -v curl >/dev/null; then
    abort "$(
        cat <<EOABORT
You must install cURL before running this script. Run the following command:
  ${tty_underline}pacman -S curl${tty_reset}
EOABORT
    )"
fi

# Download dependencies
curl -fsSL https://raw.githubusercontent.com/damienbutt/arch-base/HEAD/scripts/install-arch-base-utils.sh >install-arch-base-utils.sh
curl -fsSL https://raw.githubusercontent.com/damienbutt/arch-base/HEAD/scripts/.bashrc >.bashrc
source install-arch-base-utils.sh

# Start the actual installation
ohai "Starting Arch-Base installation"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# Update the system clock
timedatectl set-ntp true

# Setup mirrors
save_var ISO "$(curl -4 ifconfig.co/country-iso)"
ohai "Setting up ${ISO} mirrors for faster downloads"
if [[ -f /etc/pacman.d/mirrorlist ]]; then
    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
fi
reflector -a 48 -c ${ISO} -f 5 -l 20 --sort rate --save /etc/pacman.d/mirrorlist >/dev/null
pacman -Syyy --noconfirm >/dev/null

# Enable parallel downloads
sed -i 's/^#Para/Para/' /etc/pacman.conf

# Parition and format the disk
clear
ohai "Select your disk to format"
lsblk

echo
read -p "Please enter disk to work on: (example /dev/sda): " DISK

echo
warn "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"

echo
read -p "Are you sure you want to continue (y/N):" FORMAT
case ${FORMAT} in
y | Y | yes | Yes | YES)
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

    ohai "Opening LUKS volume"
    save_var CRYPTROOT_NAME "cryptroot"
    save_var CRYPTROOT_PATH "/dev/mapper/${CRYPTROOT_NAME}"
    cryptsetup open ${ROOT_PARTITION} ${CRYPTROOT_NAME}

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
TOTAL_MEM=$(awk '/MemTotal/ {printf( "%d\n", $2 / 1024 )}' /proc/meminfo)
SWAPFILE_SIZE=$((${TOTAL_MEM} + 2048))
touch /mnt/swap/swapfile
truncate -s 0 /mnt/swap/swapfile
chattr +C /mnt/swap/swapfile
btrfs property set /mnt/swap/swapfile compression none
dd if=/dev/zero of=/mnt/swap/swapfile bs=1M count=${SWAPFILE_SIZE} status=progress
chmod 600 /mnt/swap/swapfile
mkswap /mnt/swap/swapfile
swapon /mnt/swap/swapfile
echo "/swap/swapfile none swap defaults 0 0" >>/mnt/etc/fstab

# Setup LUKS keyfile
ohai "Setting up LUKS keyfile"
dd bs=512 count=4 if=/dev/random of=/mnt/crypto_keyfile.bin iflag=fullblock
chmod 600 /mnt/crypto_keyfile.bin
chmod 600 /mnt/boot/initramfs-linux*

ohai "Adding the LUKS keyfile" "Enter your disk encryption password when prompted"
cryptsetup luksAddKey ${ROOT_PARTITION} /mnt/crypto_keyfile.bin

ohai "Preparing for arch-chroot"
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
cp install-arch-base-utils.sh /mnt/
cp .env /mnt/
cp .bashrc /mnt/root/

# Chroot
arch-chroot /mnt $(
    SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
    source /install-arch-base-utils.sh
    source /.env

    ohai "Setting up locales"
    ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
    hwclock --systohc
    sed -i '160s/.//' /etc/locale.gen
    locale-gen >/dev/null
    echo "LANG=en_GB.UTF-8" >>/etc/locale.conf
    echo "KEYMAP=mac-uk" >>/etc/vconsole.conf

    ohai "Configuring hostname and hosts file"
    echo "arch" >>/etc/hostname
    echo "127.0.0.1 localhost" >>/etc/hosts
    echo "::1       localhost" >>/etc/hosts
    echo "127.0.1.1 arch" >>/etc/hosts

    ohai "Set root password"
    passwd root

    ohai "Setup root user bash"
    echo "[[ -f ~/.bashrc ]] && . ~/.bashrc" >>${HOME}/.bash_profile
    # cp ${SCRIPT_DIR}/.bashrc ${HOME}/
    touch ${HOME}/.bash_history
    # source ${HOME}/.bashrc

    clear
    ohai "Installing system packages"
    sed -i 's/^#Para/Para/' /etc/pacman.conf
    sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
    pacman -Sy --noconfirm
    PKGS=(
        'grub'
        'grub-btrfs'
        'efibootmgr'
        'networkmanager'
        'network-manager-applet'
        'dialog'
        'wpa_supplicant'
        'mtools'
        'dosfstools'
        'base-devel'
        'linux-headers'
        'cronie'
        'avahi'
        'xdg-user-dirs'
        'xdg-utils'
        'gvfs'
        'gvfs-smb'
        'nfs-utils'
        'inetutils'
        'dnsutils'
        'bash-completion'
        'openssh'
        'rsync'
        'reflector'
        'acpi'
        'acpi_call'
        'ipset'
        'firewalld'
        'sof-firmware'
        'nss-mdns'
        'acpid'
        'os-prober'
        'ntfs-3g'
        'terminus-font'
        'htop'
        'wget'
        'tmux'
        'zsh'
        'unzip'
        'nano'
        'ranger'
        'neofetch'
        'ncdu'
        'snapper'
        'snap-pac'
        'ufw'
        'speedtest-cli'
        'mlocate'
        'apparmor'
        'audit'
        'tree'
    )

    for PKG in "${PKGS[@]}"; do
        echo "Installing: ${PKG}"
        pacman -S "$PKG" --noconfirm --needed
    done

    CPU_TYPE=$(lscpu | awk '/Vendor ID:/ {print $3}')
    case ${CPU_TYPE} in
    GenuineIntel)
        echo "Installing Intel microcode"
        pacman -S --noconfirm intel-ucode
        CPU_UCODE=intel-ucode.img
        ;;
    AuthenticAMD)
        echo "Installing AMD microcode"
        pacman -S --noconfirm amd-ucode
        CPU_UCODE=amd-ucode.img
        ;;
    esac

    ohai "Setup MAKEPKG config"
    CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
    echo "You have ${CPU_CORES} cores."
    echo "Changing the makeflags for "${CPU_CORES}" cores."
    if [[ ${CPU_CORES} -gt 2 ]]; then
        sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j${CPU_CORES}\"/g" /etc/makepkg.conf
        echo "Changing the compression settings for "${CPU_CORES}" cores."
        sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T ${CPU_CORES} -z -)/g" /etc/makepkg.conf
    fi

    ohai "Create non-root user"
    read -p "Username: " USERNAME
    useradd -m ${USERNAME}
    passwd ${USERNAME}
    usermod -aG wheel ${USERNAME}
    sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
    echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >>"/etc/sudoers.d/${USERNAME}"
    save_var USERNAME ${USERNAME}

    ohai "Setup Snapper snapshots"
    umount /.snapshots
    rm -r /.snapshots
    snapper --no-dbus -c root create-config /
    btrfs subvolume delete /.snapshots
    mkdir /.snapshots
    mount -a
    chown :${USERNAME} /.snapshots
    chmod 750 /.snapshots
    chmod a+rx /.snapshots
    sed -i "s/ALLOW_USERS=\"\"/ALLOW_USERS=\"${USERNAME}\"/g" /etc/snapper/configs/root
    sed -i "s/TIMELINE_LIMIT_YEARLY=\"10\"/TIMELINE_LIMIT_YEARLY=\"0\"/g" /etc/snapper/configs/root
    sed -i "s/TIMELINE_LIMIT_MONTHLY=\"10\"/TIMELINE_LIMIT_MONTHLY=\"0\"/g" /etc/snapper/configs/root
    sed -i "s/TIMELINE_LIMIT_DAILY=\"10\"/TIMELINE_LIMIT_DAILY=\"7\"/g" /etc/snapper/configs/root
    sed -i "s/TIMELINE_LIMIT_HOURLY=\"10\"/TIMELINE_LIMIT_HOURLY=\"5\"/g" /etc/snapper/configs/root
)

arch-chroot /mnt /usr/bin/runuser -u ${USERNAME} -- $(
    clear
    ohai "Installing Paru AUR Helper"
    git clone https://aur.archlinux.org/paru-bin.git ~/paru-bin
    cd ~/paru-bin/ && makepkg -si --noconfirm && cd ~
    rm -rf paru-bin/

    ohai "Installing AUR packages"
    PKGS=(
        'zramd'
    )

    for PKG in "${PKGS[@]}"; do
        paru -S --noconfirm $PKG
    done
)

arch-chroot /mnt $(
    clear
    ohai "Configuring initramfs"
    sed -i 's/^MODULES=()/MODULES=(btrfs crc32c-intel)/' /etc/mkinitcpio.conf
    sed -i 's/^FILES=()/FILES=(\/crypto_keyfile.bin)/' /etc/mkinitcpio.conf
    sed -i 's/block filesystems keyboard fsck/block encrypt filesystems keyboard/' /etc/mkinitcpio.conf
    mkinitcpio -p linux

    ohai "Setting up Arch Linux Netboot"
    wget https://archlinux.org/static/netboot/ipxe-arch.16e24bec1a7c.efi
    mkdir /boot/efi/EFI/arch_netboot
    mv ipxe*.*.efi /boot/efi/EFI/arch_netboot/arch_netboot.efi
    efibootmgr --create --disk ${EFI_PARTITION} --part 1 --loader /EFI/arch_netboot/arch_netboot.efi --label "Arch Linux Netboot" --verbose

    ohai "Configuring Grub"
    save_var ROOT_PARTITION_UUID "$(blkid -o value -s UUID ${ROOT_PARTITION})"
    sed -i "s|quiet|cryptdevice=UUID=${ROOT_PARTITION_UUID}:${CRYPTROOT_NAME} root=${CRYPTROOT_PATH} lsm=landlock,lockdown,yama,apparmor,bpf audit=1|g" /etc/default/grub
    sed -i 's/^#GRUB_ENABLE_CRYPTODISK/GRUB_ENABLE_CRYPTODISK/' /etc/default/grub
    grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
    cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/GRUB/grubx64.efi.bak
    git clone https://github.com/ccontavalli/grub-shusher.git ~/grub-shusher
    cd ~/grub-shusher/ && make && ./grub-kernel /boot/efi/EFI/GRUB/grubx64.efi && cd ~
    rm -rf grub-shusher/

    ohai "Setting up crypttab"
    echo "${CRYPTROOT_NAME}	UUID=${ROOT_PARTITION_UUID}	/crypto_keyfile.bin	luks" >>/etc/crypttab

    ohai "Setting up ZRAM"
    sed -i 's/# MAX_SIZE=8192/MAX_SIZE=1024/g' /etc/default/zramd

    ohai "Enabling apparmor write cache"
    sed -i 's/^#write-cache/write-cache/' /etc/apparmor/parser.conf

    ohai "Enabling services to start at boot"
    systemctl enable NetworkManager
    systemctl enable sshd
    systemctl enable avahi-daemon
    systemctl enable reflector.timer
    systemctl enable fstrim.timer
    systemctl enable firewalld
    systemctl enable acpid
    systemctl enable cronie
    systemctl enable zramd
    systemctl enable snapper-timeline.timer
    systemctl enable snapper-cleanup.timer
    systemctl enable snapper-boot.timer
    systemctl enable grub-btrfs.path
    systemctl enable apparmor
    systemctl enable auditd

    echo "${USERNAME} ALL=(ALL) ALL" >"/etc/sudoers.d/${USERNAME}"

    ohai "Setting user (${USERNAME}) default shell to ZSH"
    usermod -s /bin/zsh ${USERNAME}
)

cleanup

umount -a >/dev/null

ohai "Arch-Base installation successful!"
echo

ohai "Next steps:"
cat <<EOS
- Run ${tty_bold}reboot${tty_reset} to get started
EOS
