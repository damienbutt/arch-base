#!/bin/bash
set -e

echo "🏗️  Setting up Arch Linux development environment..."

# Update package database and system
echo "📦 Updating package database..."
pacman -Syu --noconfirm

# Install essential development tools
echo "🔧 Installing development tools..."
pacman -S --noconfirm \
    base-devel \
    git \
    curl \
    wget \
    unzip \
    tar \
    gzip \
    make \
    cmake \
    which \
    nano \
    vim \
    tree \
    htop \
    less \
    jq \
    yq \
    shellcheck \
    fd \
    ripgrep \
    bat \
    exa \
    zsh \
    openssh

# Install Go tools
echo "🐹 Installing Go development tools..."
go install github.com/goreleaser/goreleaser@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install github.com/evilmartians/lefthook@latest
go install golang.org/x/tools/cmd/goimports@latest
go install golang.org/x/tools/cmd/godoc@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install honnef.co/go/tools/cmd/staticcheck@latest
go install github.com/securecodewarrior/sast-scan/cmd/gosec@latest
go install github.com/fzipp/gocyclo/cmd/gocyclo@latest
go install github.com/client9/misspell/cmd/misspell@latest

# Install testing and coverage tools
echo "🧪 Installing testing tools..."
go install gotest.tools/gotestsum@latest
go install github.com/kyoh86/richgo@latest
go install github.com/rakyll/gotest@latest

# Install useful Arch Linux specific tools (for development context)
echo "🐧 Installing Arch Linux tools..."
pacman -S --noconfirm \
    archlinux-keyring \
    pacman-contrib \
    reflector \
    arch-install-scripts \
    dosfstools \
    e2fsprogs \
    btrfs-progs \
    xfsprogs \
    ntfs-3g \
    gptfdisk \
    parted \
    lvm2 \
    device-mapper \
    cryptsetup

# Setup Git configuration (if not already configured)
echo "🔧 Configuring development environment..."

# Create workspace directories
mkdir -p /workspace/{tmp,logs,coverage}

# Set up Go workspace
export GOPATH=/go
export PATH=$PATH:/go/bin
echo 'export GOPATH=/go' >> /home/vscode/.zshrc
echo 'export PATH=$PATH:/go/bin' >> /home/vscode/.zshrc

# Install Oh My Zsh plugins and themes
echo "🎨 Setting up Zsh environment..."
if [ -d "/home/vscode/.oh-my-zsh" ]; then
    # Install useful plugins
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-/home/vscode/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || true
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-/home/vscode/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || true
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-/home/vscode/.oh-my-zsh/custom}/plugins/zsh-completions || true

    # Update .zshrc with plugins
    sed -i 's/plugins=(git)/plugins=(git golang docker docker-compose zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' /home/vscode/.zshrc || true
fi

# Set up aliases for development
echo "📝 Setting up development aliases..."
cat >> /home/vscode/.zshrc << 'EOF'

# Arch Base Development Aliases
alias ll='exa -la --git'
alias la='exa -la'
alias lt='exa --tree'
alias cat='bat'
alias grep='rg'
alias find='fd'

# Go development aliases
alias gt='go test ./...'
alias gtv='go test -v ./...'
alias gtr='go test -race ./...'
alias gtc='go test -cover ./...'
alias gb='go build ./...'
alias gr='go run .'
alias gf='go fmt ./...'
alias gl='golangci-lint run'

# Make aliases for the project
alias mb='make build'
alias mt='make test'
alias mc='make clean'
alias mr='make run'
alias mh='make help'
alias mrb='make release-build'
alias mrc='make release-check'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline'
alias gd='git diff'

# Project specific
alias arch-build='make build'
alias arch-test='make test'
alias arch-run='make run'
alias arch-release='make release-build'

EOF

# Fix permissions
chown -R vscode:vscode /home/vscode/.zshrc /go || true

# Initialize Go modules cache
echo "📚 Warming up Go modules cache..."
cd /workspace
if [ -f "go.mod" ]; then
    go mod download
fi

# Install lefthook if lefthook.yml exists
if [ -f "/workspace/lefthook.yml" ]; then
    echo "🪝 Installing git hooks..."
    lefthook install || true
fi

# Final setup
echo "🎯 Final setup..."
# Ensure correct ownership
chown -R vscode:vscode /go /home/vscode

echo "✅ Development environment setup complete!"
echo ""
echo "🚀 Ready for Arch Linux installer development!"
echo ""
echo "Available commands:"
echo "  make help          - Show all available make targets"
echo "  make test          - Run tests"
echo "  make build         - Build the application"
echo "  make release-build - Build release with GoReleaser"
echo "  arch-test          - Quick test alias"
echo "  arch-build         - Quick build alias"
echo ""
