# Development Setup Guide

This guide will help you set up the development environment for the arch-base Go project.

## Prerequisites

- **Go 1.21+**: [Download and install Go](https://golang.org/dl/)
- **Git**: For version control
- **Make**: For build automation (usually pre-installed on macOS/Linux)

## Quick Setup

### 1. Clone the Repository

```bash
git clone https://github.com/damienbutt/arch-base.git
cd arch-base
```

### 2. Install Go Development Tools

Run the automated setup script:

```bash
./scripts/install-go-tools.sh
```

This will install:

- **GoReleaser**: For automated releases
- **Lefthook**: For Git hooks (replaces Husky)
- **golangci-lint**: For comprehensive linting
- **staticcheck**: For static analysis
- **gosec**: For security scanning
- **govulncheck**: For vulnerability checking
- **go-licenses**: For license compliance

### 3. Install Git Hooks

```bash
make hooks-install
# or manually:
lefthook install
```

### 4. Run Initial CI Check

```bash
make ci
```

## Development Workflow

### Daily Development

1. **Make changes** to the Go code in `tui-prototype/`
2. **Test locally**:

    ```bash
    make test
    ```

3. **Run full CI locally**:

    ```bash
    make ci-full
    ```

4. **Commit with conventional commits**:

    ```bash
    git add .
    git commit -m "feat: add new TUI navigation component"
    ```

### Available Make Targets

| Target                  | Description                   |
| ----------------------- | ----------------------------- |
| `make build`            | Build the application         |
| `make test`             | Run tests                     |
| `make lint`             | Run linting                   |
| `make ci`               | Run basic CI pipeline         |
| `make ci-full`          | Run comprehensive CI pipeline |
| `make hooks-run`        | Run Git hooks manually        |
| `make security`         | Run security scans            |
| `make release-snapshot` | Create snapshot release       |
| `make help`             | Show all available targets    |

### Git Hooks (Lefthook)

The project uses **Lefthook** instead of Husky for Git hooks. Hooks are configured in `lefthook.yml`:

- **pre-commit**: Runs formatting, linting, and tests
- **commit-msg**: Validates conventional commit format
- **pre-push**: Runs comprehensive tests and security checks

### Conventional Commits

This project follows [Conventional Commits](https://conventionalcommits.org/):

```bash
# Features
git commit -m "feat: add user authentication"
git commit -m "feat(ui): implement dark mode toggle"

# Bug fixes
git commit -m "fix: resolve memory leak in parser"
git commit -m "fix(installer): handle invalid disk paths"

# Breaking changes
git commit -m "feat!: redesign configuration API"

# Other types
git commit -m "docs: update installation guide"
git commit -m "test: add integration tests"
git commit -m "chore: update dependencies"
```

## Code Quality

### Linting

The project uses multiple linters configured in `.golangci.yml`:

```bash
# Basic linting
make lint

# CI-level comprehensive linting
make lint-ci

# Run golangci-lint directly
cd tui-prototype && golangci-lint run
```

### Testing

```bash
# Run tests
make test

# Run tests with coverage
make test-coverage

# Run tests with race detection
make test-race

# Run benchmarks
make bench
```

### Security

```bash
# Run security scan
make security

# Run individual tools
cd tui-prototype
gosec ./...
govulncheck ./...
```

## Release Process

### Snapshot Releases (Development)

```bash
make release-snapshot
```

### Tagged Releases (Production)

1. **Create and push a version tag**:

    ```bash
    git tag v1.0.0
    git push origin v1.0.0
    ```

2. **GitHub Actions will automatically**:
    - Run comprehensive tests
    - Build for multiple platforms
    - Create GitHub release
    - Build and push Docker images
    - Update Homebrew formula

### Manual Release Testing

```bash
# Test release locally
make release-dry-run

# Check release configuration
make release-check
```

## Project Structure

```
arch-base/
├── tui-prototype/          # Go application source
│   ├── main.go            # Application entry point
│   ├── installer.go       # Core installer logic
│   ├── screens.go         # TUI screens
│   ├── system.go          # System operations
│   ├── *_test.go          # Test files
│   ├── go.mod             # Go module definition
│   └── go.sum             # Go dependencies
├── scripts/               # Build and utility scripts
├── build/                 # Build artifacts (auto-generated)
├── .github/workflows/     # CI/CD workflows
├── .goreleaser.yaml       # GoReleaser configuration
├── lefthook.yml          # Git hooks configuration
├── .golangci.yml         # Go linting configuration
├── Makefile              # Build automation
└── README.md             # Project documentation
```

## Go Tools Installation Details

If you prefer manual installation or need specific versions:

```bash
# GoReleaser
go install github.com/goreleaser/goreleaser@latest

# Lefthook (Git hooks)
go install github.com/evilmartians/lefthook@latest

# Linting tools
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install honnef.co/go/tools/cmd/staticcheck@latest

# Security tools
go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest
go install golang.org/x/vuln/cmd/govulncheck@latest

# License compliance
go install github.com/google/go-licenses@latest

# Code formatting
go install mvdan.cc/gofumpt@latest
go install golang.org/x/tools/cmd/goimports@latest
```

## Troubleshooting

### Git Hooks Not Working

```bash
# Reinstall hooks
lefthook uninstall
lefthook install

# Check hook status
lefthook run pre-commit
```

### Build Issues

```bash
# Clean and rebuild
make clean
make build

# Update dependencies
cd tui-prototype
go mod tidy
go mod download
```

### CI Failures

```bash
# Run CI locally to debug
make ci-full

# Check specific issues
make lint-ci
make test-race
make security
```

## Additional Resources

- [Go Documentation](https://golang.org/doc/)
- [Bubble Tea Framework](https://github.com/charmbracelet/bubbletea)
- [GoReleaser Documentation](https://goreleaser.com/)
- [Lefthook Documentation](https://github.com/evilmartians/lefthook)
- [Conventional Commits](https://conventionalcommits.org/)

## Getting Help

- **Issues**: [GitHub Issues](https://github.com/damienbutt/arch-base/issues)
- **Discussions**: [GitHub Discussions](https://github.com/damienbutt/arch-base/discussions)
- **Wiki**: [Project Wiki](https://github.com/damienbutt/arch-base/wiki)
