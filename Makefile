# Arch-Base TUI Installer Makefile
# Build and manage the Go BubbleTea Arch Linux installer

# Build configuration
APP_NAME := arch-installer
GO_MODULE := tui-prototype
BUILD_DIR := build
SRC_DIR := tui-prototype
INSTALL_DIR := /usr/local/bin

# Go build settings
GOOS := linux
GOARCH := amd64
CGO_ENABLED := 0

# Version information (from git)
VERSION := $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME := $(shell date -u '+%Y-%m-%d_%H:%M:%S')

# Build flags
LDFLAGS := -ldflags "-s -w -X main.version=$(VERSION) -X main.commit=$(COMMIT) -X main.buildTime=$(BUILD_TIME)"

# Default target
.PHONY: all
all: clean build

# Create build directory
$(BUILD_DIR):
	@echo "📁 Creating build directory..."
	@mkdir -p $(BUILD_DIR)

# Build the application
.PHONY: build
build: $(BUILD_DIR)
	@echo "🔨 Building $(APP_NAME)..."
	@cd $(SRC_DIR) && \
	CGO_ENABLED=$(CGO_ENABLED) GOOS=$(GOOS) GOARCH=$(GOARCH) \
	go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(APP_NAME) .
	@echo "✅ Build complete: $(BUILD_DIR)/$(APP_NAME)"

# Build for development (with debug info)
.PHONY: build-dev
build-dev: $(BUILD_DIR)
	@echo "🔨 Building $(APP_NAME) (development)..."
	@cd $(SRC_DIR) && \
	go build -gcflags="all=-N -l" -o ../$(BUILD_DIR)/$(APP_NAME)-dev .
	@echo "✅ Development build complete: $(BUILD_DIR)/$(APP_NAME)-dev"

# Build for multiple platforms
.PHONY: build-all
build-all: $(BUILD_DIR)
	@echo "🔨 Building $(APP_NAME) for multiple platforms..."
	@cd $(SRC_DIR) && \
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(APP_NAME)-linux-amd64 . && \
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(APP_NAME)-linux-arm64 . && \
	CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(APP_NAME)-darwin-amd64 . && \
	CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(APP_NAME)-darwin-arm64 . && \
	CGO_ENABLED=0 GOOS=windows GOARCH=amd64 go build $(LDFLAGS) -o ../$(BUILD_DIR)/$(APP_NAME)-windows-amd64.exe .
	@echo "✅ Multi-platform builds complete in $(BUILD_DIR)/"

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
	@cd $(SRC_DIR) && go run .

# Test the Go code
.PHONY: test
test:
	@echo "🧪 Running tests..."
	@cd $(SRC_DIR) && go test -v ./...

# Run linting and formatting
.PHONY: lint
lint:
	@echo "🔍 Running linter..."
	@cd $(SRC_DIR) && \
	go fmt ./... && \
	go vet ./... && \
	golangci-lint run 2>/dev/null || echo "⚠️  golangci-lint not found, skipping"

# Format Go code
.PHONY: fmt
fmt:
	@echo "📝 Formatting Go code..."
	@cd $(SRC_DIR) && go fmt ./...
	@echo "✅ Formatting complete"

# Tidy Go modules
.PHONY: tidy
tidy:
	@echo "📦 Tidying Go modules..."
	@cd $(SRC_DIR) && go mod tidy
	@echo "✅ Module tidy complete"

# Download dependencies
.PHONY: deps
deps:
	@echo "📥 Downloading dependencies..."
	@cd $(SRC_DIR) && go mod download
	@echo "✅ Dependencies downloaded"

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

# Create release packages for all platforms
.PHONY: release
release: build-all
	@echo "📦 Creating release packages..."
	@mkdir -p $(BUILD_DIR)/release
	@for binary in $(BUILD_DIR)/$(APP_NAME)-*; do \
		if [ -f "$$binary" ]; then \
			platform=$$(basename "$$binary" | sed 's/$(APP_NAME)-//'); \
			mkdir -p $(BUILD_DIR)/release/$(APP_NAME)-$(VERSION)-$$platform; \
			cp "$$binary" $(BUILD_DIR)/release/$(APP_NAME)-$(VERSION)-$$platform/$(APP_NAME)$$(echo $$platform | grep -q windows && echo .exe || echo ""); \
			cp README.md LICENSE $(BUILD_DIR)/release/$(APP_NAME)-$(VERSION)-$$platform/; \
			cd $(BUILD_DIR)/release && tar -czf $(APP_NAME)-$(VERSION)-$$platform.tar.gz $(APP_NAME)-$(VERSION)-$$platform/; \
			rm -rf $(APP_NAME)-$(VERSION)-$$platform/; \
		fi \
	done
	@echo "✅ Release packages created in $(BUILD_DIR)/release/"

# Development workflow: clean, build, and run
.PHONY: dev
dev: clean build run

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
ci-full: deps lint test-coverage build-all
	@echo "✅ Full CI pipeline completed successfully"

# Run tests with coverage
.PHONY: test-coverage
test-coverage:
	@echo "🧪 Running tests with coverage..."
	@cd $(SRC_DIR) && \
	go test -v -race -coverprofile=coverage.out ./... && \
	go tool cover -html=coverage.out -o coverage.html && \
	go tool cover -func=coverage.out | tail -1
	@echo "✅ Coverage report generated: $(SRC_DIR)/coverage.html"

# Run tests with race detection
.PHONY: test-race
test-race:
	@echo "🧪 Running tests with race detection..."
	@cd $(SRC_DIR) && go test -v -race ./...

# Run benchmarks
.PHONY: bench
bench:
	@echo "⚡ Running benchmarks..."
	@cd $(SRC_DIR) && go test -bench=. -benchmem ./...

# Security scanning
.PHONY: security
security:
	@echo "🔒 Running security scan..."
	@cd $(SRC_DIR) && \
	(command -v gosec >/dev/null && gosec ./... || echo "⚠️  gosec not found, install with: go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest")

# Static analysis
.PHONY: static-analysis
static-analysis:
	@echo "🔍 Running static analysis..."
	@cd $(SRC_DIR) && \
	go vet ./... && \
	(command -v staticcheck >/dev/null && staticcheck ./... || echo "⚠️  staticcheck not found, install with: go install honnef.co/go/tools/cmd/staticcheck@latest")

# Comprehensive linting
.PHONY: lint-ci
lint-ci:
	@echo "🔍 Running comprehensive linting for CI..."
	@cd $(SRC_DIR) && \
	go fmt ./... && \
	go vet ./... && \
	(command -v golangci-lint >/dev/null && golangci-lint run --verbose || echo "⚠️  golangci-lint not found")

# Verify dependencies
.PHONY: verify
verify:
	@echo "🔍 Verifying dependencies..."
	@cd $(SRC_DIR) && \
	go mod verify && \
	go mod tidy && \
	git diff --exit-code go.mod go.sum || (echo "❌ go.mod or go.sum is not tidy" && exit 1)

# Pre-commit hook simulation
.PHONY: pre-commit
pre-commit: fmt lint test
	@echo "✅ Pre-commit checks passed"

# Release preparation
.PHONY: prepare-release
prepare-release: verify lint-ci test-coverage security static-analysis build-all package
	@echo "✅ Release preparation completed"

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
	@echo "  build-all    Build for multiple platforms"
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
	@echo "🔍 Code quality targets:"
	@echo "  lint         Run basic linting and formatting"
	@echo "  lint-ci      Run comprehensive linting for CI"
	@echo "  fmt          Format Go code"
	@echo "  security     Run security scan (gosec)"
	@echo "  static-analysis Run static analysis (staticcheck)"
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
