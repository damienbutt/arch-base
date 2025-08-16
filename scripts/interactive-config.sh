#!/bin/bash

# Interactive Configuration Wizard using Gum
# This script provides a beautiful, interactive way to configure the Arch-Base installation

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/common.sh"

# Ensure gum is available (install if needed)
ensure_gum_for_interactive() {
    echo "🔧 Preparing interactive configuration wizard..."

    if ! ensure_gum; then
        echo ""
        echo "❌ Could not install gum automatically."
        echo ""
        echo "📦 Manual installation options:"
        echo "  • Arch Linux: sudo pacman -S gum"
        echo "  • Ubuntu/Debian: sudo apt install gum"
        echo "  • Fedora: sudo dnf install gum"
        echo "  • macOS: brew install gum"
        echo "  • Manual: https://github.com/charmbracelet/gum/releases"
        echo ""
        echo "💡 Alternatively, you can use non-interactive configuration."
        exit 1
    fi

    echo "✅ Interactive interface ready!"
    echo ""
}

# Display welcome screen
show_welcome() {
    gum style \
        --foreground 212 --border-foreground 212 --border double \
        --align center --width 50 --margin "1 2" --padding "2 4" \
        'Arch-Base Installation' 'Interactive Configuration Wizard'

    gum format -- "Welcome to the **Arch-Base** installation wizard!"
    echo ""
    gum format -- "This wizard will help you configure your Arch Linux installation with a beautiful, interactive interface."
    echo ""

    if ! gum confirm "Continue with interactive configuration?"; then
        echo "Configuration cancelled."
        exit 0
    fi
}

# Get system configuration
configure_system() {
    gum style --foreground 86 "📱 System Configuration"
    echo ""

    # Hostname
    HOSTNAME=$(gum input --placeholder "Enter hostname (e.g., arch-base)" --value "${HOSTNAME:-arch-base}")

    # Timezone selection
    echo ""
    gum format -- "**Timezone Selection**"
    TIMEZONE_REGION=$(gum choose --height 10 \
        "America" "Europe" "Asia" "Africa" "Australia" "Atlantic" "Indian" "Pacific" "UTC")

    if [[ "$TIMEZONE_REGION" != "UTC" ]]; then
        # Get available cities for the region
        cities=($(find /usr/share/zoneinfo/"$TIMEZONE_REGION" -type f -printf "%f\n" 2>/dev/null | sort | head -20))
        if [[ ${#cities[@]} -gt 0 ]]; then
            TIMEZONE_CITY=$(gum choose --height 15 "${cities[@]}")
            TIMEZONE="$TIMEZONE_REGION/$TIMEZONE_CITY"
        else
            TIMEZONE="$TIMEZONE_REGION"
        fi
    else
        TIMEZONE="UTC"
    fi

    # Locale
    echo ""
    gum format -- "**Locale Selection**"
    LOCALE=$(gum choose --height 10 \
        "en_US.UTF-8" "en_GB.UTF-8" "de_DE.UTF-8" "fr_FR.UTF-8" "es_ES.UTF-8" \
        "it_IT.UTF-8" "pt_PT.UTF-8" "ru_RU.UTF-8" "ja_JP.UTF-8" "zh_CN.UTF-8" \
        "Custom...")

    if [[ "$LOCALE" == "Custom..." ]]; then
        LOCALE=$(get_validated_input "Enter custom locale (e.g., sv_SE.UTF-8)" "validate_locale" "" "Enter custom locale (e.g., sv_SE.UTF-8)")
    fi

    # Keymap
    echo ""
    gum format -- "**Keyboard Layout**"
    KEYMAP=$(gum choose --height 10 \
        "us" "uk" "de" "fr" "es" "it" "pt" "ru" "jp" "Custom...")

    if [[ "$KEYMAP" == "Custom..." ]]; then
        KEYMAP=$(get_validated_input "Enter keymap code (e.g., dvorak)" "validate_keymap" "" "Enter keymap code (e.g., dvorak)")
    fi
}

# Get user configuration
configure_user() {
    gum style --foreground 86 "👤 User Configuration"
    echo ""

    # Username with enhanced validation
    USERNAME=$(get_validated_input "Enter username" "validate_username" "${USERNAME:-}" "Enter username")

    # User groups
    echo ""
    gum format -- "**Additional User Groups**"
    gum format -- "Select additional groups for user **$USERNAME**:"

    selected_groups=($(gum choose --no-limit --height 10 \
        "wheel" "audio" "video" "storage" "optical" "lp" "scanner" "games"))

    # Always include wheel group
    if [[ ! " ${selected_groups[*]} " =~ " wheel " ]]; then
        selected_groups+=("wheel")
    fi

    USER_GROUPS=$(IFS=,; echo "${selected_groups[*]}")
}

# Get disk configuration
configure_disk() {
    gum style --foreground 86 "💾 Disk Configuration"
    echo ""

    # Show available disks
    gum format -- "**Available Disks:**"
    lsblk -o NAME,SIZE,TYPE,MODEL | grep disk | gum format --type code
    echo ""

    # Disk selection
    available_disks=($(lsblk -dno NAME | grep -E '^(sd|nvme|vd)' | sed 's|^|/dev/|'))
    if [[ ${#available_disks[@]} -eq 0 ]]; then
        gum style --foreground 196 "No suitable disks found!"
        exit 1
    fi

    TARGET_DISK=$(gum choose --header "Select target disk:" "${available_disks[@]}")

    # Warning about data loss
    gum style --foreground 196 --border-foreground 196 --border thick \
        --align center --width 60 --margin "1 2" --padding "1 2" \
        "⚠️  WARNING ⚠️" "" "This will completely erase:" "$TARGET_DISK" "" "ALL DATA WILL BE LOST!"

    if ! gum confirm "Continue with disk $TARGET_DISK?"; then
        gum style --foreground 196 "Disk selection cancelled."
        exit 1
    fi

    # EFI partition size
    echo ""
    EFI_SIZE=$(gum choose --header "EFI partition size:" \
        "260M" "512M" "1G" "Custom...")

    if [[ "$EFI_SIZE" == "Custom..." ]]; then
        EFI_SIZE=$(get_validated_input "Enter EFI partition size (e.g., 512M)" "validate_partition_size" "" "Enter EFI partition size (e.g., 512M)")
    fi

    # LUKS encryption type
    echo ""
    gum format -- "**Encryption Configuration**"
    LUKS_TYPE=$(gum choose --header "LUKS encryption type:" \
        "luks2" "luks1")

    gum format -- "**LUKS2** is newer with stronger security, **LUKS1** has better compatibility with older systems."

    # Cryptroot name with validation
    echo ""
    CRYPTROOT_NAME=$(get_validated_input "LUKS container name" "validate_container_name" "${CRYPTROOT_NAME:-cryptroot}" "LUKS container name")

    # Filesystem configuration
    echo ""
    gum format -- "**Filesystem Configuration**"
    FS_TYPE=$(gum choose --header "Root filesystem type:" \
        "btrfs" "ext4" "xfs")

    # BTRFS specific configuration
    if [[ "$FS_TYPE" == "btrfs" ]]; then
        echo ""
        gum format -- "**BTRFS Subvolume Layout**"
        BTRFS_SUBVOLUME_LAYOUT=$(gum choose --header "Choose subvolume layout:" \
            "Default (@ @home @snapshots @log @cache @swap)" \
            "Minimal (@ @home)" \
            "Custom (manual selection)")

        case "$BTRFS_SUBVOLUME_LAYOUT" in
            "Default (@ @home @snapshots @log @cache @swap)")
                BTRFS_SUBVOLUME_LAYOUT="default"
                BTRFS_CUSTOM_SUBVOLUMES="@,@home,@snapshots,@log,@cache,@swap"
                ;;
            "Minimal (@ @home)")
                BTRFS_SUBVOLUME_LAYOUT="minimal"
                BTRFS_CUSTOM_SUBVOLUMES="@,@home"
                ;;
            "Custom (manual selection)")
                BTRFS_SUBVOLUME_LAYOUT="custom"
                echo ""
                gum format -- "**Custom Subvolumes**"
                gum format -- "Available subvolumes (select any you want):"
                gum format -- "• **@** - Root filesystem (always included)"
                gum format -- "• **@home** - User home directories"
                gum format -- "• **@snapshots** - System snapshots"
                gum format -- "• **@log** - System logs (/var/log)"
                gum format -- "• **@cache** - Package cache (/var/cache)"
                gum format -- "• **@swap** - Swap file location"
                gum format -- "• **@opt** - Optional software (/opt)"
                gum format -- "• **@srv** - Service data (/srv)"
                gum format -- "• **@tmp** - Temporary files (/tmp)"

                selected_subvolumes=($(gum choose --no-limit --height 12 \
                    "@home" "@snapshots" "@log" "@cache" "@swap" "@opt" "@srv" "@tmp"))

                # @ is always included
                BTRFS_CUSTOM_SUBVOLUMES="@"
                if [[ ${#selected_subvolumes[@]} -gt 0 ]]; then
                    for subvol in "${selected_subvolumes[@]}"; do
                        BTRFS_CUSTOM_SUBVOLUMES="${BTRFS_CUSTOM_SUBVOLUMES},${subvol}"
                    done
                fi
                ;;
        esac

        # BTRFS compression
        echo ""
        COMPRESS_TYPE=$(gum choose --header "BTRFS compression:" \
            "zstd" "lzo" "zlib" "none")
    fi
}

# Get package configuration
configure_packages() {
    gum style --foreground 86 "📦 Package Configuration"
    echo ""

    # Installation mode selection
    gum format -- "**Installation Mode**"
    INSTALL_MODE=$(gum choose --header "Choose installation mode:" \
        "Minimal (essential packages only)" \
        "Standard (essential + optional packages)" \
        "Complete (essential + optional + security)" \
        "Custom (manual selection)")

    # Determine filesystem tools needed
    local fs_tools=""
    case "$FS_TYPE" in
        "btrfs")
            fs_tools="btrfs-progs"
            ;;
        "ext4")
            fs_tools="e2fsprogs"
            ;;
        "xfs")
            fs_tools="xfsprogs"
            ;;
    esac

    case "$INSTALL_MODE" in
        "Minimal (essential packages only)")
            MINIMAL_INSTALL="true"
            INSTALL_OPTIONAL_PACKAGES="false"
            INSTALL_SECURITY_PACKAGES="false"
            ESSENTIAL_PACKAGES="$fs_tools"
            ;;
        "Standard (essential + optional packages)")
            MINIMAL_INSTALL="false"
            INSTALL_OPTIONAL_PACKAGES="true"
            INSTALL_SECURITY_PACKAGES="false"
            ESSENTIAL_PACKAGES="$fs_tools"
            ;;
        "Complete (essential + optional + security)")
            MINIMAL_INSTALL="false"
            INSTALL_OPTIONAL_PACKAGES="true"
            INSTALL_SECURITY_PACKAGES="true"
            ESSENTIAL_PACKAGES="$fs_tools"
            ;;
        "Custom (manual selection)")
            MINIMAL_INSTALL="false"

            # Ask about optional packages
            echo ""
            gum format -- "**Optional Packages** include:"
            gum format -- "• Development tools (base-devel, linux-headers)"
            gum format -- "• System utilities (acpi, snapper, terminus-font)"
            gum format -- "• Text editor (vim)"
            gum format -- "• Network utilities (dnsutils, inetutils)"

            if gum confirm "Install optional packages?"; then
                INSTALL_OPTIONAL_PACKAGES="true"
            else
                INSTALL_OPTIONAL_PACKAGES="false"
            fi

            # Ask about security packages
            echo ""
            gum format -- "**Security Packages** include:"
            gum format -- "• Simple firewall (ufw)"
            gum format -- "• Mandatory Access Control (apparmor)"

            if gum confirm "Install security packages?"; then
                INSTALL_SECURITY_PACKAGES="true"
            else
                INSTALL_SECURITY_PACKAGES="false"
            fi

            # Ask about additional packages
            echo ""
            if gum confirm "Select additional system packages?"; then
                selected_packages=($(gum choose --no-limit --height 12 \
                    "git" "vim" "nano" "wget" "curl" "rsync" \
                    "htop" "tree" "unzip" "which" "man-db" "man-pages"))

                if [[ ${#selected_packages[@]} -gt 0 ]]; then
                    ESSENTIAL_PACKAGES="$fs_tools $(IFS=' '; echo "${selected_packages[*]}")"
                else
                    ESSENTIAL_PACKAGES="$fs_tools"
                fi
            else
                ESSENTIAL_PACKAGES="$fs_tools"
            fi
            ;;
    esac    # Show what will be installed
    echo ""
    gum style --foreground 82 "📋 Package Summary:"
    if [[ "$MINIMAL_INSTALL" == "true" ]]; then
        gum format -- "**Mode**: Ultra-minimal (essential packages only)"
    else
        gum format -- "**Mode**: Standard installation"
        gum format -- "• Optional packages: $([ "$INSTALL_OPTIONAL_PACKAGES" == "true" ] && echo "Yes" || echo "No")"
        gum format -- "• Security packages: $([ "$INSTALL_SECURITY_PACKAGES" == "true" ] && echo "Yes" || echo "No")"
    fi
    gum format -- "• Additional packages: $ESSENTIAL_PACKAGES"

    # Additional custom packages with validation
    echo ""
    if gum confirm "Add any custom packages?"; then
        additional=$(get_validated_input "Enter package names (space-separated)" "validate_package_names" "" "Enter package names (space-separated)")
        if [[ -n "$additional" ]]; then
            ESSENTIAL_PACKAGES="$ESSENTIAL_PACKAGES $additional"
        fi
    fi
}

# Get installation behavior
configure_behavior() {
    gum style --foreground 86 "⚙️  Installation Behavior"
    echo ""

    # Swap configuration
    gum format -- "**Swap Configuration**"
    if gum confirm "Enable swap file?"; then
        SWAPFILE_ENABLED="true"

        # Swap size
        SWAP_PRESET=$(gum choose --header "Swap size:" \
            "Auto (RAM + 2GB)" \
            "Equal to RAM" \
            "Half of RAM" \
            "Custom size")

        case "$SWAP_PRESET" in
            "Auto (RAM + 2GB)")
                SWAPFILE_SIZE_MB=""
                ;;
            "Equal to RAM")
                SWAPFILE_SIZE_MB=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
                ;;
            "Half of RAM")
                SWAPFILE_SIZE_MB=$(awk '/MemTotal/ {print int($2/2048)}' /proc/meminfo)
                ;;
            "Custom size")
                SWAPFILE_SIZE_MB=$(get_validated_input "Enter swap size in MB" "validate_swap_size" "" "Enter swap size in MB")
                ;;
        esac
    else
        SWAPFILE_ENABLED="false"
    fi

    # LUKS keyfile
    echo ""
    gum format -- "**Security Options**"
    if gum confirm "Create LUKS keyfile for automatic boot unlocking?"; then
        LUKS_KEYFILE_ENABLED="true"
    else
        LUKS_KEYFILE_ENABLED="false"
    fi

    # Installation mode
    echo ""
    gum format -- "**Installation Mode**"
    if gum confirm "Skip reboot after installation?"; then
        SKIP_REBOOT="true"
    else
        SKIP_REBOOT="false"
    fi
}

# Show configuration summary
show_summary() {
    gum style --foreground 86 "📋 Configuration Summary"
    echo ""

    # Create summary text
    summary=$(cat << EOF
**System Configuration:**
• Hostname: $HOSTNAME
• Timezone: $TIMEZONE
• Locale: $LOCALE
• Keymap: $KEYMAP

**User Configuration:**
• Username: $USERNAME
• Groups: $USER_GROUPS

**Disk Configuration:**
• Target Disk: $TARGET_DISK
• EFI Size: $EFI_SIZE
• LUKS Type: $LUKS_TYPE
• Container Name: $CRYPTROOT_NAME

**Filesystem Configuration:**
• Type: $FS_TYPE
$(if [[ "$FS_TYPE" == "btrfs" ]]; then
echo "• Compression: $COMPRESS_TYPE"
echo "• Subvolumes: $BTRFS_CUSTOM_SUBVOLUMES"
fi)

**Packages:**
• Essential: $ESSENTIAL_PACKAGES

**Installation Options:**
• Swap Enabled: $SWAPFILE_ENABLED
$(if [[ -n "$SWAPFILE_SIZE_MB" ]]; then echo "• Swap Size: ${SWAPFILE_SIZE_MB}MB"; fi)
• LUKS Keyfile: $LUKS_KEYFILE_ENABLED
• Skip Reboot: $SKIP_REBOOT
EOF
)

    gum format -- "$summary"
    echo ""

    if ! gum confirm "Proceed with this configuration?"; then
        if gum confirm "Do you want to reconfigure?"; then
            main
            return
        else
            echo "Configuration cancelled."
            exit 0
        fi
    fi
}

# Save configuration
save_configuration() {
    local config_file="$SCRIPT_DIR/config.local.sh"

    cat > "$config_file" << EOF
#!/bin/bash

# Arch-Base Installation Configuration
# Generated by interactive wizard on $(date)

# System Configuration
HOSTNAME="$HOSTNAME"
TIMEZONE="$TIMEZONE"
LOCALE="$LOCALE"
KEYMAP="$KEYMAP"

# User Configuration
USERNAME="$USERNAME"
USER_GROUPS="$USER_GROUPS"

# Disk Configuration
TARGET_DISK="$TARGET_DISK"
EFI_SIZE="$EFI_SIZE"
LUKS_TYPE="$LUKS_TYPE"
CRYPTROOT_NAME="$CRYPTROOT_NAME"

# Package Configuration
ESSENTIAL_PACKAGES="$ESSENTIAL_PACKAGES"

# Installation Behavior
SWAPFILE_ENABLED="$SWAPFILE_ENABLED"
$(if [[ -n "$SWAPFILE_SIZE_MB" ]]; then echo "SWAPFILE_SIZE_MB=\"$SWAPFILE_SIZE_MB\""; fi)
LUKS_KEYFILE_ENABLED="$LUKS_KEYFILE_ENABLED"
SKIP_REBOOT="$SKIP_REBOOT"

# Set installation mode
INTERACTIVE_MODE="false"
AUTO_CONFIRM="true"
EOF

    gum style --foreground 212 "✅ Configuration saved to: $config_file"
    echo ""

    # Ask about starting installation
    if gum confirm "Start installation now?"; then
        gum style --foreground 86 "🚀 Starting Arch-Base installation..."
        echo ""
        exec "$SCRIPT_DIR/arch-base-install.sh" -c "$config_file"
    else
        gum format -- "Configuration saved! You can start the installation later with:"
        gum format --type code -- "sudo $SCRIPT_DIR/arch-base-install.sh -c $config_file"
    fi
}

# Main function
main() {
    ensure_gum_for_interactive
    show_welcome
    configure_system
    configure_user
    configure_disk
    configure_packages
    configure_behavior
    show_summary
    save_configuration
}

# Run main function
main "$@"
