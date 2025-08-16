#!/bin/bash

# Arch-Base Installation Configuration
# Copy this file and modify values as needed

# System Configuration
HOSTNAME="${HOSTNAME:-arch-desktop}"
TIMEZONE="${TIMEZONE:-UTC}"
LOCALE="${LOCALE:-en_US.UTF-8}"
KEYMAP="${KEYMAP:-us}"

# Mirror Configuration
COUNTRY_ISO="${COUNTRY_ISO:-US}"  # Auto-detect if empty
MIRROR_COUNT="${MIRROR_COUNT:-20}"
MIRROR_HOURS="${MIRROR_HOURS:-48}"

# Disk Configuration
TARGET_DISK="${TARGET_DISK:-}"  # Must be set or prompted
EFI_SIZE="${EFI_SIZE:-260M}"
LUKS_TYPE="${LUKS_TYPE:-luks1}"
CRYPTROOT_NAME="${CRYPTROOT_NAME:-cryptroot}"

# Filesystem Configuration
FS_TYPE="${FS_TYPE:-btrfs}"
COMPRESS_TYPE="${COMPRESS_TYPE:-zstd}"
MOUNT_OPTIONS="${MOUNT_OPTIONS:-noatime,compress=zstd,space_cache=v2,ssd,discard=async}"

# BTRFS Subvolume Configuration
BTRFS_SUBVOLUME_LAYOUT="${BTRFS_SUBVOLUME_LAYOUT:-default}"  # default, minimal, custom
BTRFS_CUSTOM_SUBVOLUMES="${BTRFS_CUSTOM_SUBVOLUMES:-}"       # Comma-separated list: @,@home,@snapshots

# EXT4 Configuration
EXT4_FEATURES="${EXT4_FEATURES:-^64bit,ext_attr,dir_index,filetype,sparse_super,large_file,huge_file,uninit_bg,dir_nlink,extra_isize}"

# XFS Configuration
XFS_OPTIONS="${XFS_OPTIONS:--f -s size=4096}"

# Package Configuration
BASE_PACKAGES="${BASE_PACKAGES:-base linux linux-firmware}"
ESSENTIAL_PACKAGES="${ESSENTIAL_PACKAGES:-git vim}"  # Filesystem tools added automatically

# Package Installation Options
INSTALL_OPTIONAL_PACKAGES="${INSTALL_OPTIONAL_PACKAGES:-true}"    # Development tools, utilities
INSTALL_SECURITY_PACKAGES="${INSTALL_SECURITY_PACKAGES:-true}"    # Firewall, AppArmor
MINIMAL_INSTALL="${MINIMAL_INSTALL:-false}"                       # Ultra-minimal (overrides above)

# Swap Configuration
SWAPFILE_ENABLED="${SWAPFILE_ENABLED:-true}"
SWAPFILE_SIZE_MB="${SWAPFILE_SIZE_MB:-}"  # Auto-calculate if empty (RAM + 2GB)

# Security Configuration
LUKS_KEYFILE_ENABLED="${LUKS_KEYFILE_ENABLED:-true}"
KEYFILE_PATH="${KEYFILE_PATH:-/crypto_keyfile.bin}"

# Installation Behavior
INTERACTIVE_MODE="${INTERACTIVE_MODE:-true}"
AUTO_CONFIRM="${AUTO_CONFIRM:-false}"
DRY_RUN="${DRY_RUN:-false}"
SKIP_REBOOT="${SKIP_REBOOT:-false}"

# Validation function
validate_config() {
    local errors=()

    # Check required tools
    if ! command -v curl >/dev/null 2>&1; then
        errors+=("curl is required but not installed")
    fi

    if ! command -v sgdisk >/dev/null 2>&1; then
        errors+=("sgdisk (gdisk package) is required but not installed")
    fi

    # Validate disk if specified
    if [[ -n "$TARGET_DISK" && ! -b "$TARGET_DISK" ]]; then
        errors+=("Target disk $TARGET_DISK does not exist")
    fi

    # Validate hostname
    if [[ ! "$HOSTNAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
        errors+=("Invalid hostname: $HOSTNAME")
    fi

    # Print errors and exit if any
    if [[ ${#errors[@]} -gt 0 ]]; then
        printf "Configuration validation failed:\n"
        printf "  - %s\n" "${errors[@]}"
        return 1
    fi

    return 0
}

# Load custom config if it exists
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/config.local.sh" ]]; then
    source "$SCRIPT_DIR/config.local.sh"
fi
