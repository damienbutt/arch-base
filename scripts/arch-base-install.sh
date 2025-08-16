#!/bin/bash

# Arch-Base Installation Orchestrator
# Main entry point for the Arch Linux installation process

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Default values
CONFIG_FILE=""
PHASE="all"
HELP=false

usage() {
    cat << EOF
Arch-Base Installation Orchestrator

USAGE:
    $0 [OPTIONS] [PHASE]

PHASES:
    all         Complete installation (default)
    config      Interactive configuration wizard (requires gum)
    download    Download dependencies only
    install     Full installation (excluding dependencies)
    partition   Partition disk only
    format      Format and mount filesystems only
    packages    Install packages only
    chroot      Run chroot scripts only

OPTIONS:
    -c, --config FILE       Use custom configuration file
    -i, --interactive       Use interactive configuration wizard
    -d, --dry-run          Show what would be done without executing
    -y, --auto-confirm     Automatically confirm all prompts
    -h, --help             Show this help message
    --disk DEVICE          Target disk device (e.g., /dev/sda)
    --hostname NAME        System hostname
    --username NAME        Primary user name
    --skip-download        Skip downloading dependencies
    --skip-reboot          Skip automatic reboot
    --no-gum               Disable gum interface (use fallback)

EXAMPLES:
    # Interactive configuration wizard (recommended)
    $0 config

    # Interactive installation with prompts
    $0

    # Automated installation using custom config
    $0 -c my-config.sh -y

    # Dry run to see what would be done
    $0 -d

    # Quick automated installation
    $0 --disk /dev/sda --hostname myarch --username myuser -y

    # Only download dependencies
    $0 download

    # Only partition disk
    $0 partition --disk /dev/sda

CONFIGURATION:
    Copy config.template.sh to config.local.sh and modify as needed.
    Environment variables can also be used to override settings.

NOTES:
    - This script must be run as root
    - Ensure you have a stable internet connection
    - The target disk will be completely wiped
    - A log file will be created in /tmp/arch-base-install/

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -i|--interactive)
            PHASE="config"
            shift
            ;;
        -d|--dry-run)
            export DRY_RUN=true
            shift
            ;;
        -y|--auto-confirm)
            export AUTO_CONFIRM=true
            export INTERACTIVE_MODE=false
            shift
            ;;
        --disk)
            export TARGET_DISK="$2"
            shift 2
            ;;
        --hostname)
            export HOSTNAME="$2"
            shift 2
            ;;
        --username)
            export USERNAME="$2"
            shift 2
            ;;
        --skip-download)
            export SKIP_DOWNLOAD=true
            shift
            ;;
        --skip-reboot)
            export SKIP_REBOOT=true
            shift
            ;;
        --no-gum)
            export USE_GUM=false
            shift
            ;;
        -h|--help)
            HELP=true
            shift
            ;;
        all|config|download|install|partition|format|packages|chroot)
            PHASE="$1"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Show help if requested
if [[ "$HELP" == "true" ]]; then
    usage
    exit 0
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This script must be run as root"
    echo "Try: sudo $0 $*"
    exit 1
fi

# Export config file for child scripts
if [[ -n "$CONFIG_FILE" ]]; then
    export CONFIG_FILE="$CONFIG_FILE"
fi

# Execute the appropriate phase
case "$PHASE" in
    all)
        echo "Starting complete Arch-Base installation..."
        exec "$SCRIPT_DIR/install-arch-base.sh" "$@"
        ;;
    config)
        echo "Starting interactive configuration wizard..."
        exec "$SCRIPT_DIR/interactive-config.sh"
        ;;
    download)
        echo "Downloading dependencies..."
        export SKIP_DOWNLOAD=false
        "$SCRIPT_DIR/install-arch-base.sh" --skip-download=false
        echo "Dependencies downloaded. Run '$0 install' to continue."
        ;;
    install)
        echo "Starting installation (skipping download)..."
        export SKIP_DOWNLOAD=true
        exec "$SCRIPT_DIR/install-arch-base.sh" "$@"
        ;;
    partition)
        echo "Phase 'partition' not yet implemented as standalone"
        echo "Use 'all' or 'install' phase for now"
        exit 1
        ;;
    format)
        echo "Phase 'format' not yet implemented as standalone"
        echo "Use 'all' or 'install' phase for now"
        exit 1
        ;;
    packages)
        echo "Phase 'packages' not yet implemented as standalone"
        echo "Use 'all' or 'install' phase for now"
        exit 1
        ;;
    chroot)
        echo "Phase 'chroot' not yet implemented as standalone"
        echo "Use 'all' or 'install' phase for now"
        exit 1
        ;;
    *)
        echo "Unknown phase: $PHASE"
        usage
        exit 1
        ;;
esac
