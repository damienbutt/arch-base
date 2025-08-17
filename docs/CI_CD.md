# CI/CD Pipeline Documentation

This document describes the comprehensive CI/CD pipeline implemented for the
Arch-Base Go project.

## Overview

The project includes a robust CI/CD pipeline for the Go TUI application with
automated testing, linting, building, security scanning, and releases using
modern Go tooling.

## Workflows

### 1. Main CI/CD Pipeline (`.github/workflows/main.yml`)

**Triggers:**

- Push to `master` or `develop` branches
- Pull requests to `master` or `develop` branches
- Version tags (`v*`)

**Jobs:**

#### Test & Lint (`test`)

- **Dependencies**: Downloads and verifies Go modules
- **Linting**: Runs `go vet`, `staticcheck`, and `golangci-lint`
- **Security**: Runs `gosec` security scanner and `govulncheck`
- **Testing**: Executes tests with race detection and coverage reporting
- **Benchmarking**: Runs performance benchmarks
- **Coverage**: Uploads coverage reports to Codecov

#### Build (`build`)

- **GoReleaser**: Uses GoReleaser for cross-platform builds
- **Snapshot Builds**: Creates snapshot builds for non-tag pushes
- **Artifacts**: Uploads build artifacts for downstream jobs

#### Integration Testing (`integration-test`)

- **Dependencies**: Requires `build` job to complete
- **Integration**: Downloads artifacts and runs integration tests
- **Makefile Testing**: Validates all Makefile targets work correctly

#### Release (`release`)

- **Condition**: Only runs on version tags (`v*`)
- **Dependencies**: Requires `test` and `integration-test` to pass
- **GoReleaser**: Creates release packages for Linux platforms
- **GitHub Releases**: Automatically creates GitHub releases with binaries
- **Linux Focus**: Builds for Linux AMD64 and ARM64 only (Arch Linux specific)
- **AUR Package**: Automatically creates AUR package for Arch Linux

### 2. Security & Dependencies (`.github/workflows/security.yml`)

**Triggers:**

- Daily at 2 AM UTC (scheduled)
- Manual trigger (`workflow_dispatch`)
- Changes to Go dependency files

**Jobs:**

#### Security Scan (`security-scan`)

- **Go Security**: Runs `gosec` security scanner with SARIF output
- **Vulnerability Check**: Uses `govulncheck` for known vulnerabilities
- **SARIF Upload**: Integrates with GitHub Security tab

#### Dependency Updates (`dependency-update`)

- **Automated Updates**: Updates Go dependencies
- **Pull Request Creation**: Automatically creates PRs for dependency updates
- **Change Detection**: Only creates PRs when changes are detected

#### License Compliance (`license-check`)

- **License Scanning**: Generates license reports for all dependencies
- **Compliance**: Ensures license compatibility
- **Reporting**: Creates artifacts with license information

## Local Development

### Makefile Targets

The project includes comprehensive Makefile targets for local development:

#### Basic Operations

```bash
make build          # Build for production
make test           # Run tests
make run            # Build and run
make clean          # Clean build artifacts
```

#### CI/CD Operations

```bash
make ci             # Basic CI pipeline locally
make ci-full        # Full CI with coverage and multi-platform builds
make hooks-run      # Run git hooks manually
make prepare-release # Complete release preparation
```

#### Testing

```bash
make test-coverage  # Run tests with coverage report
make test-race      # Run tests with race detection
make bench          # Run benchmarks
```

#### Code Quality

```bash
make lint           # Basic linting
make lint-ci        # Comprehensive CI linting
make security       # Security scanning
make static-analysis # Static code analysis
```

#### Release & Hooks

```bash
make release-check     # Check release readiness with GoReleaser
make release-snapshot  # Create snapshot release
make release-dry-run   # Dry run release process
make hooks-install     # Install Lefthook git hooks
make hooks-uninstall   # Uninstall git hooks
```

### Git Hooks (Lefthook)

Install Lefthook for automatic code quality:

```bash
# Install lefthook (if not already installed)
go install github.com/evilmartians/lefthook@latest

# Install hooks
make hooks-install

# Run manually
make hooks-run
```

**Configured Hooks:**

- Go formatting (`go fmt`)
- Go vetting (`go vet`)
- Go testing
- Go module tidying
- golangci-lint with auto-fix
- Trailing whitespace removal
- Merge conflict detection
- Conventional commit validation
- Security scanning on push

## Configuration Files

### `.goreleaser.yaml`

GoReleaser configuration for automated releases:

- Linux-only builds (AMD64 and ARM64) - Arch Linux specific
- GitHub releases with binaries and changelogs
- AUR package generation for Arch Linux distribution
- Checksum generation and verification
- Focused on Arch Linux ecosystem

### `lefthook.yml`

Lefthook Git hooks configuration:

- Pre-commit: Go formatting, linting, testing, file validation
- Commit-msg: Conventional commit format validation
- Pre-push: Comprehensive testing and security scanning
- Parallel execution for faster hook processing

### `.golangci.yml`

Comprehensive Go linting configuration with:

- 30+ enabled linters
- Custom rules for test files
- Performance and security checks
- Style and formatting validation

### `.pre-commit-config.yaml`

Alternative pre-commit hooks configuration for:

- Multi-language support (Go, Shell, Markdown, YAML)
- Automated formatting and validation
- Security scanning
- File consistency checks

### `.markdownlint.yaml`

Markdown linting rules for documentation consistency.

## CI/CD Features

### ✅ Automated Testing

- Comprehensive test suites for Go application
- Race condition detection
- Coverage reporting with Codecov integration
- Performance benchmarking

### ✅ Code Quality

- Multi-level linting (basic → CI → security)
- Static analysis with multiple tools
- Lefthook hooks for early catch
- Dependency vulnerability scanning

### ✅ Multi-Platform Builds

- Cross-compilation for Linux AMD64 and ARM64
- Arch Linux focused distribution
- Automated binary packaging with GoReleaser
- AUR package generation for Arch Linux users

### ✅ Security

- Daily security scans with gosec
- Vulnerability database checks with govulncheck
- Dependency update automation
- Secret detection and SARIF reporting

### ✅ Release Management

- Semantic versioning with Git tags
- Automated GitHub releases with GoReleaser
- Linux-focused distribution packages
- AUR package for Arch Linux distribution
- License compliance checking

## Monitoring & Reports

### GitHub Integration

- **Security Tab**: SARIF reports from security scans
- **Actions Tab**: CI/CD pipeline status and logs
- **Releases**: Automated releases with binaries
- **Pull Requests**: Automated dependency updates

### Artifacts

- **Build Binaries**: Multi-platform executables
- **Coverage Reports**: HTML coverage reports
- **License Reports**: Dependency license information
- **Security Reports**: SARIF security scan results

## Best Practices

### For Developers

1. **Run `make hooks-run`** before committing
2. **Use `make ci`** to test locally before pushing
3. **Keep dependencies updated** with automated PRs
4. **Review security reports** in GitHub Security tab
5. **Follow conventional commits** for proper release automation

### For Maintainers

1. **Monitor automated dependency PRs** for breaking changes
2. **Review security alerts** and apply patches promptly
3. **Create version tags** for releases: `git tag v1.0.0 && git push origin v1.0.0`
4. **Monitor GoReleaser releases** and Docker image builds
5. **Test releases** before promoting to production

This CI/CD pipeline ensures code quality, security, and reliability while
automating repetitive tasks and enabling fast, confident deployments using
modern Go tooling.
