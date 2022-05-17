#!/bin/bash

pacman -Syyy --noconfirm
pacman -S git --noconfirm --needed
git clone https://github.com/damienbutt/arch-base.git && cd arch-base/scripts
bash base.sh
