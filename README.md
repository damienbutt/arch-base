# Arch-Base

<div align="center">
    <img align="center" src="./assets/img/archlinux-logo-dark-scalable.518881f04ca9.svg" alt="archlinux-logo" />
</div>

---

[![Go Report Card](https://goreportcard.com/badge/github.com/damienbutt/arch-base)](https://goreportcard.com/report/github.com/damienbutt/arch-base)
[![Conventional Commits](https://img.shields.io/badge/Conventional%20Commits-1.0.0-%23FE5196?logo=conventionalcommits&logoColor=white)](https://conventionalcommits.org)
[![GitHub contributors](https://img.shields.io/github/contributors/damienbutt/arch-base)](#contributors)
[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

A modern, interactive TUI (Terminal User Interface) installer for Arch Linux, built with Go and
the Bubble Tea framework. This installer provides a streamlined, user-friendly experience for
setting up Arch Linux with sensible defaults and modern filesystem configurations.

## 🚀 Quick Start

### Option 1: One-Line Installation

Boot into an Arch Linux live environment and run:

```bash
curl -fsSL https://raw.githubusercontent.com/damienbutt/arch-base/HEAD/scripts/install-arch-base.sh | bash
```

### Option 2: Development Container (Recommended for Contributors)

The fastest way to contribute is using the pre-configured development container:

1. **Prerequisites**: Docker and VS Code with Dev Containers extension
2. **Open Project**: `code .`
3. **Reopen in Container**: `Ctrl+Shift+P` → "Dev Containers: Reopen in Container"
4. **Start Developing**: Container sets up automatically with all tools

```bash
# Inside the container
make help          # See all available commands
make test          # Run tests
make build         # Build the installer
make release-build # Build with GoReleaser
```

### Option 3: Local Development

For local development without containers:

```bash
# Clone and setup
git clone https://github.com/damienbutt/arch-base.git
cd arch-base

# Install dependencies
go mod download

# Install development tools (optional)
./scripts/install-go-tools.sh

# Build and test
make test
make build
make run
```

## � Contents

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

-   [Features](#features)
-   [Installation Guide](#installation-guide)
-   [Build System](#build-system)
-   [Development](#development)
-   [Contributing](#contributing)
-   [Team](#team)
-   [Contributors](#contributors)
-   [Learn More](#learn-more)
-   [License](#license)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## ✨ Features

-   **Modern TUI Interface**: Interactive terminal interface built with Bubble Tea
-   **EFI Boot Support**: 260MB EFI system partition for modern UEFI systems
-   **BTRFS Filesystem**: Advanced filesystem with subvolumes for better organization:
    -   `@` (root)
    -   `@home` (user data)
    -   `@log` (system logs)
    -   `@cache` (package cache)
    -   `@snapshots` (system snapshots)
    -   `@swap` (swap files)
-   **Full Disk Encryption**: LUKS1 encryption including boot directory
-   **Automatic Snapshots**: Configured with `snapper` and `snap-pac`
-   **GRUB Bootloader**: Reliable boot management
-   **AUR Support**: Paru AUR helper pre-installed
-   **Optimized Memory**: ZRAM (1GB) + Swapfile (System Memory + 2GB)
-   **Network Boot Ready**: Arch NetBoot support

## 📋 Installation Guide

### Prerequisites

1. Download the [Arch Linux ISO](https://archlinux.org/download/) and boot into the live environment
2. (Optional) Connect to WiFi if needed:

    ```bash
    iwctl
    # Follow the prompts to connect to your network
    ```

3. Verify internet connectivity:

    ```bash
    ping -c 4 archlinux.org
    ```

### Installation Steps

1. **Optional SSH Setup** (recommended for copy/paste functionality):

    ```bash
    # Set root password
    passwd root

    # Find IP address
    ip a

    # SSH from another machine
    ssh root@<ip-address>
    ```

2. **Run the installer**:

    ```bash
    curl -fsSL https://raw.githubusercontent.com/damienbutt/arch-base/HEAD/scripts/install-arch-base.sh | bash
    ```

3. **Follow the interactive prompts** to configure your system

4. **Reboot** when installation completes

## 🔨 Build System

This project includes a comprehensive Makefile for development and building:

### Quick Commands

```bash
make build         # Build for production (Linux x64)
make test          # Run all tests
make run           # Build and run the application
make dev           # Development workflow (clean + build + run)
make lint          # Run linting and formatting
make release-build # Build with GoReleaser
make help          # Show all available commands
```

### Development Commands

```bash
make build-dev     # Build with debug information
make run-dev       # Run in development mode (go run)
make fmt           # Format Go code
make tidy          # Tidy Go modules
make deps          # Download dependencies
make clean         # Remove build artifacts
```

### Distribution Commands

```bash
make package       # Create distribution package
make release       # Create release packages for all platforms
make install       # Install system-wide (requires sudo)
make uninstall     # Remove from system (requires sudo)
```

## 🛠️ Development

### Prerequisites

-   **Go 1.21+**: [Download and install Go](https://golang.org/dl/)
-   **Git**: For version control
-   **Make**: For build automation

### Setting Up

1. **Clone the repository**:

    ```bash
    git clone https://github.com/damienbutt/arch-base.git
    cd arch-base
    ```

2. **Install development tools** (optional):

    ```bash
    ./scripts/install-go-tools.sh
    ```

3. **Install git hooks**:

    ```bash
    lefthook install
    ```

4. **Run initial checks**:

    ```bash
    make ci
    ```

### Project Structure

```
arch-base/
├── main.go              # Application entry point
├── main_test.go         # Main package tests
├── internal/            # Internal packages
│   ├── installer/       # Core installation logic
│   ├── styles/          # TUI styling
│   ├── system/          # System utilities
│   ├── types/           # Type definitions
│   └── ui/              # User interface components
├── scripts/             # Installation and setup scripts
├── docs/                # Additional documentation
├── build/               # Build artifacts (generated)
├── .devcontainer/       # Development container config
├── Makefile            # Build system
└── .goreleaser.yaml    # Release configuration
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Workflow

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Run tests: `make test`
5. Run linting: `make lint`
6. Commit using conventional commits: `git commit -m "feat: add amazing feature"`
7. Push to your fork and submit a pull request

## 👥 Team

This project is maintained by [Damien Butt](https://github.com/damienbutt) and the
[awesome contributors](https://github.com/damienbutt/arch-base/graphs/contributors).

## ✨ Contributors

<!-- ALL-CONTRIBUTORS-BADGE:START - Do not remove or modify this section -->

[![All Contributors](https://img.shields.io/badge/all_contributors-1-orange.svg?style=flat-square)](#contributors-)

<!-- ALL-CONTRIBUTORS-BADGE:END -->

Thanks go to these awesome people ([emoji key](https://allcontributors.org/docs/en/emoji-key)):

<!-- ALL-CONTRIBUTORS-LIST:START - Do not remove or modify this section -->
<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->

<!-- ALL-CONTRIBUTORS-LIST:END -->

This project follows the [all-contributors](https://allcontributors.org) specification.
Contributions of any kind are welcome!

## 📚 Learn More

-   [Arch Linux Wiki](https://wiki.archlinux.org/) - Comprehensive Arch Linux documentation
-   [Bubble Tea](https://github.com/charmbracelet/bubbletea) - The TUI framework used
-   [BTRFS](https://wiki.archlinux.org/title/Btrfs) - Learn about the BTRFS filesystem

## 📄 License

[MIT](LICENSE)
