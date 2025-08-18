# Arch-Base TUI Installer Makefile
# Build and manage the Go BubbleTea Arch Linux installer

# Build configuration
APP_NAME := arch-installer
GO_MODULE := github.com/damienbutt/arch-base
BUILD_DIR := build
SRC_DIR := .
INSTALL_DIR := /usr/local/bin

# Go build settings
GOOS := linux
GOARCH := amd64
CGO_ENABLED := 0

# Version information (from git tags and commit)
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')

# Build flags
LDFLAGS := -ldflags "-s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.buildTime=$(BUILD_TIME)"

# Default target
.PHONY: all
all: clean build

# Create build directory
build-dir:
	@echo "📁 Creating build directory..."
	@mkdir -p $(BUILD_DIR)

# Build the application
.PHONY: build
build: build-dir
	@echo "🔨 Building $(APP_NAME)..."
	@\
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
	go build $(LDFLAGS) -o $(BUILD_DIR)/$(APP_NAME) ./$(SRC_DIR)
	@echo "✅ Build complete: $(BUILD_DIR)/$(APP_NAME)"

# Build for development (with debug info)
.PHONY: build-dev
build-dev: build-dir
	@echo "🔨 Building $(APP_NAME) (development)..."
	@\
	go build -gcflags="all=-N -l" -o $(BUILD_DIR)/$(APP_NAME)-dev ./$(SRC_DIR)
	@echo "✅ Development build complete: $(BUILD_DIR)/$(APP_NAME)-dev"

# Clean build artifacts
.PHONY: clean
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@rm -f $(SRC_DIR)/$(APP_NAME)
	@echo "✅ Clean complete"

# Install the application system-wide
.PHONY: install
install: build
	@echo "📦 Installing $(APP_NAME) to $(INSTALL_DIR)..."
	@sudo cp $(BUILD_DIR)/$(APP_NAME) $(INSTALL_DIR)/
	@sudo chmod +x $(INSTALL_DIR)/$(APP_NAME)
	@echo "✅ Installation complete: $(INSTALL_DIR)/$(APP_NAME)"

# Uninstall the application
.PHONY: uninstall
uninstall:
	@echo "🗑️  Uninstalling $(APP_NAME)..."
	@sudo rm -f $(INSTALL_DIR)/$(APP_NAME)
	@echo "✅ Uninstall complete"

# Run the application directly
.PHONY: run
run: build
	@echo "🚀 Running $(APP_NAME)..."
	@./$(BUILD_DIR)/$(APP_NAME)

# Run the application in development mode
.PHONY: run-dev
run-dev:
	@echo "🚀 Running $(APP_NAME) (development)..."
	@go run ./$(SRC_DIR)

# Test the Go code
.PHONY: test
test:
	@echo "🧪 Running tests..."
	@go test -v ./...

# Run linting and formatting
.PHONY: lint
lint:
	@echo "🔍 Running linter..."
	@\
	go fmt ./... && \
	go vet ./... && \
	golangci-lint run 2>/dev/null || echo "⚠️  golangci-lint not found, skipping"

# Format Go code with goimports
.PHONY: fmt
fmt:
	@echo "📝 Formatting Go code with goimports..."
	@go tool goimports -w .
	@echo "✅ Formatting complete"

# Format Go code (basic)
.PHONY: fmt-basic
fmt-basic:
	@echo "📝 Basic Go formatting..."
	@go fmt ./...
	@echo "✅ Basic formatting complete"

# Tidy Go modules
.PHONY: tidy
tidy:
	@echo "📦 Tidying Go modules..."
	@go mod tidy
	@echo "✅ Module tidy complete"

# Download dependencies
.PHONY: deps
deps:
	@echo "📥 Downloading dependencies..."
	@go mod download
	@echo "✅ Dependencies downloaded"

# Run vulnerability check
.PHONY: vuln-check
vuln-check:
	@echo "🔍 Checking for vulnerabilities..."
	@go tool govulncheck ./...
	@echo "✅ Vulnerability check complete"

# Install git hooks with lefthook
.PHONY: hooks-install
hooks-install:
	@echo "🪝 Installing git hooks..."
	@go tool lefthook install
	@echo "✅ Git hooks installed"

# Run lefthook checks manually
.PHONY: hooks-run
hooks-run:
	@echo "🪝 Running git hook checks..."
	@go tool lefthook run pre-commit
	@echo "✅ Hook checks complete"

# Uninstall git hooks
.PHONY: hooks-uninstall
hooks-uninstall:
	@echo "🪝 Uninstalling git hooks..."
	@go tool lefthook uninstall
	@echo "✅ Git hooks uninstalled"

# Create a distributable package
.PHONY: package
package: build
	@echo "📦 Creating distribution package..."
	@mkdir -p $(BUILD_DIR)/dist
	@cp $(BUILD_DIR)/$(APP_NAME) $(BUILD_DIR)/dist/
	@cp README.md $(BUILD_DIR)/dist/
	@cp LICENSE $(BUILD_DIR)/dist/
	@cd $(BUILD_DIR) && tar -czf $(APP_NAME)-$(VERSION)-linux-amd64.tar.gz dist/
	@echo "✅ Package created: $(BUILD_DIR)/$(APP_NAME)-$(VERSION)-linux-amd64.tar.gz"

# Development workflow: clean, build, and run
.PHONY: dev
dev: clean build run

# GPG Development Setup
.PHONY: gpg-setup
gpg-setup:
	@echo "🔐 Setting up GPG for development container..."
	@if [ ! -f .devcontainer/.env ]; then \
		echo "📝 Creating .env file from template..."; \
		cp .devcontainer/.env.template .devcontainer/.env; \
		echo "✏️  Please edit .devcontainer/.env with your GPG configuration"; \
		echo "📖 See .devcontainer/GPG_SETUP_GUIDE.md for detailed instructions"; \
	else \
		echo "✅ .env file already exists"; \
	fi

.PHONY: gpg-export
gpg-export:
	@echo "🔑 Exporting GPG private key for container import..."
	@echo "💡 This will help you set up GPG_KEY_FILE in .env"
	@echo ""
	@echo "Available GPG keys:"
	@gpg --list-secret-keys --keyid-format LONG
	@echo ""
	@read -p "Enter the Key ID to export: " KEY_ID; \
	if [ -n "$$KEY_ID" ]; then \
		echo "📤 Exporting key $$KEY_ID to .devcontainer/private-key.asc..."; \
		gpg --export-secret-keys "$$KEY_ID" > .devcontainer/private-key.asc; \
		chmod 600 .devcontainer/private-key.asc; \
		echo "✅ Key exported. Add 'GPG_KEY_FILE=./private-key.asc' to .devcontainer/.env"; \
	else \
		echo "❌ No key ID provided"; \
	fi

.PHONY: gpg-test
gpg-test:
	@echo "🧪 Testing GPG setup in development container..."
	@docker-compose -f .devcontainer/docker-compose.yml exec devcontainer /home/vscode/setup-gpg.sh || \
		echo "⚠️  Container not running. Start with: docker-compose -f .devcontainer/docker-compose.yml up -d"

# Show build information
.PHONY: info
info:
	@echo "📋 Build Information:"
	@echo "   App Name:    $(APP_NAME)"
	@echo "   Version:     $(VERSION)"
	@echo "   Commit:      $(COMMIT)"
	@echo "   Build Time:  $(BUILD_TIME)"
	@echo "   Go Module:   $(GO_MODULE)"
	@echo "   Build Dir:   $(BUILD_DIR)"
	@echo "   Target OS:   $(GOOS)"
	@echo "   Target Arch: $(GOARCH)"

# CI/CD targets
.PHONY: ci
ci: deps lint test build
	@echo "✅ CI pipeline completed successfully"

# Full CI with coverage
.PHONY: ci-full
ci-full: deps lint test-coverage release-build
	@echo "✅ Full CI pipeline completed successfully"

# Run tests with coverage
.PHONY: test-coverage
test-coverage:
	@echo "🧪 Running tests with coverage..."
	@\
	go test -v -race -coverprofile=coverage.out ./... && \
	go tool cover -html=coverage.out -o coverage.html && \
	go tool cover -func=coverage.out | tail -1
	@echo "✅ Coverage report generated: $(SRC_DIR)/coverage.html"

# Run tests with race detection
.PHONY: test-race
test-race:
	@echo "🧪 Running tests with race detection..."
	@go test -v -race ./...

# Run benchmarks
.PHONY: bench
bench:
	@echo "⚡ Running benchmarks..."
	@go test -bench=. -benchmem ./...

# Security scanning
.PHONY: security
security:
	@echo "🔒 Running security scan..."
	@go tool gosec ./...

# Static analysis
.PHONY: static-analysis
static-analysis:
	@echo "🔍 Running static analysis..."
	@go vet ./...
	@go tool staticcheck ./...

# Comprehensive linting
.PHONY: lint-ci
lint-ci:
	@echo "🔍 Running comprehensive linting for CI..."
	@\
	go fmt ./... && \
	go vet ./... && \
	(command -v golangci-lint >/dev/null && golangci-lint run --verbose || echo "⚠️  golangci-lint not found")

# Verify dependencies
.PHONY: verify
verify:
	@echo "🔍 Verifying dependencies..."
	@\
	go mod verify && \
	go mod tidy && \
	git diff --exit-code go.mod go.sum || (echo "❌ go.mod or go.sum is not tidy" && exit 1)

# Pre-commit hook simulation
.PHONY: pre-commit
pre-commit: fmt lint test
	@echo "✅ Pre-commit checks passed"

# Run actual lefthook pre-commit hooks
.PHONY: pre-commit-hooks
pre-commit-hooks:
	@echo "🪝 Running lefthook pre-commit hooks..."
	@go tool lefthook run pre-commit
	@echo "✅ Lefthook pre-commit checks passed"

# Release preparation
.PHONY: prepare-release
prepare-release: verify lint-ci test-coverage security static-analysis release-check
	@echo "✅ Release preparation completed"

# GoReleaser targets
.PHONY: release-check
release-check:
	@echo "🔍 Checking release readiness..."
	@go tool goreleaser check

.PHONY: release-snapshot
release-snapshot:
	@echo "📦 Creating snapshot release..."
	@go tool goreleaser release --snapshot --clean

.PHONY: release-build
release-build:
	@echo "🔨 Building release with GoReleaser..."
	@go tool goreleaser build --snapshot --clean \
	fi

.PHONY: release-dry-run
release-dry-run:
	@echo "🧪 Dry run release..."
	@go tool goreleaser release --skip=publish --clean

# Show help
.PHONY: help
help:
	@echo "🏗️  Arch-Base TUI Installer Build System"
	@echo ""
	@echo "Available targets:"
	@echo ""
	@echo "📦 Build targets:"
	@echo "  build        Build the application for production"
	@echo "  build-dev    Build with debug information"
	@echo "  clean        Remove build artifacts"
	@echo ""
	@echo "🚀 Run targets:"
	@echo "  run          Build and run the application"
	@echo "  run-dev      Run in development mode (go run)"
	@echo "  install      Install to system (requires sudo)"
	@echo "  uninstall    Remove from system (requires sudo)"
	@echo ""
	@echo "🧪 Testing targets:"
	@echo "  test         Run tests"
	@echo "  test-coverage Run tests with coverage report"
	@echo "  test-race    Run tests with race detection"
	@echo "  bench        Run benchmarks"
	@echo ""
	@echo "� GPG Development Setup:"
	@echo "  gpg-setup    Create .env file from template"
	@echo "  gpg-export   Export GPG key for container import"
	@echo "  gpg-test     Test GPG setup in development container"
	@echo ""
	@echo "�🔍 Code quality targets:"
	@echo "  lint         Run basic linting and formatting"
	@echo "  lint-ci      Run comprehensive linting for CI"
	@echo "  fmt          Format Go code with goimports"
	@echo "  fmt-basic    Format Go code (basic go fmt)"
	@echo "  security     Run security scan (gosec)"
	@echo "  static-analysis Run static analysis (staticcheck)"
	@echo "  vuln-check   Check for vulnerabilities"
	@echo ""
	@echo "🪝 Git hooks targets:"
	@echo "  hooks-install   Install git hooks with lefthook"
	@echo "  hooks-run       Run git hook checks manually"
	@echo "  hooks-uninstall Uninstall git hooks"
	@echo ""
	@echo "📦 Dependency targets:"
	@echo "  deps         Download dependencies"
	@echo "  tidy         Tidy Go modules"
	@echo "  verify       Verify dependencies are clean"
	@echo ""
	@echo "🎯 CI/CD targets:"
	@echo "  ci           Basic CI pipeline (deps + lint + test + build)"
	@echo "  ci-full      Full CI pipeline with coverage and multi-platform builds"
	@echo "  pre-commit   Simulate pre-commit hooks"
	@echo "  prepare-release Complete release preparation"
	@echo ""
	@echo "📦 Release targets:"
	@echo "  release-check    Check release readiness with GoReleaser"
	@echo "  release-build    Build release artifacts with GoReleaser"
	@echo "  release-snapshot Create snapshot release"
	@echo "  release-dry-run  Dry run release process"
	@echo ""
	@echo "🪝 Git hooks targets:"
	@echo "  hooks-install    Install Lefthook git hooks"
	@echo "  hooks-run        Run pre-commit hooks manually"
	@echo "  hooks-uninstall  Uninstall git hooks"
	@echo ""
	@echo "📦 Package targets:"
	@echo "  package      Create distribution package"
	@echo "  release      Create release packages for all platforms"
	@echo ""
	@echo "ℹ️  Utility targets:"
	@echo "  dev          Development workflow (clean + build + run)"
	@echo "  info         Show build information"
	@echo "  help         Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make ci                # Run CI pipeline"
	@echo "  make pre-commit        # Check before committing"
	@echo "  make test-coverage     # Run tests with coverage"
	@echo "  make prepare-release   # Prepare for release"
	@echo "  make dev               # Quick development cycle"

# Default help if no target specified
.DEFAULT_GOAL := help
