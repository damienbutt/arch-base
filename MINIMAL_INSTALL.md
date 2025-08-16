# Minimal Installation Guide

This project has been optimized to provide an ultra-minimal Arch Linux base system installation. The scripts now support different installation modes to give you complete control over what gets installed.

## Installation Modes

### 1. Minimal Mode (Recommended for Base System)

- **Packages**: Only absolute essentials (grub, networkmanager, openssh, btrfs-progs)
- **Services**: SSH daemon enabled for remote access
- **Storage**: Lightweight base system (~2GB installed)
- **Use Case**: Server deployments, containers, embedded systems

```bash
# Configuration for minimal mode
MINIMAL_INSTALL="true"
INSTALL_OPTIONAL_PACKAGES="false"
INSTALL_SECURITY_PACKAGES="false"
ESSENTIAL_PACKAGES="btrfs-progs"
```

### 2. Standard Mode

- **Packages**: Essential + optional development tools
- **Services**: SSH, NetworkManager, and optionally additional services
- **Storage**: Moderate system (~4GB installed)
- **Use Case**: Development workstations, general purpose systems

```bash
# Configuration for standard mode
MINIMAL_INSTALL="false"
INSTALL_OPTIONAL_PACKAGES="true"
INSTALL_SECURITY_PACKAGES="false"
```

### 3. Complete Mode

- **Packages**: Essential + optional + security packages
- **Services**: All applicable services enabled
- **Storage**: Full-featured system (~6GB installed)
- **Use Case**: Production servers, security-focused deployments

```bash
# Configuration for complete mode
MINIMAL_INSTALL="false"
INSTALL_OPTIONAL_PACKAGES="true"
INSTALL_SECURITY_PACKAGES="true"
```

## Package Categories

### Essential Packages (Always Installed)

- `grub` - Boot loader
- `btrfs-progs` - Filesystem utilities
- `networkmanager` - Network management
- `openssh` - SSH server and client

### Optional Packages (Configurable)

- `base-devel` - Development tools (make, gcc, etc.)
- `linux-headers` - Kernel headers for module compilation
- `acpi` - Power management utilities
- `snapper` - BTRFS snapshot management
- `terminus-font` - Console font
- `vim` - Text editor
- `dnsutils` - DNS lookup utilities
- `inetutils` - Network utilities

### Security Packages (Configurable)

- `ufw` - Uncomplicated Firewall
- `apparmor` - Mandatory Access Control

## System Features (All Modes)

### BTRFS Filesystem

- Subvolume structure for system separation
- Compression enabled (zstd)
- SSD optimization when applicable
- Snapshot-ready configuration

### LUKS Encryption

- Support for LUKS1 and LUKS2
- Secure keyfile generation
- Hardware-optimized encryption settings

### System Hardening

- Secure boot configuration
- Proper file permissions
- SSH security configuration
- Firewall ready (when security packages installed)

## Interactive Configuration

The enhanced `interactive-config.sh` script provides a beautiful TUI interface using `gum` for:

1. **System Configuration**: Hostname, timezone, localization
2. **User Management**: Username, password, sudo access
3. **Disk Configuration**: Encryption, filesystem options
4. **Package Selection**: Minimal/Standard/Complete/Custom modes

## Non-Interactive Usage

For automation, use the configuration file approach:

```bash
# Copy and edit the template
cp scripts/config.template.sh scripts/config.sh

# Edit with your preferences
vim scripts/config.sh

# Run installation
sudo ./arch-base-install.sh
```

## What's NOT Included

This base installation intentionally excludes:

- ❌ Desktop environments (GNOME, KDE, XFCE, etc.)
- ❌ Display servers (X11, Wayland)
- ❌ Audio systems (PulseAudio, PipeWire)
- ❌ Multimedia codecs
- ❌ Gaming software
- ❌ Office applications
- ❌ Web browsers
- ❌ Development IDEs

This keeps the base system minimal and allows you to add only what you need on top of a solid foundation.

## Post-Installation

After the base installation completes, you have a minimal but fully functional Arch Linux system ready for:

1. Installing a desktop environment of your choice
2. Adding specific applications for your use case
3. Deploying as a server or container base
4. Further customization and hardening

The system includes SSH access, network connectivity, and all the tools needed to install additional software as required.
