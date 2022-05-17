#!/bin/bash

source env.sh

save_var SCRIPT_DIR ${GET_SCRIPT_DIR}
save_var REPO_DIR ${GET_REPO_DIR}
save_var REPO_NAME ${GET_REPO_NAME}

bash 0-preinstall.sh
arch-chroot /mnt /${REPO_NAME}/scripts/1-setup.sh

source /mnt/${REPO_NAME}/scripts/.env
arch-chroot /mnt /usr/bin/runuser -u ${USERNAME} -- /home/${USERNAME}/${REPO_NAME}/scripts/2-user.sh

arch-chroot /mnt /${REPO_NAME}/scripts/3-post-setup.sh
arch-chroot /mnt /bin/bash -c "rm -rf /${REPO_NAME}/"

cleanup

print_header "Complete"
reboot_after_delay 10
