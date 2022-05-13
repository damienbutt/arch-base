#!/bin/bash

source /arch-base/.env

echo "-------------------------------------------------"
echo "Configuring initramfs                            "
echo "-------------------------------------------------"
sed -i 's/^MODULES=()/MODULES=(btrfs crc32c-intel)/' /etc/mkinitcpio.conf
sed -i 's/^FILES=()/FILES=(\/crypto_keyfile.bin)/' /etc/mkinitcpio.conf
sed -i 's/block filesystems keyboard fsck/block encrypt filesystems keyboard/' /etc/mkinitcpio.conf
mkinitcpio -p linux

echo "-------------------------------------------------"
echo "Setting up Arch Linux Netboot                    "
echo "-------------------------------------------------"
wget https://archlinux.org/static/netboot/ipxe-arch.16e24bec1a7c.efi
mkdir /boot/efi/EFI/arch_netboot
mv ipxe*.*.efi /boot/efi/EFI/arch_netboot/arch_netboot.efi
efibootmgr --create --disk ${EFI_PARTITION} --part 1 --loader /EFI/arch_netboot/arch_netboot.efi --label "Arch Linux Netboot" --verbose

echo "-------------------------------------------------"
echo "Configuring Grub                                 "
echo "-------------------------------------------------"
ROOT_PARTITION_UUID=$(blkid -o value -s UUID ${ROOT_PARTITION})
echo "ROOT_PARTITION_UUID=${ROOT_PARTITION_UUID}" >>/arch-base/.env
sed -i "s|quiet|cryptdevice=UUID=${ROOT_PARTITION_UUID}:${CRYPTROOT_NAME} root=${CRYPTROOT_PATH} lsm=landlock,lockdown,yama,apparmor,bpf audit=1|g" /etc/default/grub
sed -i 's/^#GRUB_ENABLE_CRYPTODISK/GRUB_ENABLE_CRYPTODISK/' /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
cp /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/GRUB/grubx64.efi.bak
git clone https://github.com/ccontavalli/grub-shusher.git ~/grub-shusher
cd ~/grub-shusher/
make
./grub-kernel /boot/efi/EFI/GRUB/grubx64.efi
cd ~
rm -rf grub-shusher/

echo "-------------------------------------------------"
echo "Setting up crypttab                              "
echo "-------------------------------------------------"
echo "${CRYPTROOT_NAME}	UUID=${ROOT_PARTITION_UUID}	/crypto_keyfile.bin	luks" >>/etc/crypttab

echo "-------------------------------------------------"
echo "Setting up ZRAM                                  "
echo "-------------------------------------------------"
sed -i 's/# MAX_SIZE=8192/MAX_SIZE=1024/g' /etc/default/zramd

echo "-------------------------------------------------"
echo "Enabling apparmor write cache                    "
echo "-------------------------------------------------"
sed -i 's/^#write-cache/write-cache/' /etc/apparmor/parser.conf

echo "-------------------------------------------------"
echo "Enabling services to start at boot               "
echo "-------------------------------------------------"
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

echo "-------------------------------------------------"
echo "Copying arch-base repo to user directory         "
echo "-------------------------------------------------"
cp -r /arch-base/ /home/${USERNAME}/
chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}/arch-base/

echo "-------------------------------------------------"
echo "Resetting user (${USERNAME}) sudo permissions    "
echo "-------------------------------------------------"
echo "${USERNAME} ALL=(ALL) ALL" >"/etc/sudoers.d/${USERNAME}"

echo "-------------------------------------------------"
echo "Setting user (${USERNAME}) default shell to ZSH  "
echo "-------------------------------------------------"
usermod --shell /bin/zsh ${USERNAME}

echo "-------------------------------------------------"
echo "Setup Complete                                   "
echo "-------------------------------------------------"
