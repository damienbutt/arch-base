# CI/CD Pipeline Documentation

This document describes the comprehensive CI/CD pipeline implemented for the
Arch-Base project.

## Overview

The project now includes a robust CI/CD pipeline that handles both the
Node.js/Yarn components and the new Go TUI application with automated testing,
linting, building, and releases.

## Workflows

### 1. Main CI/CD Pipeline (`.github/workflows/main.yml`)

**Triggers:**

- Push to `master` or `develop` branches
- Pull requests to `master` or `develop` branches

**Jobs:**

#### Go TUI CI (`go-ci`)

- **Dependencies**: Downloads and verifies Go modules
- **Linting**: Runs `go vet`, `staticcheck`, and `golangci-lint`
- **Testing**: Executes tests with race detection and coverage reporting
- **Benchmarking**: Runs performance benchmarks
- **Building**: Creates binaries for multiple platforms (Linux, macOS,
  Windows - AMD64/ARM64)
- **Artifacts**: Uploads build artifacts for downstream jobs

#### Node.js CI (`node-ci`)

- **Dependencies**: Installs Yarn dependencies with cache
- **Linting**: Runs project linting rules
- **Testing**: Executes Node.js test suite
- **Building**: Builds the Node.js project

#### Integration Testing (`integration-test`)

- **Dependencies**: Requires both `go-ci` and `node-ci` to complete
- **Integration**: Downloads artifacts and runs integration tests
- **Makefile Testing**: Validates all Makefile targets work correctly

#### Release (`release`)

- **Condition**: Only runs on `master` branch
- **Dependencies**: Requires all previous jobs to pass
- **Go Packaging**: Creates release packages for all platforms
- **GitHub Releases**: Automatically creates GitHub releases with binaries
- **Semantic Release**: Handles Node.js semantic versioning and releases

### 2. Security & Dependencies (`.github/workflows/security.yml`)

**Triggers:**

- Daily at 2 AM UTC (scheduled)
- Manual trigger (`workflow_dispatch`)
- Changes to dependency files

**Jobs:**

#### Security Scan (`security-scan`)

- **Go Security**: Runs `gosec` security scanner with SARIF output
- **Vulnerability Check**: Uses `govulncheck` for known vulnerabilities
- **Node.js Security**: Runs `yarn audit` for npm vulnerabilities
- **SARIF Upload**: Integrates with GitHub Security tab

#### Dependency Updates (`dependency-update`)

- **Automated Updates**: Updates Go and Node.js dependencies
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
make pre-commit     # Simulate pre-commit hooks
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

### Pre-commit Hooks

Install pre-commit hooks for automatic code quality:

```bash
# Install pre-commit (if not already installed)
pip install pre-commit

# Install hooks
pre-commit install

# Run manually on all files
pre-commit run --all-files
```

**Configured Hooks:**

- Go formatting (`go fmt`)
- Go vetting (`go vet`)
- Go testing
- Go module tidying
- Trailing whitespace removal
- YAML/JSON validation
- Markdown linting
- Shell script linting
- Security secret detection

## Configuration Files

### `.golangci.yml`

Comprehensive Go linting configuration with:

- 30+ enabled linters
- Custom rules for test files
- Performance and security checks
- Style and formatting validation

### `.pre-commit-config.yaml`

Pre-commit hooks configuration for:

- Multi-language support (Go, Shell, Markdown, YAML)
- Automated formatting and validation
- Security scanning
- File consistency checks

### `.markdownlint.yaml`

Markdown linting rules for documentation consistency.

## CI/CD Features

### ✅ Automated Testing

- Comprehensive test suites for Go and Node.js
- Race condition detection
- Coverage reporting with Codecov integration
- Performance benchmarking

### ✅ Code Quality

- Multi-level linting (basic → CI → security)
- Static analysis with multiple tools
- Pre-commit hooks for early catch
- Dependency vulnerability scanning

### ✅ Multi-Platform Builds

- Cross-compilation for Linux, macOS, Windows
- ARM64 and AMD64 architecture support
- Automated binary packaging
- Release artifact management

### ✅ Security

- Daily security scans
- Vulnerability database checks
- Dependency update automation
- Secret detection

### ✅ Release Management

- Semantic versioning
- Automated GitHub releases
- Multi-platform distribution packages
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

1. **Run `make pre-commit`** before committing
2. **Use `make ci`** to test locally before pushing
3. **Keep dependencies updated** with automated PRs
4. **Review security reports** in GitHub Security tab

### For Maintainers

1. **Monitor automated dependency PRs** for breaking changes
2. **Review security alerts** and apply patches promptly
3. **Use semantic commit messages** for proper versioning
4. **Test releases** before deployment

This CI/CD pipeline ensures code quality, security, and reliability while
automating repetitive tasks and enabling fast, confident deployments.
