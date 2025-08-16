#!/bin/bash

# Arch-Base Installation Script
# Enhanced version with improved error handling, configuration, and robustness

# Source configuration and common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/config.sh"

# Parse command line arguments
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
    -c, --config FILE    Use custom configuration file
    -d, --dry-run        Show what would be done without executing
    -y, --auto-confirm   Automatically confirm all prompts
    -h, --help           Show this help message
    --skip-download      Skip downloading dependencies
    --disk DEVICE        Target disk device (e.g., /dev/sda)

Examples:
    $0                           # Interactive installation
    $0 -y --disk /dev/sda        # Automated installation
    $0 -d                        # Dry run to see what would be done
    $0 -c custom-config.sh       # Use custom configuration

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -y|--auto-confirm)
                AUTO_CONFIRM=true
                INTERACTIVE_MODE=false
                shift
                ;;
            --skip-download)
                SKIP_DOWNLOAD=true
                shift
                ;;
            --disk)
                TARGET_DISK="$2"
                shift 2
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# Pre-flight checks
preflight_checks() {
    log_info "Performing pre-flight checks..."

    check_root
    check_arch_linux
    check_internet

    # Validate configuration
    if ! validate_config; then
        abort "Configuration validation failed"
    fi

    log_success "Pre-flight checks completed"
}

# Download dependencies with better error handling
download_dependencies() {
    if [[ "${SKIP_DOWNLOAD:-false}" == "true" ]]; then
        log_info "Skipping dependency download"
        return 0
    fi

    step "Downloading installation dependencies"

    local base_url="https://raw.githubusercontent.com/damienbutt/arch-base/HEAD/scripts"
    local scripts=(
        "arch-chroot-setup.sh"
        "arch-chroot-user.sh"
        "arch-chroot-postsetup.sh"
        "install-arch-base-utils.sh"
        ".bashrc"
    )

    for script in "${scripts[@]}"; do
        log_info "Downloading $script..."
        if ! retry 3 2 "curl -fsSL $base_url/$script -o $script"; then
            abort "Failed to download $script"
        fi
    done

    chmod +x *.sh

    # Source utilities after download
    if [[ -f "install-arch-base-utils.sh" ]]; then
        source install-arch-base-utils.sh
    fi

    log_success "Dependencies downloaded successfully"
}

# Setup system time with NTP
setup_time() {
    step "Setting up system time"

    execute "timedatectl set-ntp true"

    # Wait for time synchronization
    local timeout=30
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if timedatectl status | grep -q "System clock synchronized: yes"; then
            log_success "System clock synchronized"
            return 0
        fi
        sleep 1
        ((elapsed++))
    done

    log_warn "Time synchronization timeout, continuing anyway"
}

# Setup package mirrors with country detection
setup_mirrors() {
    step "Setting up package mirrors"

    # Detect country if not specified
    if [[ -z "${COUNTRY_ISO}" ]]; then
        log_info "Detecting country..."
        COUNTRY_ISO=$(retry 3 2 "curl -s ifconfig.co/country-iso" || echo "US")
        log_info "Detected country: $COUNTRY_ISO"
    fi

    # Backup existing mirrorlist
    backup_file /etc/pacman.d/mirrorlist

    log_info "Setting up $COUNTRY_ISO mirrors for faster downloads"
    execute "reflector -a $MIRROR_HOURS -c $COUNTRY_ISO -f 5 -l $MIRROR_COUNT --sort rate --save /etc/pacman.d/mirrorlist"

    # Update package database
    execute "pacman -Syyy --noconfirm"

    # Enable parallel downloads
    if ! grep -q "^ParallelDownloads" /etc/pacman.conf; then
        execute "sed -i 's/^#ParallelDownloads/ParallelDownloads/' /etc/pacman.conf"
    fi

    log_success "Package mirrors configured"
}

# Enhanced disk selection with gum support
select_target_disk() {
    if [[ -n "${TARGET_DISK}" ]]; then
        if [[ ! -b "${TARGET_DISK}" ]]; then
            abort "Specified target disk ${TARGET_DISK} does not exist"
        fi
        log_info "Using specified target disk: ${TARGET_DISK}"
        return 0
    fi

    step "Disk selection"

    # Get available disks
    local available_disks=($(lsblk -dno NAME | grep -E '^(sd|nvme|vd)' | sed 's|^|/dev/|'))

    if [[ ${#available_disks[@]} -eq 0 ]]; then
        abort "No suitable disks found!"
    fi

    # Display disk information
    display_message "info" "Available disks:" "💾 Disk Selection"
    echo ""
    lsblk -o NAME,SIZE,TYPE,MODEL | grep disk | gum format --type code
    echo ""

    # Use gum for selection if available
    if has_gum && [[ "${USE_GUM:-true}" == "true" ]]; then
        TARGET_DISK=$(select_option "Select target disk for installation:" "${available_disks[@]}")

        # Show disk details
        echo ""
        display_message "info" "Selected disk: **$TARGET_DISK**"
        lsblk "$TARGET_DISK" | gum format --type code
        echo ""

        # Check if disk is in use and warn
        if mount | grep -q "${TARGET_DISK}"; then
            display_message "warning" "Disk $TARGET_DISK has mounted partitions!"
            if ! confirm "Continue anyway?"; then
                select_target_disk  # Recursively call to select again
                return
            fi
        fi

        # Final confirmation with dramatic warning
        display_message "warning" "⚠️  **FINAL WARNING** ⚠️\n\nThis will **COMPLETELY ERASE** all data on:\n**$TARGET_DISK**\n\n**ALL DATA WILL BE PERMANENTLY LOST!**" "Data Loss Warning"

        if ! confirm "I understand that ALL DATA on $TARGET_DISK will be PERMANENTLY DELETED"; then
            abort "Installation cancelled by user"
        fi
    else
        # Fallback to traditional selection
        echo "Available disks:"
        for i in "${!available_disks[@]}"; do
            echo "$((i+1))) ${available_disks[i]}"
        done

        while true; do
            echo
            read -p "Please enter disk to install Arch-Base on (example /dev/sda): " TARGET_DISK

            if [[ -z "${TARGET_DISK}" ]]; then
                log_warn "No disk specified. Please try again."
                continue
            fi

            if [[ ! -b "${TARGET_DISK}" ]]; then
                log_warn "Disk ${TARGET_DISK} does not exist. Please try again."
                continue
            fi

            # Check if disk is in use
            if mount | grep -q "${TARGET_DISK}"; then
                log_warn "Disk ${TARGET_DISK} has mounted partitions"
                if ! confirm "Continue anyway?"; then
                    continue
                fi
            fi

            log_info "Target disk selected: ${TARGET_DISK}"
            break
        done
    fi

    log_success "Target disk confirmed: ${TARGET_DISK}"
}

# Enhanced partitioning with better error handling
partition_disk() {
    step "Disk partitioning"

    log_info "Target disk: ${TARGET_DISK}"
    log_warn "THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK"

    if ! confirm "Are you sure you want to continue?"; then
        abort "Installation cancelled by user"
    fi

    log_info "Partitioning disk ${TARGET_DISK}..."

    # Unmount any existing mounts
    if mount | grep -q "${TARGET_DISK}"; then
        log_info "Unmounting existing partitions..."
        umount "${TARGET_DISK}"* 2>/dev/null || true
    fi

    # Create partitions
    execute "sgdisk -Z ${TARGET_DISK}"
    execute "sgdisk -a 2048 -o ${TARGET_DISK}"
    execute "sgdisk -n 1::+${EFI_SIZE} --typecode=1:ef00 ${TARGET_DISK}"
    execute "sgdisk -n 2::-0 --typecode=2:8300 ${TARGET_DISK}"

    # Set partition variables based on disk type
    if [[ ${TARGET_DISK} =~ nvme ]]; then
        EFI_PARTITION="${TARGET_DISK}p1"
        ROOT_PARTITION="${TARGET_DISK}p2"
    else
        EFI_PARTITION="${TARGET_DISK}1"
        ROOT_PARTITION="${TARGET_DISK}2"
    fi

    save_var EFI_PARTITION "$EFI_PARTITION"
    save_var ROOT_PARTITION "$ROOT_PARTITION"

    # Wait for partition table to be re-read
    sleep 2
    partprobe "${TARGET_DISK}" || true

    log_success "Disk partitioned successfully"
}

# Enhanced LUKS setup
setup_luks_encryption() {
    step "Setting up LUKS encryption"

    log_info "Creating LUKS container on ${ROOT_PARTITION}..."

    # Setup LUKS with stronger defaults for LUKS2 if requested
    local luks_options="--type ${LUKS_TYPE}"
    if [[ "${LUKS_TYPE}" == "luks2" ]]; then
        luks_options+=" --pbkdf argon2id --iter-time 2000"
    fi

    if ! execute "cryptsetup -y -v ${luks_options} luksFormat ${ROOT_PARTITION}"; then
        abort "Failed to create LUKS container"
    fi

    log_info "Opening LUKS container..."
    CRYPTROOT_PATH="/dev/mapper/${CRYPTROOT_NAME}"

    if ! execute "cryptsetup open ${ROOT_PARTITION} ${CRYPTROOT_NAME}"; then
        abort "Failed to open LUKS container"
    fi

    save_var CRYPTROOT_NAME "$CRYPTROOT_NAME"
    save_var CRYPTROOT_PATH "$CRYPTROOT_PATH"

    log_success "LUKS encryption configured"
}

# Enhanced filesystem creation and mounting
create_filesystems() {
    step "Creating filesystems"

    log_info "Formatting EFI partition: ${EFI_PARTITION}"
    execute "mkfs.fat -F32 ${EFI_PARTITION}"

    # Create root filesystem based on type
    case "$FS_TYPE" in
        "btrfs")
            log_info "Formatting BTRFS root partition: ${CRYPTROOT_PATH}"
            execute "mkfs.btrfs -f ${CRYPTROOT_PATH}"
            create_btrfs_subvolumes
            ;;
        "ext4")
            log_info "Formatting EXT4 root partition: ${CRYPTROOT_PATH}"
            execute "mkfs.ext4 -F ${EXT4_FEATURES:+-O $EXT4_FEATURES} ${CRYPTROOT_PATH}"
            ;;
        "xfs")
            log_info "Formatting XFS root partition: ${CRYPTROOT_PATH}"
            execute "mkfs.xfs ${XFS_OPTIONS} ${CRYPTROOT_PATH}"
            ;;
        *)
            log_error "Unsupported filesystem type: $FS_TYPE"
            exit 1
            ;;
    esac

    # Save filesystem configuration for chroot scripts
    save_var FS_TYPE "$FS_TYPE"
    save_var BTRFS_CUSTOM_SUBVOLUMES "$BTRFS_CUSTOM_SUBVOLUMES"
    save_var COMPRESS_TYPE "$COMPRESS_TYPE"

    log_success "Filesystems created"
}

# Create BTRFS subvolumes based on configuration
create_btrfs_subvolumes() {
    log_info "Creating BTRFS subvolumes..."
    execute "mount ${CRYPTROOT_PATH} /mnt"

    # Parse custom subvolumes
    IFS=',' read -ra subvolumes <<< "$BTRFS_CUSTOM_SUBVOLUMES"

    # Ensure @ (root) is always first
    local root_created=false
    for subvol in "${subvolumes[@]}"; do
        subvol=$(echo "$subvol" | xargs)  # Trim whitespace
        if [[ "$subvol" == "@" ]]; then
            execute "btrfs subvolume create /mnt/@"
            root_created=true
            break
        fi
    done

    # Create @ if not found in custom list
    if [[ "$root_created" == "false" ]]; then
        execute "btrfs subvolume create /mnt/@"
    fi

    # Create other subvolumes
    for subvol in "${subvolumes[@]}"; do
        subvol=$(echo "$subvol" | xargs)  # Trim whitespace
        if [[ "$subvol" != "@" && -n "$subvol" ]]; then
            execute "btrfs subvolume create /mnt/${subvol}"
        fi
    done

    execute "umount /mnt"
}

# Enhanced filesystem mounting
mount_filesystems() {
    step "Mounting filesystems"

    case "$FS_TYPE" in
        "btrfs")
            mount_btrfs_filesystems
            ;;
        "ext4"|"xfs")
            mount_traditional_filesystems
            ;;
        *)
            log_error "Unsupported filesystem type for mounting: $FS_TYPE"
            exit 1
            ;;
    esac

    # Mount EFI partition
    execute "mount ${EFI_PARTITION} /mnt/boot/efi"

    # Validate all mounts
    validate_mounts

    log_success "Filesystems mounted successfully"
}

# Mount BTRFS with subvolumes
mount_btrfs_filesystems() {
    # Determine mount options based on SSD detection
    local mount_opts="$MOUNT_OPTIONS"
    if ! is_ssd "$TARGET_DISK"; then
        log_info "HDD detected, removing SSD-specific mount options"
        mount_opts="${mount_opts//,ssd/}"
        mount_opts="${mount_opts//,discard=async/}"
    fi

    # Update compression in mount options
    if [[ "$COMPRESS_TYPE" != "zstd" ]]; then
        mount_opts="${mount_opts//compress=zstd/compress=$COMPRESS_TYPE}"
    fi

    # Remove compression if set to none
    if [[ "$COMPRESS_TYPE" == "none" ]]; then
        mount_opts="${mount_opts//,compress=$COMPRESS_TYPE/}"
    fi

    log_info "Mounting root filesystem..."
    execute "mount -o ${mount_opts},subvol=@ ${CRYPTROOT_PATH} /mnt"

    # Create mount point directories and mount subvolumes
    IFS=',' read -ra subvolumes <<< "$BTRFS_CUSTOM_SUBVOLUMES"

    for subvol in "${subvolumes[@]}"; do
        subvol=$(echo "$subvol" | xargs)  # Trim whitespace
        case "$subvol" in
            "@")
                # Already mounted as root
                ;;
            "@home")
                execute "mkdir -p /mnt/home"
                execute "mount -o ${mount_opts},subvol=@home ${CRYPTROOT_PATH} /mnt/home"
                ;;
            "@snapshots")
                execute "mkdir -p /mnt/.snapshots"
                execute "mount -o ${mount_opts},subvol=@snapshots ${CRYPTROOT_PATH} /mnt/.snapshots"
                ;;
            "@log")
                execute "mkdir -p /mnt/var/log"
                execute "mount -o ${mount_opts},subvol=@log ${CRYPTROOT_PATH} /mnt/var/log"
                ;;
            "@cache")
                execute "mkdir -p /mnt/var/cache"
                execute "mount -o ${mount_opts},subvol=@cache ${CRYPTROOT_PATH} /mnt/var/cache"
                ;;
            "@swap")
                execute "mkdir -p /mnt/swap"
                execute "mount -o ${mount_opts},subvol=@swap ${CRYPTROOT_PATH} /mnt/swap"
                ;;
            "@opt")
                execute "mkdir -p /mnt/opt"
                execute "mount -o ${mount_opts},subvol=@opt ${CRYPTROOT_PATH} /mnt/opt"
                ;;
            "@srv")
                execute "mkdir -p /mnt/srv"
                execute "mount -o ${mount_opts},subvol=@srv ${CRYPTROOT_PATH} /mnt/srv"
                ;;
            "@tmp")
                execute "mkdir -p /mnt/tmp"
                execute "mount -o ${mount_opts},subvol=@tmp ${CRYPTROOT_PATH} /mnt/tmp"
                ;;
        esac
    done

    # Always create boot directory
    execute "mkdir -p /mnt/boot/efi"
}

# Mount traditional filesystems (ext4, xfs)
mount_traditional_filesystems() {
    local mount_opts="defaults,noatime"

    # Add SSD optimizations if applicable
    if is_ssd "$TARGET_DISK"; then
        case "$FS_TYPE" in
            "ext4")
                mount_opts="${mount_opts},discard"
                ;;
            "xfs")
                mount_opts="${mount_opts},discard"
                ;;
        esac
    fi

    log_info "Mounting root filesystem..."
    execute "mount -o ${mount_opts} ${CRYPTROOT_PATH} /mnt"

    # Create standard directory structure
    local dirs=("boot/efi" "home" "var/log" "var/cache" "tmp" "opt" "srv")
    for dir in "${dirs[@]}"; do
        execute "mkdir -p /mnt/${dir}"
    done
}

# Enhanced package installation
install_base_packages() {
    step "Installing base packages"

    local packages="$BASE_PACKAGES $ESSENTIAL_PACKAGES"
    log_info "Installing packages: $packages"

    if ! retry 3 5 "pacstrap /mnt $packages --noconfirm --needed"; then
        abort "Failed to install base packages"
    fi

    log_success "Base packages installed successfully"
}

# Enhanced fstab generation
generate_fstab() {
    step "Generating fstab"

    execute "genfstab -U /mnt >> /mnt/etc/fstab"

    # Verify fstab was generated correctly
    if [[ ! -s /mnt/etc/fstab ]]; then
        abort "Failed to generate fstab"
    fi

    log_info "Generated fstab:"
    cat /mnt/etc/fstab

    log_success "fstab generated successfully"
}

# Enhanced swapfile creation
create_swapfile() {
    if [[ "${SWAPFILE_ENABLED}" != "true" ]]; then
        log_info "Swapfile creation disabled"
        return 0
    fi

    step "Creating swapfile"

    # Calculate swap size if not specified
    if [[ -z "${SWAPFILE_SIZE_MB}" ]]; then
        SWAPFILE_SIZE_MB=$(calculate_swap_size)
        log_info "Calculated swap size: ${SWAPFILE_SIZE_MB}MB"
    fi

    save_var SWAPFILE_SIZE_MB "$SWAPFILE_SIZE_MB"

    # Create swapfile with filesystem-specific handling
    case "$FS_TYPE" in
        "btrfs")
            # Check if @swap subvolume exists, otherwise use root
            if echo "$BTRFS_CUSTOM_SUBVOLUMES" | grep -q "@swap"; then
                local swap_path="/mnt/swap"
                # BTRFS requires no-copy-on-write for swapfiles
                execute "chattr +C ${swap_path}/"
                execute "truncate -s 0 ${swap_path}/swapfile"
                execute "dd if=/dev/zero of=${swap_path}/swapfile bs=1M count=${SWAPFILE_SIZE_MB} status=progress"
                local fstab_path="/swap/swapfile"
            else
                local swap_path="/mnt"
                execute "truncate -s 0 ${swap_path}/swapfile"
                execute "dd if=/dev/zero of=${swap_path}/swapfile bs=1M count=${SWAPFILE_SIZE_MB} status=progress"
                local fstab_path="/swapfile"
            fi
            ;;
        "ext4"|"xfs")
            local swap_path="/mnt"
            execute "dd if=/dev/zero of=${swap_path}/swapfile bs=1M count=${SWAPFILE_SIZE_MB} status=progress"
            local fstab_path="/swapfile"
            ;;
        *)
            log_error "Swapfile creation not supported for filesystem type: $FS_TYPE"
            return 1
            ;;
    esac

    execute "chmod 600 ${swap_path}/swapfile"
    execute "mkswap ${swap_path}/swapfile"
    execute "swapon ${swap_path}/swapfile"

    # Add to fstab
    echo "${fstab_path} none swap defaults 0 0" >> /mnt/etc/fstab

    log_success "Swapfile created and configured"
}

# Enhanced LUKS keyfile setup
setup_luks_keyfile() {
    if [[ "${LUKS_KEYFILE_ENABLED}" != "true" ]]; then
        log_info "LUKS keyfile setup disabled"
        return 0
    fi

    step "Setting up LUKS keyfile"

    log_info "Creating LUKS keyfile..."
    execute "dd bs=512 count=4 if=/dev/random of=/mnt${KEYFILE_PATH} iflag=fullblock"
    execute "chmod 600 /mnt${KEYFILE_PATH}"
    execute "chmod 600 /mnt/boot/initramfs-linux*"

    log_info "Adding LUKS keyfile to container..."
    if ! execute "cryptsetup luksAddKey ${ROOT_PARTITION} /mnt${KEYFILE_PATH}"; then
        log_warn "Failed to add LUKS keyfile, continuing without it"
        rm -f "/mnt${KEYFILE_PATH}"
        return 0
    fi

    save_var KEYFILE_PATH "$KEYFILE_PATH"

    log_success "LUKS keyfile configured"
}

# Enhanced chroot preparation
prepare_chroot() {
    step "Preparing chroot environment"

    # Copy essential files
    local files_to_copy=(
        "/etc/pacman.d/mirrorlist:/mnt/etc/pacman.d/mirrorlist"
        "install-arch-base-utils.sh:/mnt/"
        "arch-chroot-setup.sh:/mnt/"
        "arch-chroot-user.sh:/mnt/"
        "arch-chroot-postsetup.sh:/mnt/"
        ".env:/mnt/"
        ".bashrc:/mnt/root/"
    )

    for file_mapping in "${files_to_copy[@]}"; do
        local src="${file_mapping%:*}"
        local dest="${file_mapping#*:}"

        if [[ -f "$src" ]]; then
            execute "cp $src $dest"
        else
            log_warn "File not found: $src"
        fi
    done

    log_success "Chroot environment prepared"
}

# Enhanced chroot execution
run_chroot_scripts() {
    step "Running chroot installation scripts"

    # Execute setup script
    log_info "Running arch-chroot-setup.sh..."
    if ! execute "arch-chroot /mnt /arch-chroot-setup.sh"; then
        abort "Failed to execute arch-chroot-setup.sh"
    fi

    # Source environment variables
    if [[ -f /mnt/.env ]]; then
        source /mnt/.env
    fi

    # Execute user script if username is set
    if [[ -n "${USERNAME:-}" ]]; then
        log_info "Running arch-chroot-user.sh as ${USERNAME}..."
        if ! execute "arch-chroot /mnt /usr/bin/runuser -u ${USERNAME} -- /home/${USERNAME}/arch-chroot-user.sh"; then
            log_warn "Failed to execute arch-chroot-user.sh"
        fi
    fi

    # Execute post-setup script
    log_info "Running arch-chroot-postsetup.sh..."
    if ! execute "arch-chroot /mnt /arch-chroot-postsetup.sh"; then
        log_warn "Failed to execute arch-chroot-postsetup.sh"
    fi

    log_success "Chroot scripts completed"
}

# Enhanced cleanup
perform_cleanup() {
    step "Cleaning up temporary files"

    local files_to_remove=(
        "/mnt/install-arch-base-utils.sh"
        "/mnt/arch-chroot-setup.sh"
        "/mnt/arch-chroot-user.sh"
        "/mnt/arch-chroot-postsetup.sh"
    )

    for file in "${files_to_remove[@]}"; do
        if [[ -f "$file" ]]; then
            execute "rm $file"
        fi
    done

    # Move environment file to user directory if username exists
    if [[ -n "${USERNAME:-}" && -f "/mnt/.env" ]]; then
        execute "mv /mnt/.env /mnt/home/${USERNAME}/"
    fi

    # Remove user-specific duplicate files
    if [[ -n "${USERNAME:-}" ]]; then
        rm -f "/mnt/home/${USERNAME}/install-arch-base-utils.sh"
        rm -f "/mnt/home/${USERNAME}/arch-chroot-user.sh"
    fi

    log_success "Cleanup completed"
}

# Main installation function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    # Load custom config if specified
    if [[ -n "${CONFIG_FILE:-}" ]]; then
        if [[ -f "$CONFIG_FILE" ]]; then
            source "$CONFIG_FILE"
        else
            abort "Configuration file not found: $CONFIG_FILE"
        fi
    fi

    # Set total steps for progress tracking
    set_total_steps 12

    # Display banner
    clear
    printf "${tty_blue}==>${tty_bold} Starting Arch-Base Installation${tty_reset}\n"
    printf "Configuration: %s\n" "${CONFIG_FILE:-default}"
    printf "Log file: %s\n" "$LOG_FILE"
    echo

    # Run installation steps
    preflight_checks
    download_dependencies
    setup_time
    setup_mirrors
    select_target_disk
    partition_disk
    setup_luks_encryption
    create_filesystems
    mount_filesystems
    install_base_packages
    generate_fstab
    create_swapfile
    setup_luks_keyfile
    prepare_chroot
    run_chroot_scripts
    perform_cleanup

    # Final success message
    log_success "Arch-Base installation completed successfully!"

    printf "${tty_green}Installation completed!${tty_reset}\n"
    printf "Next steps:\n"
    printf "  - Run ${tty_bold}reboot${tty_reset} to start your new system\n"
    printf "  - Check log file: %s\n" "$LOG_FILE"
    echo

    if [[ "${SKIP_REBOOT:-false}" != "true" ]]; then
        if confirm "Reboot now?" "y"; then
            execute "reboot"
        fi
    fi
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
