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

# Show help
.PHONY: help
help:
	@echo "🏗️  Arch-Base TUI Installer Build System"
	@echo ""
	@echo "Available targets:"
	@echo "  build        Build the application for production"
	@echo "  build-dev    Build with debug information"
	@echo "  build-all    Build for multiple platforms"
	@echo "  clean        Remove build artifacts"
	@echo "  install      Install to system (requires sudo)"
	@echo "  uninstall    Remove from system (requires sudo)"
	@echo "  run          Build and run the application"
	@echo "  run-dev      Run in development mode (go run)"
	@echo "  test         Run tests"
	@echo "  lint         Run linting and formatting"
	@echo "  fmt          Format Go code"
	@echo "  tidy         Tidy Go modules"
	@echo "  deps         Download dependencies"
	@echo "  package      Create distribution package"
	@echo "  release      Create release packages for all platforms"
	@echo "  dev          Development workflow (clean + build + run)"
	@echo "  info         Show build information"
	@echo "  help         Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make build              # Build for production"
	@echo "  make run               # Build and run"
	@echo "  make dev               # Clean, build, and run"
	@echo "  make install           # Install system-wide"
	@echo "  make release           # Create release packages"

# Default help if no target specified
.DEFAULT_GOAL := help
