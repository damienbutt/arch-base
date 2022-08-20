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

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source ${SCRIPT_DIR}/install-arch-base-utils.sh
source ${SCRIPT_DIR}/.env

clear
ohai "Configuring initramfs"
sed -i 's/^MODULES=()/MODULES=(btrfs crc32c-intel)/' /etc/mkinitcpio.conf
sed -i 's/^FILES=()/FILES=(\/crypto_keyfile.bin)/' /etc/mkinitcpio.conf
sed -i 's/block filesystems keyboard fsck/block encrypt filesystems keyboard/' /etc/mkinitcpio.conf
mkinitcpio -p linux

# ohai "Setting up Arch Linux Netboot"
# wget https://archlinux.org/static/netboot/ipxe-arch.16e24bec1a7c.efi
# mkdir /boot/efi/EFI/arch_netboot
# mv ipxe*.*.efi /boot/efi/EFI/arch_netboot/arch_netboot.efi
# efibootmgr --create --disk ${EFI_PARTITION} --part 1 --loader /EFI/arch_netboot/arch_netboot.efi --label "Arch Linux Netboot" --verbose

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
SERVICES=(
    NetworkManager
    sshd
    avahi-daemon
    reflector.timer
    fstrim.timer
    firewalld
    acpid
    cronie
    zramd
    snapper-timeline.timer
    snapper-cleanup.timer
    snapper-boot.timer
    grub-btrfs.path
    apparmor
    auditd
)

for SERVICE in "${SERVICES[@]}"; do
    systemctl enable "${SERVICE}" >/dev/null
done

echo "${USERNAME} ALL=(ALL) ALL" >"/etc/sudoers.d/${USERNAME}"

ohai "Setting user (${USERNAME}) default shell to ZSH"
usermod -s /bin/zsh ${USERNAME}
