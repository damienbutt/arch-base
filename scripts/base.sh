#!/bin/bash

export REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
export REPO_NAME=$(awk -F/ '{print $NF}' <<<${REPO_DIR})
echo "REPO_DIR=${REPO_DIR}" >>${REPO_DIR}/.env
echo "REPO_NAME=${REPO_NAME}" >>${REPO_DIR}/.env

bash ${REPO_DIR}/scripts/0-preinstall.sh
arch-chroot /mnt /${REPO_NAME}/1-setup.sh
source /mnt/${REPO_NAME}/.env
arch-chroot /mnt /usr/bin/runuser -u ${USERNAME} -- /home/${USERNAME}/${REPO_NAME}/2-user.sh
arch-chroot /mnt /${REPO_NAME}/3-post-setup.sh
arch-chroot /mnt /bin/bash -c "rm -rf /${REPO_NAME}/"

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
