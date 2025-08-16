#!/bin/bash

set -euo pipefail

# Source common functions and environment
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source ${SCRIPT_DIR}/common.sh
source ${SCRIPT_DIR}/.env

log_info "Configuring initramfs"
# Update mkinitcpio configuration based on filesystem type
if [[ "${FS_TYPE:-btrfs}" == "btrfs" ]]; then
    sed -i 's/^MODULES=()/MODULES=(btrfs crc32c-intel)/' /etc/mkinitcpio.conf
else
    sed -i 's/^MODULES=()/MODULES=(crc32c-intel)/' /etc/mkinitcpio.conf
fi

# Add LUKS keyfile if enabled
if [[ "${LUKS_KEYFILE_ENABLED:-true}" == "true" ]]; then
    sed -i "s|^FILES=()|FILES=(${KEYFILE_PATH:-/crypto_keyfile.bin})|" /etc/mkinitcpio.conf
fi

sed -i 's/block filesystems keyboard fsck/block encrypt filesystems keyboard/' /etc/mkinitcpio.conf
mkinitcpio -p linux

log_info "Setting up Arch Linux Netboot"
wget https://archlinux.org/static/netboot/ipxe-arch.16e24bec1a7c.efi &>/dev/null
mkdir -p /boot/efi/EFI/arch_netboot
mv ipxe*.*.efi /boot/efi/EFI/arch_netboot/arch_netboot.efi
efibootmgr --create --disk ${EFI_PARTITION} --part 1 --loader /EFI/arch_netboot/arch_netboot.efi --label "Arch Linux Netboot" &>/dev/null

log_info "Configuring Grub"
save_var ROOT_PARTITION_UUID "$(blkid -o value -s UUID ${ROOT_PARTITION})"
sed -i "s|quiet|cryptdevice=UUID=${ROOT_PARTITION_UUID}:${CRYPTROOT_NAME} root=${CRYPTROOT_PATH} lsm=landlock,lockdown,yama,apparmor,bpf audit=1|g" /etc/default/grub
sed -i 's/^#GRUB_ENABLE_CRYPTODISK/GRUB_ENABLE_CRYPTODISK/' /etc/default/grub
sed -i 's/^#GRUB_DISABLE_OS_PROBER/GRUB_DISABLE_OS_PROBER/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB --recheck
grub-mkconfig -o /boot/grub/grub.cfg
# cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/GRUB/grubx64.efi.bak
# git clone https://github.com/ccontavalli/grub-shusher.git ~/grub-shusher
# cd ~/grub-shusher/ && make && ./grub-kernel /boot/efi/EFI/GRUB/grubx64.efi && cd ~
# rm -rf grub-shusher/

log_info "Setting up crypttab"
echo "${CRYPTROOT_NAME}	UUID=${ROOT_PARTITION_UUID}	${KEYFILE_PATH:-/crypto_keyfile.bin}	luks" >>/etc/crypttab

log_info "Enabling essential services"
ESSENTIAL_SERVICES=(
    NetworkManager          # Network management
    sshd                    # SSH server
    reflector.timer         # Mirror list updates
    fstrim.timer           # SSD maintenance
)

# Optional services (only enabled if packages are installed)
OPTIONAL_SERVICES=(
    acpid                  # Power management (if acpi installed)
    snapper-timeline.timer # BTRFS snapshots (if snapper installed)
    snapper-cleanup.timer  # Snapshot cleanup (if snapper installed)
    snapper-boot.timer     # Boot snapshots (if snapper installed)
    grub-btrfs.path       # GRUB BTRFS integration (if grub-btrfs installed)
)

# Security services (only if security packages installed)
SECURITY_SERVICES=(
    ufw                    # Simple firewall (if ufw installed)
    apparmor              # MAC security (if apparmor installed)
    auditd                # Audit daemon (if audit installed)
)

# ZRAM service (only if zramd installed)
ZRAM_SERVICES=(
    zramd                 # ZRAM management
)

# Enable essential services
for SERVICE in "${ESSENTIAL_SERVICES[@]}"; do
    log_info "Enabling essential service: ${SERVICE}"
    systemctl enable "${SERVICE}" &>/dev/null || log_warn "Warning: Failed to enable ${SERVICE}"
done

# Enable optional services only if their packages are installed
for SERVICE in "${OPTIONAL_SERVICES[@]}"; do
    case "$SERVICE" in
        acpid)
            if pacman -Qi acpi &>/dev/null; then
                log_info "Enabling optional service: ${SERVICE}"
                systemctl enable "${SERVICE}" &>/dev/null
            fi
            ;;
        snapper-*)
            if pacman -Qi snapper &>/dev/null; then
                log_info "Enabling optional service: ${SERVICE}"
                systemctl enable "${SERVICE}" &>/dev/null
            fi
            ;;
        grub-btrfs.path)
            if pacman -Qi grub-btrfs &>/dev/null; then
                log_info "Enabling optional service: ${SERVICE}"
                systemctl enable "${SERVICE}" &>/dev/null
            fi
            ;;
    esac
done

# Enable security services only if their packages are installed
for SERVICE in "${SECURITY_SERVICES[@]}"; do
    case "$SERVICE" in
        ufw)
            if pacman -Qi ufw &>/dev/null; then
                log_info "Enabling security service: ${SERVICE}"
                systemctl enable "${SERVICE}" &>/dev/null
            fi
            ;;
        apparmor)
            if pacman -Qi apparmor &>/dev/null; then
                log_info "Enabling security service: ${SERVICE}"
                systemctl enable "${SERVICE}" &>/dev/null
            fi
            ;;
        auditd)
            if pacman -Qi audit &>/dev/null; then
                log_info "Enabling security service: ${SERVICE}"
                systemctl enable "${SERVICE}" &>/dev/null
            fi
            ;;
    esac
done

# Enable ZRAM only if installed
if pacman -Qi zramd &>/dev/null; then
    log_info "Setting up ZRAM"
    sed -i 's/# MAX_SIZE=8192/MAX_SIZE=1024/g' /etc/default/zramd
    for SERVICE in "${ZRAM_SERVICES[@]}"; do
        log_info "Enabling ZRAM service: ${SERVICE}"
        systemctl enable "${SERVICE}" &>/dev/null
    done
fi

# Enable AppArmor write cache only if AppArmor is installed
if pacman -Qi apparmor &>/dev/null; then
    log_info "Enabling apparmor write cache"
    sed -i 's/^#write-cache/write-cache/' /etc/apparmor/parser.conf
fi

echo "${USERNAME} ALL=(ALL) ALL" >"/etc/sudoers.d/${USERNAME}"
