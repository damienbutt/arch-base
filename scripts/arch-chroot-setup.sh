#!/bin/bash

set -euo pipefail

# Source common functions and environment
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source ${SCRIPT_DIR}/common.sh
source ${SCRIPT_DIR}/.env

log_info "Setting up timezone"
ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

log_info "Setting up hardware clock"
hwclock --systohc

log_info "Setting up locales"
echo "${LOCALE} UTF-8" >>/etc/locale.gen
locale-gen
echo "LANG=${LOCALE}" >/etc/locale.conf
echo "KEYMAP=${KEYMAP}" >/etc/vconsole.conf

log_info "Configuring hostname and hosts file"
echo "${HOSTNAME}" >/etc/hostname
echo "127.0.0.1 localhost" >>/etc/hosts
echo "::1       localhost" >>/etc/hosts
echo "127.0.1.1 ${HOSTNAME}.localdomain ${HOSTNAME}" >>/etc/hosts

log_info "Set root password"
echo "root:${ROOT_PASSWORD}" | chpasswd

log_info "Setup root user bash"
echo "[[ -f ~/.bashrc ]] && . ~/.bashrc" >>${HOME}/.bash_profile
touch ${HOME}/.bash_history

log_info "Installing system packages"
sed -i 's/^#Para/Para/' /etc/pacman.conf
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Syyy --noconfirm

# Essential packages for a minimal base system
ESSENTIAL_PKGS=(
    'grub'              # Bootloader
    'grub-btrfs'        # BTRFS integration for GRUB
    'efibootmgr'        # EFI boot management
    'networkmanager'    # Network management
    'dialog'            # For network configuration TUI
    'wpa_supplicant'    # WiFi authentication
    'mtools'            # Tools for FAT filesystems
    'dosfstools'        # FAT filesystem utilities
    'openssh'           # SSH server/client
    'bash-completion'   # Command completion
    'reflector'         # Mirror list management
    'rsync'             # File synchronization
)

# Optional packages (can be disabled for ultra-minimal system)
OPTIONAL_PKGS=(
    'base-devel'        # Development tools (needed for AUR)
    'linux-headers'     # Kernel headers (needed for some modules)
    'acpi'              # Power management
    'acpi_call'         # ACPI call interface
    'acpid'             # ACPI daemon
    'sof-firmware'      # Sound firmware
    'terminus-font'     # Console font
    'vim'               # Text editor
    'snapper'           # BTRFS snapshots
    'snap-pac'          # Automatic snapshots with pacman
    'dnsutils'          # DNS utilities (dig, nslookup)
    'inetutils'         # Network utilities
)

# Security packages (optional for base system)
SECURITY_PKGS=(
    'ufw'               # Simple firewall
    'apparmor'          # MAC security
)

# Install essential packages
for PKG in "${ESSENTIAL_PKGS[@]}"; do
    log_info "Installing essential: ${PKG}"
    pacman -S "$PKG" --noconfirm --needed
done

# Handle minimal install override
if [[ "${MINIMAL_INSTALL:-false}" == "true" ]]; then
    log_info "Minimal install mode: Skipping optional and security packages"
else
    # Ask about optional packages in interactive mode
    if [[ "${INTERACTIVE_MODE:-true}" == "true" ]]; then
        echo
        if gum confirm "Install optional packages (development tools, utilities)?" 2>/dev/null || confirm "Install optional packages (development tools, utilities)?"; then
            for PKG in "${OPTIONAL_PKGS[@]}"; do
                log_info "Installing optional: ${PKG}"
                pacman -S "$PKG" --noconfirm --needed
            done
        fi

        echo
        if gum confirm "Install security packages (firewall, AppArmor)?" 2>/dev/null || confirm "Install security packages (firewall, AppArmor)?"; then
            for PKG in "${SECURITY_PKGS[@]}"; do
                log_info "Installing security: ${PKG}"
                pacman -S "$PKG" --noconfirm --needed
            done
        fi
    else
        # In non-interactive mode, check configuration variables
        if [[ "${INSTALL_OPTIONAL_PACKAGES:-false}" == "true" ]]; then
            for PKG in "${OPTIONAL_PKGS[@]}"; do
                log_info "Installing optional: ${PKG}"
                pacman -S "$PKG" --noconfirm --needed
            done
        fi

        if [[ "${INSTALL_SECURITY_PACKAGES:-false}" == "true" ]]; then
            for PKG in "${SECURITY_PKGS[@]}"; do
                log_info "Installing security: ${PKG}"
                pacman -S "$PKG" --noconfirm --needed
            done
        fi
    fi
fi

save_var CPU_TYPE "$(lscpu | awk '/^Vendor ID:/ {print $3}')"
case ${CPU_TYPE} in
GenuineIntel)
    log_info "Installing Intel microcode"
    pacman -S --noconfirm intel-ucode
    save_var CPU_UCODE "intel-ucode.img"
    ;;
AuthenticAMD)
    log_info "Installing AMD microcode"
    pacman -S --noconfirm amd-ucode
    save_var CPU_UCODE "amd-ucode.img"
    ;;
esac

log_info "Setup MAKEPKG config"
save_var CPU_CORES "$(grep -c ^processor /proc/cpuinfo)"
echo "You have ${CPU_CORES} cores."
echo "Changing the makeflags for "${CPU_CORES}" cores."
if [[ ${CPU_CORES} -gt 2 ]]; then
    sed -i "s/#MAKEFLAGS=\"-j2\"/MAKEFLAGS=\"-j${CPU_CORES}\"/g" /etc/makepkg.conf
    echo "Changing the compression settings for "${CPU_CORES}" cores."
    sed -i "s/COMPRESSXZ=(xz -c -z -)/COMPRESSXZ=(xz -c -T ${CPU_CORES} -z -)/g" /etc/makepkg.conf
fi

log_info "Create non-root user"
for (( ; ; )); do
    read -p "Username: " USERNAME

    if [ id -u ${USERNAME} ] &>/dev/null; then
        echo "Username \"${USERNAME}\" already exists on the system. Please use a different username..."
        continue
    fi

    break
done

useradd -m -G wheel ${USERNAME}
passwd ${USERNAME}
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo "${USERNAME} ALL=(ALL) NOPASSWD: ALL" >>"/etc/sudoers.d/${USERNAME}"
save_var USERNAME ${USERNAME}
cp ${HOME}/.bashrc /home/${USERNAME}/ && chown ${USERNAME}:${USERNAME} /home/${USERNAME}/.bashrc

log_info "Setup Snapper snapshots"
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
