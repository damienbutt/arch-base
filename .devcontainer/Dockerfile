# Use official Arch Linux base-devel image
FROM archlinux:base-devel

# Initialize and populate the pacman keyring (required for Arch containers)
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syyy

# Update package database and install essential packages including Go
RUN pacman -S --noconfirm \
        # Go and development tools
        go \
        # Editor and utilities
        git \
        nano \
        vim \
        neovim \
        tree \
        htop \
        jq \
        yq \
        yazi \
        wget \
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
# Using UID 1000 to match common host user IDs
RUN useradd -m -u 1000 -G wheel vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode

# Set up Go environment
ENV GOPATH=/go
ENV PATH=$PATH:/usr/bin:/go/bin

# Create Go workspace and VS Code directories
RUN mkdir -p /go/{bin,pkg,src} && \
    mkdir -p /home/vscode/.vscode-server && \
    mkdir -p /home/vscode/.cache && \
    mkdir -p /home/vscode/.config && \
    chown -R vscode:vscode /go /home/vscode

# Switch to vscode user
USER vscode
WORKDIR /workspace

# Default command - keep container running for VS Code
CMD ["sleep", "infinity"]
