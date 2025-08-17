#!/bin/bash

# Simple demo script that simulates the BubbleTea TUI prototype
# This demonstrates the concept without requiring Go dependencies

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Unicode characters for better visual appearance
CHECK="✅"
ARROW="➤"
STAR="⭐"
GEAR="⚙️"
DISK="💾"
USER="👤"
PACKAGE="📦"
SUMMARY="📋"

clear

# Function to create a bordered box
create_box() {
    local title="$1"
    local content="$2"
    local width=80

    echo -e "${PURPLE}╭$(printf '─%.0s' $(seq 1 $((width-2))))╮${NC}"
    echo -e "${PURPLE}│${NC} ${WHITE}${title}${NC}$(printf ' %.0s' $(seq 1 $((width-${#title}-3))))${PURPLE}│${NC}"
    echo -e "${PURPLE}├$(printf '─%.0s' $(seq 1 $((width-2))))┤${NC}"

    while IFS= read -r line; do
        local padded_line="$line$(printf ' %.0s' $(seq 1 $((width-${#line}-3))))"
        echo -e "${PURPLE}│${NC} $padded_line ${PURPLE}│${NC}"
    done <<< "$content"

    echo -e "${PURPLE}╰$(printf '─%.0s' $(seq 1 $((width-2))))╯${NC}"
}

# Function to show progress
show_progress() {
    local current="$1"
    local total="$2"
    local step_name="$3"

    echo -e "\n${BLUE}Progress: ${current}/${total} - ${step_name}${NC}"

    # Progress bar
    local filled=$((current * 50 / total))
    local empty=$((50 - filled))

    printf "${GREEN}["
    printf "█%.0s" $(seq 1 $filled)
    printf "░%.0s" $(seq 1 $empty)
    printf "]${NC} %d%%\n" $((current * 100 / total))
}

# Welcome screen
welcome_screen() {
    clear
    create_box "🎉 Arch-Base TUI Installer Prototype" "
${STAR} Welcome to the BubbleTea-powered configuration wizard!

${GREEN}This prototype demonstrates:${NC}
${ARROW} Beautiful terminal user interface
${ARROW} Step-by-step configuration workflow
${ARROW} Real-time validation and feedback
${ARROW} Professional-grade visual components
${ARROW} Seamless integration with existing bash scripts

${YELLOW}In the full BubbleTea version, you would see:${NC}
${ARROW} Interactive forms with tab navigation
${ARROW} Real-time input validation
${ARROW} Dropdown menus and checkboxes
${ARROW} Smooth transitions between screens
${ARROW} Mouse support and vim-like keybindings
${ARROW} Progress indicators and status updates

${CYAN}Press Enter to continue...${NC}"

    read -r
}

# System configuration screen
system_screen() {
    clear
    show_progress 1 5 "System Configuration"

    create_box "${GEAR} System Configuration" "
Configure basic system settings:

${BLUE}Hostname:${NC}     arch-desktop
${BLUE}Timezone:${NC}     America/New_York
${BLUE}Locale:${NC}       en_US.UTF-8
${BLUE}Keymap:${NC}       us

${GREEN}In BubbleTea version:${NC}
${ARROW} Interactive text inputs with validation
${ARROW} Dropdown menus for timezone/locale selection
${ARROW} Real-time hostname validation (no spaces/special chars)
${ARROW} Tab completion for common values
${ARROW} Visual focus indicators and field highlighting

${CYAN}Press Enter to continue...${NC}"

    read -r
}

# User configuration screen
user_screen() {
    clear
    show_progress 2 5 "User Configuration"

    create_box "${USER} User Configuration" "
Configure your user account:

${BLUE}Username:${NC}         damien
${BLUE}User Groups:${NC}      wheel, audio, video, storage
${BLUE}Password:${NC}         [Protected Input]

${GREEN}In BubbleTea version:${NC}
${ARROW} Username validation (no special characters)
${ARROW} Multi-select checkboxes for user groups
${ARROW} Secure password input with strength indicator
${ARROW} Password confirmation with visual feedback
${ARROW} Real-time validation messages

${CYAN}Press Enter to continue...${NC}"

    read -r
}

# Disk configuration screen
disk_screen() {
    clear
    show_progress 3 5 "Disk Configuration"

    create_box "${DISK} Disk Configuration" "
Configure disk partitioning and encryption:

${BLUE}Target Disk:${NC}      /dev/nvme0n1 (512GB NVMe)
${BLUE}EFI Size:${NC}         512M
${BLUE}Filesystem:${NC}       BTRFS with compression
${BLUE}Encryption:${NC}       LUKS2 enabled
${BLUE}Swap:${NC}             4GB swapfile

${GREEN}In BubbleTea version:${NC}
${ARROW} Visual disk selection with size information
${ARROW} Real-time disk usage preview
${ARROW} Interactive partition size sliders
${ARROW} Encryption options with security explanations
${ARROW} Filesystem-specific configuration panels

${YELLOW}${ARROW} WARNING: Destructive operation visual indicators${NC}

${CYAN}Press Enter to continue...${NC}"

    read -r
}

# Package configuration screen
package_screen() {
    clear
    show_progress 4 5 "Package Selection"

    create_box "${PACKAGE} Package Configuration" "
Select installation mode and packages:

${BLUE}Installation Mode:${NC} Standard
${BLUE}Desktop Environment:${NC} KDE Plasma
${BLUE}Additional Packages:${NC}
  ${CHECK} Development tools
  ${CHECK} Media codecs
  ${CHECK} Gaming support

${GREEN}In BubbleTea version:${NC}
${ARROW} Filterable package list with search
${ARROW} Category-based package browser
${ARROW} Dependency resolution preview
${ARROW} Package size and description display
${ARROW} Custom package group creation

${CYAN}Press Enter to continue...${NC}"

    read -r
}

# Summary screen
summary_screen() {
    clear
    show_progress 5 5 "Configuration Summary"

    create_box "${SUMMARY} Configuration Summary" "
${WHITE}Review your installation configuration:${NC}

${BLUE}System:${NC}
  Hostname: arch-desktop
  Timezone: America/New_York
  Locale: en_US.UTF-8

${BLUE}User:${NC}
  Username: damien
  Groups: wheel, audio, video, storage

${BLUE}Disk:${NC}
  Target: /dev/nvme0n1
  Filesystem: BTRFS + LUKS2
  EFI: 512M, Swap: 4GB

${BLUE}Packages:${NC}
  Mode: Standard + KDE Plasma
  Extras: dev-tools, codecs, gaming

${GREEN}${ARROW} Configuration will be saved to config.local.sh${NC}
${GREEN}${ARROW} Compatible with existing installation scripts${NC}

${CYAN}Press Enter to generate configuration...${NC}"

    read -r
}

# Generate config
generate_config() {
    clear
    echo -e "${GREEN}${CHECK} Generating configuration file...${NC}"
    sleep 1

    # Create a sample config file
    cat > ../scripts/config.local.sh << 'EOF'
#!/bin/bash
# Generated by Arch-Base TUI Configuration Wizard (Prototype)

# System Configuration
HOSTNAME="arch-desktop"
TIMEZONE="America/New_York"
LOCALE="en_US.UTF-8"
KEYMAP="us"

# User Configuration
USERNAME="damien"
USER_GROUPS="wheel,audio,video,storage"

# Disk Configuration
TARGET_DISK="/dev/nvme0n1"
EFI_SIZE="512M"
CRYPTROOT_NAME="cryptroot"
FS_TYPE="btrfs"
BTRFS_SUBVOLUME_LAYOUT="default"
COMPRESS_TYPE="zstd"
SWAPFILE_ENABLED="true"
SWAPFILE_SIZE_MB="4096"

# Package Configuration
INSTALL_MODE="standard"
ESSENTIAL_PACKAGES="plasma-meta konsole dolphin firefox"

# Installation Behavior
AUTO_REBOOT="false"
SKIP_NON_FREE="false"
EOF

    echo -e "${GREEN}${CHECK} Configuration saved to ../scripts/config.local.sh${NC}"
    echo -e "${GREEN}${CHECK} Ready for installation!${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "  ${ARROW} cd ../scripts"
    echo -e "  ${ARROW} sudo ./arch-base-install.sh all"
    echo ""
    echo -e "${YELLOW}This prototype demonstrates the BubbleTea TUI concept.${NC}"
    echo -e "${YELLOW}The full version would have interactive forms, validation, and more!${NC}"
}

# Main execution
main() {
    welcome_screen
    system_screen
    user_screen
    disk_screen
    package_screen
    summary_screen
    generate_config
}

main "$@"
