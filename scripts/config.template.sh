#!/bin/bash

# Arch-Base Installation Configuration Template
# Copy this file to config.local.sh and modify as needed

# REQUIRED SETTINGS
# Uncomment and set these values for automated installation

# HOSTNAME="my-arch-system"
# TARGET_DISK="/dev/sda"  # WARNING: This disk will be completely wiped!

# USER SETTINGS
# USERNAME="myuser"
# USER_GROUPS="wheel,audio,video,storage,optical,lp,scanner"

# OPTIONAL SETTINGS
# These have sensible defaults but can be customized

# System Configuration
# TIMEZONE="America/New_York"
# LOCALE="en_US.UTF-8"
# KEYMAP="us"

# Mirror Configuration
# COUNTRY_ISO="US"  # Leave empty for auto-detection
# MIRROR_COUNT=20
# MIRROR_HOURS=48

# Disk Configuration
# EFI_SIZE="512M"
# LUKS_TYPE="luks2"

# Filesystem Configuration
# FS_TYPE="btrfs"  # Options: btrfs, ext4, xfs
# COMPRESS_TYPE="zstd"  # BTRFS only: zstd, lzo, zlib, none
# BTRFS_SUBVOLUME_LAYOUT="default"  # Options: default, minimal, custom
# BTRFS_CUSTOM_SUBVOLUMES="@,@home,@snapshots,@log,@cache,@swap"  # Custom layout
# LUKS_TYPE="luks2"  # or "luks1" for older compatibility
# CRYPTROOT_NAME="cryptroot"

# Filesystem Configuration
# FS_TYPE="btrfs"
# COMPRESS_TYPE="zstd"

# Package Configuration
# BASE_PACKAGES="base linux linux-firmware"
# ESSENTIAL_PACKAGES="btrfs-progs git vim sudo networkmanager"

# Swap Configuration
# SWAPFILE_ENABLED=true
# SWAPFILE_SIZE_MB=""  # Leave empty for auto-calculation (RAM + 2GB)

# Security Configuration
# LUKS_KEYFILE_ENABLED=true
# KEYFILE_PATH="/crypto_keyfile.bin"

# Installation Behavior
# INTERACTIVE_MODE=true  # Set to false for non-interactive installation
# AUTO_CONFIRM=false     # Set to true to automatically confirm all prompts
# DRY_RUN=false         # Set to true to see what would be done without executing
# SKIP_REBOOT=false     # Set to true to skip automatic reboot

# EXAMPLES:

# Example 1: Minimal automated installation
# HOSTNAME="workstation"
# USERNAME="john"
# TARGET_DISK="/dev/sda"
# AUTO_CONFIRM=true
# INTERACTIVE_MODE=false

# Example 2: Minimal base system with EXT4
# HOSTNAME="arch-server"
# USERNAME="admin"
# TARGET_DISK="/dev/nvme0n1"
# FS_TYPE="ext4"
# TIMEZONE="Europe/London"
# COUNTRY_ISO="GB"
# LUKS_TYPE="luks2"
# MINIMAL_INSTALL="true"
# INSTALL_OPTIONAL_PACKAGES="false"
# INSTALL_SECURITY_PACKAGES="false"

# Example 3: Development system with custom BTRFS layout
# HOSTNAME="dev-machine"
# USERNAME="developer"
# TARGET_DISK="/dev/sda"
# FS_TYPE="btrfs"
# COMPRESS_TYPE="zstd"
# BTRFS_SUBVOLUME_LAYOUT="custom"
# BTRFS_CUSTOM_SUBVOLUMES="@,@home,@snapshots,@opt"
# TIMEZONE="America/New_York"
# COUNTRY_ISO="US"
# MINIMAL_INSTALL="false"
# INSTALL_OPTIONAL_PACKAGES="true"
# INSTALL_SECURITY_PACKAGES="true"

# Example 4: XFS filesystem for high-performance storage
# HOSTNAME="storage-server"
# USERNAME="admin"
# TARGET_DISK="/dev/sdb"
# FS_TYPE="xfs"
# XFS_OPTIONS="-f -s size=4096 -d agcount=32"
# SWAPFILE_ENABLED="false"  # XFS with external swap partition
