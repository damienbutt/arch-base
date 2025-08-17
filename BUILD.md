# Build System

This project includes a comprehensive Makefile for building and managing the Arch-Base TUI Installer.

## Quick Start

```bash
# Build the application
make build

# Build and run
make run

# Development workflow (clean + build + run)
make dev

# Show all available commands
make help
```

## Available Commands

### Building

- `make build` - Build for production (Linux x64)
- `make build-dev` - Build with debug information
- `make build-all` - Build for multiple platforms
- `make clean` - Remove build artifacts

### Running

- `make run` - Build and run the application
- `make run-dev` - Run in development mode (go run)

### Development

- `make test` - Run tests
- `make lint` - Run linting and formatting
- `make fmt` - Format Go code
- `make tidy` - Tidy Go modules
- `make deps` - Download dependencies

### Distribution

- `make package` - Create distribution package
- `make release` - Create release packages for all platforms
- `make install` - Install system-wide (requires sudo)
- `make uninstall` - Remove from system (requires sudo)

### Information

- `make info` - Show build information
- `make help` - Show detailed help

## Build Output

All build artifacts are placed in the `build/` directory:

- `build/arch-installer` - Main Linux binary
- `build/arch-installer-*` - Multi-platform binaries
- `build/*.tar.gz` - Distribution packages

## Platform Support

The build system supports creating binaries for:

- Linux (x64, ARM64)
- macOS (x64, ARM64)
- Windows (x64)

## Examples

```bash
# Development workflow
make clean build run

# Create release packages
make clean build-all release

# Install system-wide
make build install

# Format and test code
make fmt test lint
```
