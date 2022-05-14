#!/bin/bash

pacman -Syyy --noconfirm
pacman -S git --noconfirm --needed
git clone https://github.com/damienbutt/arch-base.git arch-base && cd "$_"
