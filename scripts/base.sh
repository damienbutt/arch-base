#!/bin/bash

bash 0-preinstall.sh
arch-chroot /mnt /arch-base/1-setup.sh
source /mnt/arch-base/.env
arch-chroot /mnt /usr/bin/runuser -u ${USERNAME} -- /home/${USERNAME}/arch-base/2-user.sh
arch-chroot /mnt /arch-base/3-post-setup.sh
arch-chroot /mnt /bin/bash -c "rm -rf /arch-base/"

echo "-------------------------------------------------"
echo "Complete                                         "
echo "Rebooting in 10 seconds...                       "
echo "Press CTRL+C to cancel the reboot                "
echo "-------------------------------------------------"
echo "Rebooting in 10 Seconds ..." && sleep 1
echo "Rebooting in 9 Seconds ..." && sleep 1
echo "Rebooting in 8 Seconds ..." && sleep 1
echo "Rebooting in 7 Seconds ..." && sleep 1
echo "Rebooting in 6 Seconds ..." && sleep 1
echo "Rebooting in 5 Seconds ..." && sleep 1
echo "Rebooting in 4 Seconds ..." && sleep 1
echo "Rebooting in 3 Seconds ..." && sleep 1
echo "Rebooting in 2 Seconds ..." && sleep 1
echo "Rebooting in 1 Second ..." && sleep 1
reboot now
