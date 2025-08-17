#!/bin/bash
# Go Development Tools Installation Script
# This script installs all necessary Go tools for the arch-base project

set -e

echo "🔧 Installing Go development tools for arch-base project..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go first: https://golang.org/dl/"
    exit 1
fi

echo "✅ Go version: $(go version)"

# Install build and development tools
echo ""
echo "📦 Installing build and development tools..."

# GoReleaser for releases
echo "Installing GoReleaser..."
go install github.com/goreleaser/goreleaser@latest

# Lefthook for Git hooks
echo "Installing Lefthook..."
go install github.com/evilmartians/lefthook@latest

# Code quality tools
echo ""
echo "🔍 Installing code quality tools..."

# golangci-lint for comprehensive linting
echo "Installing golangci-lint..."
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# staticcheck for static analysis
echo "Installing staticcheck..."
go install honnef.co/go/tools/cmd/staticcheck@latest

# Security tools
echo ""
echo "🔒 Installing security tools..."

# gosec for security scanning
echo "Installing gosec..."
go install github.com/securecodewarrior/gosec/v2/cmd/gosec@latest

# govulncheck for vulnerability checking
echo "Installing govulncheck..."
go install golang.org/x/vuln/cmd/govulncheck@latest

# License checking tool
echo ""
echo "📄 Installing license tools..."

# go-licenses for license compliance
echo "Installing go-licenses..."
go install github.com/google/go-licenses@latest

# Utility tools
echo ""
echo "🛠️  Installing utility tools..."

# gofumpt for enhanced formatting
echo "Installing gofumpt..."
go install mvdan.cc/gofumpt@latest

# gotests for test generation
echo "Installing gotests..."
go install github.com/cweill/gotests/gotests@latest

# goimports for import management
echo "Installing goimports..."
go install golang.org/x/tools/cmd/goimports@latest

echo ""
echo "✅ All Go tools installed successfully!"
echo ""
echo "🪝 Setting up Git hooks with Lefthook..."
if [ -f "lefthook.yml" ]; then
    lefthook install
    echo "✅ Git hooks installed successfully!"
else
    echo "⚠️  lefthook.yml not found. Please run this script from the project root."
fi

echo ""
echo "🎉 Setup complete! You can now use:"
echo "  make ci          # Run CI pipeline locally"
echo "  make hooks-run   # Run Git hooks manually"
echo "  make help        # Show all available commands"
echo ""
echo "📝 Optional: Install pre-commit for additional validation:"
echo "  pip install pre-commit && pre-commit install"
