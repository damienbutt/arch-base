# Arch Linux Installer Development Container

This development container provides a complete Arch Linux environment for developing the arch-base installer.

## Features

### 🐧 **Arch Linux Base**

-   Latest Arch Linux container image
-   Native Arch Linux tools and utilities
-   Authentic development environment matching target deployment

### 🐹 **Go Development**

-   Go 1.21 with full toolchain
-   golangci-lint for code quality
-   Delve debugger (dlv)
-   Rich testing tools (gotestsum, richgo)
-   Go modules with persistent cache

### 🛠️ **Development Tools**

-   **Build System**: Make with comprehensive targets
-   **Release Management**: GoReleaser pre-installed
-   **Git Hooks**: Lefthook for consistent commits
-   **Code Quality**: staticcheck, gosec, misspell
-   **Shell**: Zsh with Oh My Zsh and useful plugins

### 🏗️ **Arch-Specific Tools**

Pre-installed tools relevant to Arch Linux installation:

-   `arch-install-scripts` - Arch installation utilities
-   `pacman-contrib` - Pacman utilities and scripts
-   `reflector` - Mirror list management
-   Filesystem tools: `dosfstools`, `e2fsprogs`, `btrfs-progs`, `xfsprogs`
-   Partitioning: `gptfdisk`, `parted`, `lvm2`
-   Encryption: `cryptsetup`, `device-mapper`

### 🎨 **VS Code Integration**

-   Go extension with full IntelliSense
-   Integrated debugging and testing
-   Makefile support
-   Git and GitHub integration
-   Markdown and YAML support
-   Code spell checking and linting

## Quick Start

1. **Open in VS Code**:

    ```bash
    code .
    ```

2. **Reopen in Container**:

    - Press `Ctrl+Shift+P` (or `Cmd+Shift+P` on Mac)
    - Select "Dev Containers: Reopen in Container"

3. **Wait for Setup**:

    - Container builds and configures automatically
    - Setup script installs all tools and dependencies

4. **Start Developing**:
    ```bash
    make help          # See all available commands
    make test          # Run tests
    make build         # Build the installer
    make release-build # Build with GoReleaser
    ```

## Development Workflow

### 🧪 **Testing**

```bash
make test              # Run all tests
make test-coverage     # Tests with coverage report
make test-race         # Tests with race detection
arch-test              # Quick alias
```

### 🔨 **Building**

```bash
make build             # Development build
make release-build     # Release build with GoReleaser
make clean             # Clean artifacts
arch-build             # Quick alias
```

### 🔍 **Code Quality**

```bash
make lint              # Run linting
make fmt               # Format code
make security          # Security scan
```

### 🚀 **Running**

```bash
make run               # Build and run
make run-dev           # Run in development mode
arch-run               # Quick alias
```

## Container Features

### 📂 **Persistent Storage**

-   Go modules cache persisted across rebuilds
-   Workspace mounted with optimized consistency

### 🔧 **Environment Variables**

-   `GOOS=linux`, `GOARCH=amd64` for Linux targeting
-   `CGO_ENABLED=0` for static binaries
-   Proper Go proxy and checksum database configuration

### 🌐 **Port Forwarding**

-   Port 8080: Development server
-   Port 9000: Debug port

### 🛡️ **Privileged Mode**

-   Required for testing disk operations and low-level system calls
-   Enables realistic testing of installer functionality

## Useful Aliases

The container includes helpful aliases:

```bash
# File operations
ll, la, lt    # Enhanced ls with exa
cat           # bat (syntax highlighting)
grep          # ripgrep (faster)
find          # fd (faster)

# Go development
gt, gtv, gtr, gtc    # Various go test commands
gb, gr, gf, gl       # go build, run, fmt, lint

# Make shortcuts
mb, mt, mc, mr       # make build, test, clean, run
mrb, mrc            # make release-build, release-check

# Project specific
arch-build, arch-test, arch-run, arch-release
```

## Architecture Context

This development environment matches the target deployment environment:

-   **Same OS**: Arch Linux container mirrors target systems
-   **Same Architecture**: x86_64 Linux builds
-   **Same Tools**: Native Arch tools for authentic development
-   **Same Package Manager**: Pacman for dependency management

Perfect for developing and testing the Arch Linux installer in an environment that closely matches where it will be deployed.

## Customization

The container can be customized by editing:

-   `.devcontainer/devcontainer.json` - Container configuration
-   `.devcontainer/setup.sh` - Post-creation setup script

Rebuild the container after changes:

```bash
# Command Palette -> Dev Containers: Rebuild Container
```
