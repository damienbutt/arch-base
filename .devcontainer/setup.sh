#!/bin/bash
set -e

echo "🏗️  Arch-Base Development Container"
echo "=================================="
echo ""
# Ensure system is up to date
echo "🔄 Updating system packages..."
sudo pacman -Syyu --noconfirm 2>/dev/null || echo "⚠️  Could not update system packages (no sudo access)"

echo "✅ Arch Linux development environment ready!"
echo ""
echo "📦 Go $(go version | cut -d' ' -f3) installed"
echo "🔧 Development tools available:"
echo "   • golangci-lint - Go linting"
echo "   • delve - Go debugger"
echo "   • goreleaser - Release automation"
echo "   • goimports - Import management"
echo "   • govulncheck - Vulnerability scanning"
echo ""

# Ensure workspace is properly owned by vscode user
sudo chown -R vscode:vscode /go 2>/dev/null || true

# Initialize Go modules if needed
if [ -f "/workspace/go.mod" ]; then
    echo "📚 Downloading Go dependencies..."
    go mod download
    echo "✅ Dependencies ready"

    # Install development tools from tools.go
    echo "🔧 Development tools available via 'go run'..."
    if [ -f "/workspace/tools.go" ]; then
        echo "✅ Development tools ready (lefthook, goimports, govulncheck)"
        echo "📝 Use: make help to see available commands"
    fi
fi

# Install git hooks if lefthook config exists
if [ -f "/workspace/lefthook.yml" ]; then
    echo "🪝 Installing git hooks..."
    go tool lefthook install 2>/dev/null || echo "⚠️  Could not install git hooks (no git repo)"
fi

echo ""
echo "🚀 Common commands:"
echo "   make help          - Show all available make targets"
echo "   make test          - Run tests"
echo "   make build         - Build the application"
echo "   make release-build - Build release with GoReleaser"
echo "   make run           - Build and run the application"
echo ""
echo "📁 Project structure:"
echo "   main.go           - Application entry point"
echo "   internal/         - Internal packages"
echo "   scripts/          - Installation scripts"
echo "   Makefile          - Build automation"
echo ""
echo "🎉 Setup complete - happy hacking!"
echo ""
