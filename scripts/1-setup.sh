#!/bin/bash

source .env
source env.sh

print_header "Starting setup"
update_var SCRIPT_DIR ${GET_SCRIPT_DIR}
update_var REPO_DIR ${GET_REPO_DIR}

print_header "Setting up locales"
ln -sf /usr/share/zoneinfo/Europe/London /etc/localtime
hwclock --systohc
sed -i '160s/.//' /etc/locale.gen
locale-gen
echo "LANG=en_GB.UTF-8" >>/etc/locale.conf
echo "KEYMAP=uk" >>/etc/vconsole.conf

print_header "Configuring hostname and hosts file"
echo "arch" >>/etc/hostname
echo "127.0.0.1 localhost" >>/etc/hosts
echo "::1       localhost" >>/etc/hosts
echo "127.0.1.1 arch" >>/etc/hosts

print_header "Set root password"
passwd root

print_header "Setup root user bash"
echo "[[ -f ~/.bashrc ]] && . ~/.bashrc" >>${HOME}/.bash_profile
cp ${SCRIPT_DIR}/.bashrc ${HOME}/
touch ${HOME}/.bash_history
source ${HOME}/.bashrc

print_header "Installing system packages"
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
    'doas'
    'htop'
    'wget'
    'tmux'
    'zsh'
    'unzip'
    'nano'
    'ranger'
    'neofetch'
    'ncdu'
    'open-vm-tools'
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

print_header "Setup MAKEPKG config"
CPU_CORES=$(grep -c ^processor /proc/cpuinfo)
echo "You have ${CPU_CORES} cores."
echo "Changing the makeflags for "${CPU_CORES}" cores."
if [[ ${CPU_CORES} -gt 2 ]]; then
    sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j${CPU_CORES}\"/g" /etc/makepkg.conf
    echo "Changing the compression settings for "${CPU_CORES}" cores."
    sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T ${CPU_CORES} -z -)/g" /etc/makepkg.conf
fi

print_header "Create non-root user"
read -p "Username: " USERNAME
useradd -m ${USERNAME}
passwd ${USERNAME}
usermod -aG wheel ${USERNAME}
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >>"/etc/sudoers.d/${USERNAME}"
echo "permit persist :wheel" >>/etc/doas.conf
echo "permit persist :${USERNAME}" >>/etc/doas.conf
save_var USERNAME ${USERNAME}

print_header "Setup Snapper snapshots"
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

print_header "Copying arch-base repo to user directory"
cp -r ${REPO_DIR} /home/${USERNAME}/
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/${REPO_NAME}/

print_header "Setup complete"
