#!/bin/bash

# Gum Demo Script for Arch-Base
# This script demonstrates the beautiful gum interfaces without actually installing anything

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions for gum installation
source "$SCRIPT_DIR/common.sh"

# Ensure gum is available
echo "🔧 Preparing gum demo..."
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
    exit 1
fi

echo "✅ Gum demo ready!"
echo ""

# Welcome screen
gum style \
    --foreground 212 --border-foreground 212 --border double \
    --align center --width 60 --margin "1 2" --padding "2 4" \
    'Arch-Base Installation' 'Gum Interface Demo'

echo ""
gum format -- "This is a **demonstration** of the beautiful interfaces available in the Arch-Base installation scripts when using **Gum**."
echo ""

if ! gum confirm "Continue with the demo?"; then
    echo "Demo cancelled."
    exit 0
fi

# System Configuration Demo
echo ""
gum style --foreground 86 "📱 System Configuration Demo"
echo ""

hostname=$(gum input --placeholder "Enter hostname (e.g., arch-desktop)" --value "demo-system")
gum style --foreground 82 "✓ Hostname set to: $hostname"

echo ""
timezone_region=$(gum choose --height 8 "America" "Europe" "Asia" "Africa" "Australia" "UTC")
gum style --foreground 82 "✓ Timezone region: $timezone_region"

echo ""
locale=$(gum choose --height 6 \
    "en_US.UTF-8" "en_GB.UTF-8" "de_DE.UTF-8" "fr_FR.UTF-8" "es_ES.UTF-8" "Custom...")
gum style --foreground 82 "✓ Locale: $locale"

# Disk Selection Demo
echo ""
gum style --foreground 86 "💾 Disk Selection Demo"
echo ""

# Simulate disk listing
gum format --type code "NAME    SIZE TYPE  MODEL
sda     250G disk  Samsung SSD
nvme0n1 500G disk  NVMe Controller
sdb     1T   disk  WD Blue HDD"

echo ""
disk=$(gum choose --header "Select target disk:" "/dev/sda (250GB SSD)" "/dev/nvme0n1 (500GB NVMe)" "/dev/sdb (1TB HDD)")

# Warning demo
echo ""
gum style --foreground 196 --border-foreground 196 --border thick \
    --align center --width 60 --margin "1 2" --padding "1 2" \
    "⚠️  WARNING ⚠️" "" "This would completely erase:" "$disk" "" "ALL DATA WOULD BE LOST!"

echo ""
if gum confirm "Continue with disk selection? (This is just a demo)"; then
    gum style --foreground 82 "✓ Disk selected: $disk"
else
    gum style --foreground 196 "✗ Disk selection cancelled"
fi

# Package Selection Demo
echo ""
gum style --foreground 86 "📦 Package Selection Demo"
echo ""

package_preset=$(gum choose --header "Choose a package preset:" \
    "Minimal (base system only)" \
    "Standard (base + common tools)" \
    "Development (standard + dev tools)" \
    "Desktop (development + desktop apps)")

gum style --foreground 82 "✓ Package preset: $package_preset"

if gum confirm "Select additional packages?"; then
    echo ""
    selected_packages=($(gum choose --no-limit --height 10 \
        "git" "vim" "firefox" "htop" "neofetch" "docker" "code" "discord"))

    if [[ ${#selected_packages[@]} -gt 0 ]]; then
        gum style --foreground 82 "✓ Additional packages: $(IFS=', '; echo "${selected_packages[*]}")"
    fi
fi

# Progress Demo
echo ""
gum style --foreground 86 "⚡ Progress Tracking Demo"
echo ""

total_steps=5
for ((step=1; step<=total_steps; step++)); do
    progress_percent=$((step * 100 / total_steps))

    case $step in
        1) task="Partitioning disk" ;;
        2) task="Creating filesystems" ;;
        3) task="Installing packages" ;;
        4) task="Configuring system" ;;
        5) task="Installing bootloader" ;;
    esac

    gum style \
        --foreground 86 \
        --border-foreground 86 \
        --border normal \
        --margin "0 2" \
        --padding "0 1" \
        "Step $step/$total_steps ($progress_percent%): $task"

    # Progress bar
    filled=$((progress_percent / 5))
    empty=$((20 - filled))
    gum style --foreground 82 "$(printf '█%.0s' $(seq 1 $filled))$(printf '░%.0s' $(seq 1 $empty))"

    sleep 1
done

# Final demo
echo ""
gum style \
    --foreground 82 \
    --border-foreground 82 \
    --border double \
    --align center \
    --width 50 \
    --margin "1 2" \
    --padding "1 3" \
    "✅ Demo Complete!" "" "The actual installation would" "create a beautiful Arch Linux system!"

echo ""
gum format -- "**Next Steps:**
- Try the real installation: \`sudo ./arch-base-install.sh config\`
- Or use traditional mode: \`sudo ./arch-base-install.sh --no-gum\`
- View documentation: \`GUM_INTEGRATION.md\`"

echo ""
if gum confirm "Open the Gum integration documentation?"; then
    if command -v less >/dev/null 2>&1; then
        less GUM_INTEGRATION.md 2>/dev/null || cat GUM_INTEGRATION.md 2>/dev/null || echo "Documentation not found in current directory"
    else
        cat GUM_INTEGRATION.md 2>/dev/null || echo "Documentation not found in current directory"
    fi
fi
