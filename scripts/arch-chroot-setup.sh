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

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
source ${SCRIPT_DIR}/install-arch-base-utils.sh
source ${SCRIPT_DIR}/.env

ohai "Setting up locales"
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime

ohai "Setting up hardware clock"
hwclock --systohc

ohai "Setting up locales"
sed -i '160s/.//' /etc/locale.gen
echo "LANG=en_GB.UTF-8" >>/etc/locale.conf
echo "KEYMAP=uk" >>/etc/vconsole.conf
locale-gen >/dev/null

ohai "Configuring hostname and hosts file"
echo "arch" >>/etc/hostname
echo "127.0.0.1 localhost" >>/etc/hosts
echo "::1       localhost" >>/etc/hosts
echo "127.0.1.1 arch" >>/etc/hosts

ohai "Set root password"
passwd root

echo
ohai "Setup root user bash"
echo "[[ -f ~/.bashrc ]] && . ~/.bashrc" >>${HOME}/.bash_profile
touch ${HOME}/.bash_history

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
    'unzip'
    'nano'
    'snapper'
    'snap-pac'
    'ufw'
    'apparmor'
    'audit'
)

for PKG in "${PKGS[@]}"; do
    ohai "Installing: ${PKG}"
    pacman -S "$PKG" --noconfirm --needed
done

save_var CPU_TYPE "$(lscpu | awk '/^Vendor ID:/ {print $3}')"
case ${CPU_TYPE} in
GenuineIntel)
    ohai "Installing Intel microcode"
    pacman -S --noconfirm intel-ucode
    save_var CPU_UCODE "intel-ucode.img"
    ;;
AuthenticAMD)
    ohai "Installing AMD microcode"
    pacman -S --noconfirm amd-ucode
    save_var CPU_UCODE "amd-ucode.img"
    ;;
esac

ohai "Setup MAKEPKG config"
save_var CPU_CORES "$(grep -c ^processor /proc/cpuinfo)"
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

cp ${SCRIPT_DIR}/.env /home/${USERNAME}/
cp ${SCRIPT_DIR}/install-arch-base-utils.sh /home/${USERNAME}/
cp ${SCRIPT_DIR}/arch-chroot-user.sh /home/${USERNAME}/
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/
