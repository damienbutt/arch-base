#!/bin/bash

set -euo pipefail

# Source common functions and environment
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source ${SCRIPT_DIR}/common.sh
source ${SCRIPT_DIR}/.env

# Only install AUR helper and packages if base-devel is installed
if pacman -Qi base-devel &>/dev/null; then
    log_info "Installing Paru AUR Helper"
    git clone https://aur.archlinux.org/paru-bin.git ~/paru-bin
    cd ~/paru-bin/ && makepkg -si --noconfirm && cd ~
    rm -rf paru-bin/

    log_info "Installing AUR packages"
    AUR_PKGS=(
        'zramd'        # ZRAM management daemon
    )

    for PKG in "${AUR_PKGS[@]}"; do
        log_info "Installing AUR package: ${PKG}"
        paru -S --noconfirm $PKG
    done
else
    log_info "Skipping AUR helper installation (base-devel not installed)"
    log_info "This is normal for a minimal base system"
fi
