#!/bin/bash

# Common functions and error handling for Arch-Base installation scripts

# Error handling setup
set -euo pipefail
IFS=$'\n\t'

# Logging configuration
LOG_DIR="/tmp/arch-base-install"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"
mkdir -p "$LOG_DIR"

# Redirect output to log file while keeping terminal output
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Color definitions
if [[ -t 1 ]]; then
    tty_escape() { printf "\033[%sm" "$1"; }
else
    tty_escape() { :; }
fi

tty_mkbold() { tty_escape "1;$1"; }
tty_underline="$(tty_escape "4;39")"
tty_blue="$(tty_mkbold 34)"
tty_red="$(tty_mkbold 31)"
tty_green="$(tty_mkbold 32)"
tty_yellow="$(tty_mkbold 33)"
tty_bold="$(tty_mkbold 39)"
tty_reset="$(tty_escape 0)"

# Enhanced logging functions
log() {
    printf "[%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

log_info() {
    printf "${tty_blue}[INFO]${tty_reset} [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

log_warn() {
    printf "${tty_yellow}[WARN]${tty_reset} [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >&2
}

log_error() {
    printf "${tty_red}[ERROR]${tty_reset} [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*" >&2
}

log_success() {
    printf "${tty_green}[SUCCESS]${tty_reset} [%s] %s\n" "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

# Enhanced abort function
abort() {
    log_error "$@"
    log_error "Installation aborted. Check log file: $LOG_FILE"
    cleanup_on_exit
    exit 1
}

# Cleanup function
cleanup_on_exit() {
    log_info "Performing cleanup..."

    # Unmount any mounted filesystems
    if mountpoint -q /mnt; then
        log_info "Unmounting filesystems..."
        umount -R /mnt 2>/dev/null || true
    fi

    # Close LUKS container if open
    if [[ -n "${CRYPTROOT_NAME:-}" ]] && [[ -e "/dev/mapper/$CRYPTROOT_NAME" ]]; then
        log_info "Closing LUKS container..."
        cryptsetup close "$CRYPTROOT_NAME" 2>/dev/null || true
    fi
}

# Set up trap for cleanup
trap cleanup_on_exit EXIT INT TERM

# Enhanced execute function with dry-run support
execute() {
    local cmd="$*"
    log_info "Executing: $cmd"

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_warn "DRY RUN: Would execute: $cmd"
        return 0
    fi

    if ! eval "$cmd"; then
        abort "Command failed: $cmd"
    fi
}

# Check if gum is available
has_gum() {
    command -v gum >/dev/null 2>&1
}

# Install gum if not present
install_gum() {
    if has_gum; then
        log_info "Gum is already installed"
        return 0
    fi

    log_info "Installing gum for interactive interface..."

    # Detect the package manager and install gum
    if command -v pacman >/dev/null 2>&1; then
        # Arch Linux / Manjaro
        log_info "Installing gum via pacman..."
        if ! pacman -S --noconfirm gum; then
            log_warn "Failed to install gum via pacman, trying AUR..."
            if command -v yay >/dev/null 2>&1; then
                yay -S --noconfirm gum
            elif command -v paru >/dev/null 2>&1; then
                paru -S --noconfirm gum
            else
                install_gum_binary
            fi
        fi
    elif command -v apt >/dev/null 2>&1; then
        # Debian / Ubuntu
        log_info "Installing gum via apt..."
        apt update && apt install -y gum || install_gum_binary
    elif command -v dnf >/dev/null 2>&1; then
        # Fedora
        log_info "Installing gum via dnf..."
        dnf install -y gum || install_gum_binary
    elif command -v brew >/dev/null 2>&1; then
        # macOS with Homebrew
        log_info "Installing gum via brew..."
        brew install gum || install_gum_binary
    else
        install_gum_binary
    fi

    # Verify installation
    if has_gum; then
        log_success "Gum installed successfully"
    else
        log_error "Failed to install gum"
        return 1
    fi
}

# Install gum binary directly from GitHub releases
install_gum_binary() {
    log_info "Installing gum binary from GitHub releases..."

    # Detect architecture and OS
    local arch
    case "$(uname -m)" in
        x86_64) arch="x86_64" ;;
        aarch64|arm64) arch="arm64" ;;
        armv7l) arch="armv7" ;;
        *) log_error "Unsupported architecture: $(uname -m)"; return 1 ;;
    esac

    local os
    case "$(uname -s)" in
        Linux) os="Linux" ;;
        Darwin) os="Darwin" ;;
        *) log_error "Unsupported OS: $(uname -s)"; return 1 ;;
    esac

    # Download and install
    local temp_dir
    temp_dir=$(mktemp -d)
    local gum_version="v0.14.1"  # Latest stable version
    local download_url="https://github.com/charmbracelet/gum/releases/download/${gum_version}/gum_${gum_version#v}_${os}_${arch}.tar.gz"

    log_info "Downloading gum from: $download_url"

    if command -v curl >/dev/null 2>&1; then
        curl -sL "$download_url" | tar -xz -C "$temp_dir"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$download_url" | tar -xz -C "$temp_dir"
    else
        log_error "Neither curl nor wget found. Cannot download gum."
        return 1
    fi

    # Install binary
    local install_dir="/usr/local/bin"
    if [[ ! -w "$install_dir" ]]; then
        install_dir="$HOME/.local/bin"
        mkdir -p "$install_dir"
        export PATH="$install_dir:$PATH"
    fi

    if cp "$temp_dir/gum" "$install_dir/gum"; then
        chmod +x "$install_dir/gum"
        log_success "Gum binary installed to $install_dir/gum"
    else
        log_error "Failed to install gum binary"
        return 1
    fi

    # Cleanup
    rm -rf "$temp_dir"
}

# Ensure gum is available for interactive mode
ensure_gum() {
    if ! has_gum; then
        log_info "Gum not found. Installing automatically for interactive mode..."
        if ! install_gum; then
            log_error "Failed to install gum. Please install manually or use non-interactive mode."
            return 1
        fi
    fi
    return 0
}

# Enhanced progress tracking with gum
set_total_steps() {
    TOTAL_STEPS="$1"
    log_info "Total installation steps: $TOTAL_STEPS"
}

step() {
    ((CURRENT_STEP++))

    if has_gum && [[ "${USE_GUM:-true}" == "true" ]]; then
        # Use gum for beautiful progress display
        local progress_percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))

        gum style \
            --foreground 86 \
            --border-foreground 86 \
            --border normal \
            --margin "0 2" \
            --padding "0 1" \
            "Step $CURRENT_STEP/$TOTAL_STEPS ($progress_percent%): $*"

        # Show progress bar if not in final step
        if [[ $CURRENT_STEP -lt $TOTAL_STEPS ]]; then
            gum style --foreground 238 "$(printf '█%.0s' $(seq 1 $((progress_percent / 5))))$(printf '░%.0s' $(seq 1 $((20 - progress_percent / 5))))"
        fi
    else
        # Fallback to original display
        printf "${tty_blue}==>${tty_bold} Step %d/%d: %s${tty_reset}\n" "$CURRENT_STEP" "$TOTAL_STEPS" "$*"
    fi

    log_info "Step $CURRENT_STEP/$TOTAL_STEPS: $*"
}

# Enhanced user confirmation with gum support
confirm() {
    local message="$1"
    local default="${2:-n}"

    if [[ "${AUTO_CONFIRM:-false}" == "true" ]]; then
        log_info "Auto-confirming: $message"
        return 0
    fi

    if [[ "${INTERACTIVE_MODE:-true}" == "false" ]]; then
        if [[ "$default" == "y" ]]; then
            return 0
        else
            return 1
        fi
    fi

    # Use gum if available and enabled
    if has_gum && [[ "${USE_GUM:-true}" == "true" ]]; then
        if [[ "$default" == "y" ]]; then
            gum confirm --default=true "$message"
        else
            gum confirm --default=false "$message"
        fi
    else
        # Fallback to traditional prompt
        local prompt
        if [[ "$default" == "y" ]]; then
            prompt="$message (Y/n): "
        else
            prompt="$message (y/N): "
        fi

        while true; do
            read -p "$prompt" response
            case "$response" in
                [Yy]|[Yy][Ee][Ss]|"")
                    if [[ "$default" == "y" || "$response" =~ ^[Yy] ]]; then
                        return 0
                    elif [[ "$default" == "n" && "$response" == "" ]]; then
                        return 1
                    fi
                    ;;
                [Nn]|[Nn][Oo])
                    return 1
                    ;;
                *)
                    echo "Please answer yes or no."
                    ;;
            esac
        done
    fi
}

# Enhanced input validation functions
validate_hostname() {
    local hostname="$1"
    if [[ -z "$hostname" ]]; then
        echo "Hostname cannot be empty"
        return 1
    fi
    if [[ ! "$hostname" =~ ^[a-zA-Z0-9-]+$ ]]; then
        echo "Hostname can only contain letters, numbers, and hyphens"
        return 1
    fi
    if [[ ${#hostname} -gt 63 ]]; then
        echo "Hostname cannot be longer than 63 characters"
        return 1
    fi
    if [[ "$hostname" =~ ^- || "$hostname" =~ -$ ]]; then
        echo "Hostname cannot start or end with a hyphen"
        return 1
    fi
    return 0
}

validate_username() {
    local username="$1"
    if [[ -z "$username" ]]; then
        echo "Username cannot be empty"
        return 1
    fi
    if [[ ! "$username" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        echo "Username must start with lowercase letter and contain only lowercase letters, numbers, underscores, and hyphens"
        return 1
    fi
    if [[ ${#username} -gt 32 ]]; then
        echo "Username cannot be longer than 32 characters"
        return 1
    fi
    if [[ "$username" =~ ^(root|bin|daemon|sys|adm|tty|disk|lp|mail|news|uucp|proxy|www-data|backup|list|irc|gnats|nobody|systemd-|_).*$ ]]; then
        echo "Username conflicts with system user"
        return 1
    fi
    return 0
}

validate_partition_size() {
    local size="$1"
    if [[ -z "$size" ]]; then
        echo "Size cannot be empty"
        return 1
    fi
    if [[ ! "$size" =~ ^[0-9]+[MG]?$ ]]; then
        echo "Size must be a number optionally followed by M or G (e.g., 512M, 2G)"
        return 1
    fi

    # Extract numeric part
    local numeric="${size//[^0-9]/}"
    local unit="${size//[0-9]/}"

    # Convert to MB for validation
    local size_mb
    case "$unit" in
        "G"|"g") size_mb=$((numeric * 1024)) ;;
        "M"|"m"|"") size_mb="$numeric" ;;
        *) echo "Invalid size unit. Use M for megabytes or G for gigabytes"; return 1 ;;
    esac

    # Validate reasonable ranges
    if [[ "$size_mb" -lt 32 ]]; then
        echo "Size too small (minimum 32MB)"
        return 1
    fi
    if [[ "$size_mb" -gt 4096 ]]; then
        echo "Size too large (maximum 4GB for EFI partition)"
        return 1
    fi

    return 0
}

validate_swap_size() {
    local size="$1"
    if [[ -z "$size" ]]; then
        echo "Swap size cannot be empty"
        return 1
    fi
    if [[ ! "$size" =~ ^[0-9]+$ ]]; then
        echo "Swap size must be a number in megabytes"
        return 1
    fi

    if [[ "$size" -lt 100 ]]; then
        echo "Swap size too small (minimum 100MB)"
        return 1
    fi
    if [[ "$size" -gt 65536 ]]; then
        echo "Swap size too large (maximum 64GB)"
        return 1
    fi

    return 0
}

validate_container_name() {
    local name="$1"
    if [[ -z "$name" ]]; then
        echo "Container name cannot be empty"
        return 1
    fi
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Container name can only contain letters, numbers, underscores, and hyphens"
        return 1
    fi
    if [[ ${#name} -gt 32 ]]; then
        echo "Container name cannot be longer than 32 characters"
        return 1
    fi
    return 0
}

validate_locale() {
    local locale="$1"
    if [[ -z "$locale" ]]; then
        echo "Locale cannot be empty"
        return 1
    fi
    # Basic locale format validation (language_COUNTRY.encoding)
    if [[ ! "$locale" =~ ^[a-z]{2,3}_[A-Z]{2}(\.[A-Za-z0-9-]+)?$ ]]; then
        echo "Invalid locale format. Use format like: en_US.UTF-8"
        return 1
    fi
    return 0
}

validate_keymap() {
    local keymap="$1"
    if [[ -z "$keymap" ]]; then
        echo "Keymap cannot be empty"
        return 1
    fi
    # Basic keymap validation - alphanumeric and common symbols
    if [[ ! "$keymap" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Invalid keymap format. Use lowercase letters, numbers, underscores, and hyphens"
        return 1
    fi
    if [[ ${#keymap} -gt 20 ]]; then
        echo "Keymap name too long"
        return 1
    fi
    return 0
}

validate_package_names() {
    local packages="$1"
    if [[ -z "$packages" ]]; then
        return 0  # Empty is valid (optional)
    fi

    # Split packages by space and validate each
    local package_array=($packages)
    for package in "${package_array[@]}"; do
        # Package names should be alphanumeric, hyphens, underscores, dots, plus signs
        if [[ ! "$package" =~ ^[a-zA-Z0-9._+-]+$ ]]; then
            echo "Invalid package name: '$package'. Package names can only contain letters, numbers, dots, hyphens, underscores, and plus signs."
            return 1
        fi

        # Check for reasonable length
        if [[ ${#package} -gt 80 ]]; then
            echo "Package name too long: '$package'"
            return 1
        fi

        # Common invalid patterns
        if [[ "$package" =~ ^[.-] || "$package" =~ [.-]$ ]]; then
            echo "Package name cannot start or end with dots or hyphens: '$package'"
            return 1
        fi
    done

    return 0
}

# Enhanced input function with validation
get_validated_input() {
    local prompt="$1"
    local validator="$2"
    local default="${3:-}"
    local placeholder="${4:-$prompt}"
    local value
    local error_msg

    while true; do
        if has_gum && [[ "${USE_GUM:-true}" == "true" ]]; then
            if [[ -n "$default" ]]; then
                value=$(gum input --placeholder "$placeholder" --value "$default")
            else
                value=$(gum input --placeholder "$placeholder")
            fi
        else
            if [[ -n "$default" ]]; then
                read -p "$prompt [$default]: " -r value
                [[ -z "$value" ]] && value="$default"
            else
                read -p "$prompt: " -r value
            fi
        fi

        # Skip validation if empty and default provided
        if [[ -z "$value" && -n "$default" ]]; then
            value="$default"
            break
        fi

        # Run validation if validator provided
        if [[ -n "$validator" ]]; then
            if error_msg=$($validator "$value" 2>&1); then
                break
            else
                if has_gum && [[ "${USE_GUM:-true}" == "true" ]]; then
                    gum style --foreground 196 "❌ $error_msg"
                else
                    echo "❌ $error_msg" >&2
                fi
                # Clear default after first attempt
                default=""
            fi
        else
            break
        fi
    done

    echo "$value"
}

# Enhanced selection function with gum support
select_option() {
    local prompt="$1"
    shift
    local options=("$@")

    if has_gum && [[ "${USE_GUM:-true}" == "true" ]]; then
        gum choose --header "$prompt" "${options[@]}"
    else
        echo "$prompt"
        local i=1
        for option in "${options[@]}"; do
            echo "$i) $option"
            ((i++))
        done

        while true; do
            read -p "Select option (1-${#options[@]}): " -r choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#options[@]} ]]; then
                echo "${options[$((choice-1))]}"
                break
            else
                echo "Invalid selection. Please choose 1-${#options[@]}."
            fi
        done
    fi
}

# Enhanced multi-select function with gum support
select_multiple() {
    local prompt="$1"
    shift
    local options=("$@")

    if has_gum && [[ "${USE_GUM:-true}" == "true" ]]; then
        gum choose --no-limit --header "$prompt" "${options[@]}"
    else
        echo "$prompt (enter numbers separated by spaces, e.g., '1 3 5'):"
        local i=1
        for option in "${options[@]}"; do
            echo "$i) $option"
            ((i++))
        done

        while true; do
            read -p "Select options: " -r choices
            local selected=()
            local valid=true

            for choice in $choices; do
                if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#options[@]} ]]; then
                    selected+=("${options[$((choice-1))]}")
                else
                    valid=false
                    break
                fi
            done

            if [[ "$valid" == "true" ]]; then
                printf '%s\n' "${selected[@]}"
                break
            else
                echo "Invalid selection. Please enter valid numbers (1-${#options[@]})."
            fi
        done
    fi
}

# Display styled message with gum support
display_message() {
    local type="$1"
    local message="$2"
    local title="${3:-}"

    if has_gum && [[ "${USE_GUM:-true}" == "true" ]]; then
        case "$type" in
            "info")
                if [[ -n "$title" ]]; then
                    gum style --foreground 86 --bold "$title"
                fi
                gum format -- "$message"
                ;;
            "warning")
                gum style \
                    --foreground 220 \
                    --border-foreground 220 \
                    --border normal \
                    --margin "1 2" \
                    --padding "0 1" \
                    "${title:-⚠️  WARNING}" "" "$message"
                ;;
            "error")
                gum style \
                    --foreground 196 \
                    --border-foreground 196 \
                    --border thick \
                    --margin "1 2" \
                    --padding "0 1" \
                    "${title:-❌ ERROR}" "" "$message"
                ;;
            "success")
                gum style \
                    --foreground 82 \
                    --border-foreground 82 \
                    --border normal \
                    --margin "1 2" \
                    --padding "0 1" \
                    "${title:-✅ SUCCESS}" "" "$message"
                ;;
        esac
    else
        # Fallback to colored text
        case "$type" in
            "info")
                [[ -n "$title" ]] && printf "${tty_blue}%s${tty_reset}\n" "$title"
                printf "%s\n" "$message"
                ;;
            "warning")
                printf "${tty_yellow}%s${tty_reset}\n" "${title:-WARNING}: $message"
                ;;
            "error")
                printf "${tty_red}%s${tty_reset}\n" "${title:-ERROR}: $message"
                ;;
            "success")
                printf "${tty_green}%s${tty_reset}\n" "${title:-SUCCESS}: $message"
                ;;
        esac
    fi
}

# Spinner function for long-running operations
show_spinner() {
    local pid=$1
    local message="${2:-Processing...}"

    if has_gum && [[ "${USE_GUM:-true}" == "true" ]]; then
        gum spin --spinner dot --title "$message" -- sleep 0.1
        while kill -0 $pid 2>/dev/null; do
            gum spin --spinner dot --title "$message" -- sleep 0.5
        done
    else
        # Fallback spinner
        local chars="/-\|"
        local i=0
        while kill -0 $pid 2>/dev/null; do
            printf "\r%s %s" "${chars:$i:1}" "$message"
            i=$(( (i+1) % 4 ))
            sleep 0.1
        done
        printf "\r%s %s\n" "✓" "$message"
    fi
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        abort "This script must be run as root"
    fi
}

# Check internet connectivity
check_internet() {
    log_info "Checking internet connectivity..."
    if ! ping -c 1 -W 5 archlinux.org >/dev/null 2>&1; then
        abort "No internet connection available"
    fi
    log_success "Internet connectivity confirmed"
}

# Check if running on Arch Linux
check_arch_linux() {
    if [[ ! -f /etc/arch-release ]]; then
        abort "This script must be run on Arch Linux"
    fi
}

# Enhanced save_var function with validation
save_var() {
    local key="$1"
    local value="$2"
    local env_file="${3:-.env}"

    # Validate variable name
    if [[ ! "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
        abort "Invalid variable name: $key"
    fi

    echo "${key}=${value}" >> "$env_file"
    export "${key}=${value}"
    log_info "Saved variable: $key=$value"
}

# Backup important files
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        local backup="${file}.backup.$(date +%s)"
        cp "$file" "$backup"
        log_info "Backed up $file to $backup"
    fi
}

# Retry function for unreliable operations
retry() {
    local max_attempts="$1"
    local delay="$2"
    shift 2
    local cmd="$*"

    local attempt=1
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Attempt $attempt/$max_attempts: $cmd"

        if eval "$cmd"; then
            return 0
        fi

        if [[ $attempt -lt $max_attempts ]]; then
            log_warn "Command failed, retrying in ${delay}s..."
            sleep "$delay"
        fi

        ((attempt++))
    done

    abort "Command failed after $max_attempts attempts: $cmd"
}

# Enhanced filesystem mount validation
validate_mounts() {
    local required_mounts=(
        "/mnt"
        "/mnt/boot/efi"
        "/mnt/home"
        "/mnt/var/log"
        "/mnt/var/cache"
        "/mnt/swap"
        "/mnt/.snapshots"
    )

    for mount_point in "${required_mounts[@]}"; do
        if ! mountpoint -q "$mount_point"; then
            abort "Required mount point not mounted: $mount_point"
        fi
    done

    log_success "All required filesystems are properly mounted"
}

# Calculate swap size based on RAM
calculate_swap_size() {
    local total_mem_kb
    total_mem_kb=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    local total_mem_mb=$((total_mem_kb / 1024))

    # Default: RAM + 2GB for hibernation support
    local swap_size_mb=$((total_mem_mb + 2048))

    echo "$swap_size_mb"
}

# Detect if running on SSD
is_ssd() {
    local disk="$1"
    local device_name
    device_name=$(basename "$disk")

    # Remove partition number if present
    device_name=${device_name%[0-9]*}
    device_name=${device_name%p[0-9]*}  # for nvme devices

    if [[ -f "/sys/block/$device_name/queue/rotational" ]]; then
        local rotational
        rotational=$(cat "/sys/block/$device_name/queue/rotational")
        [[ "$rotational" == "0" ]]
    else
        # Default to SSD if we can't determine
        return 0
    fi
}
