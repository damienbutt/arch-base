#!/bin/bash

source .env
source env.sh

print_header "Starting Post-setup"

print_header "Configuring initramfs"
sed -i 's/^MODULES=()/MODULES=(btrfs crc32c-intel)/' /etc/mkinitcpio.conf
sed -i 's/^FILES=()/FILES=(\/crypto_keyfile.bin)/' /etc/mkinitcpio.conf
sed -i 's/block filesystems keyboard fsck/block encrypt filesystems keyboard/' /etc/mkinitcpio.conf
mkinitcpio -p linux

print_header "Setting up Arch Linux Netboot"
wget https://archlinux.org/static/netboot/ipxe-arch.16e24bec1a7c.efi
mkdir /boot/efi/EFI/arch_netboot
mv ipxe*.*.efi /boot/efi/EFI/arch_netboot/arch_netboot.efi
efibootmgr --create --disk ${EFI_PARTITION} --part 1 --loader /EFI/arch_netboot/arch_netboot.efi --label "Arch Linux Netboot" --verbose

print_header "Configuring Grub"
save_var ROOT_PARTITION_UUID "$(blkid -o value -s UUID ${ROOT_PARTITION})"
sed -i "s|quiet|cryptdevice=UUID=${ROOT_PARTITION_UUID}:${CRYPTROOT_NAME} root=${CRYPTROOT_PATH} lsm=landlock,lockdown,yama,apparmor,bpf audit=1|g" /etc/default/grub
sed -i 's/^#GRUB_ENABLE_CRYPTODISK/GRUB_ENABLE_CRYPTODISK/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/GRUB/grubx64.efi.bak
git clone https://github.com/ccontavalli/grub-shusher.git ~/grub-shusher
cd ~/grub-shusher/ && make && ./grub-kernel /boot/efi/EFI/GRUB/grubx64.efi && cd ~
rm -rf grub-shusher/

print_header "Setting up crypttab"
echo "${CRYPTROOT_NAME}	UUID=${ROOT_PARTITION_UUID}	/crypto_keyfile.bin	luks" >>/etc/crypttab

print_header "Setting up ZRAM"
sed -i 's/# MAX_SIZE=8192/MAX_SIZE=1024/g' /etc/default/zramd

print_header "Enabling apparmor write cache"
sed -i 's/^#write-cache/write-cache/' /etc/apparmor/parser.conf

print_header "Enabling services to start at boot"
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

print_header "Copying arch-base repo to user directory"
cp -r ${REPO_DIR} /home/${USERNAME}/
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/${REPO_NAME}/

print_header "Resetting user (${USERNAME}) sudo permissions"
echo "${USERNAME} ALL=(ALL) ALL" >"/etc/sudoers.d/${USERNAME}"

print_header "Setting user (${USERNAME}) default shell to ZSH"
usermod --shell /bin/zsh ${USERNAME}

print_header "Post-setup complete"
