# Use official Arch Linux base-devel image
FROM archlinux:base-devel

# Initialize and populate the pacman keyring (required for Arch containers)
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syyy

# Update package database and install essential packages including Go
RUN pacman -S --noconfirm --needed \
        # Go and development tools
        go \
        # Editor and utilities
        nano \
        vim \
        neovim \
        tree \
        htop \
        jq \
        yq \
        yazi \
        # Shell scripting tools
        shellcheck \
        # Network tools
        openssh

# Install Go tools from Arch repos where available
RUN pacman -S --noconfirm \
        golangci-lint \
        goreleaser \
        delve

# Create vscode user with bash (keeping it simple)
RUN useradd -mG wheel vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode

# Set up Go environment
ENV GOPATH=/go
ENV PATH=$PATH:/usr/bin:/go/bin

# Create Go workspace
RUN mkdir -p /go/{bin,pkg,src} && \
    chown -R vscode:vscode /go

# Switch to vscode user
USER vscode
WORKDIR /workspace

# Install a few essential Go tools that aren't in Arch repos
RUN go install golang.org/x/tools/cmd/goimports@latest && \
    go install golang.org/x/vuln/cmd/govulncheck@latest

# Default command - keep container running for VS Code
CMD ["sleep", "infinity"]
