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

ohai "Installing Paru AUR Helper"
git clone https://aur.archlinux.org/paru-bin.git ~/paru-bin
cd ~/paru-bin/ && makepkg -si --noconfirm && cd ~
rm -rf paru-bin/

ohai "Installing AUR packages"
PKGS=(
    'zramd'
)

for PKG in "${PKGS[@]}"; do
    paru -S --noconfirm $PKG
done
