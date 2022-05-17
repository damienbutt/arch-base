#!/bin/bash

source /env.sh

print_header "Starting user setup"

print_header "Installing Paru AUR Helper" "This may take some time... Please be patient"
git clone https://aur.archlinux.org/paru-bin.git ~/paru-bin
cd ~/paru-bin/ && makepkg -si --noconfirm && cd ~
rm -rf paru-bin/

print_header "Installing AUR packages" "This may take some time... Please be patient"
PKGS=(
    'zramd'
)

for PKG in "${PKGS[@]}"; do
    paru -S --noconfirm $PKG
done

print_header "User setup complete"
