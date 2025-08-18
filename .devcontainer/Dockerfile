# Use official Arch Linux image and install base-devel
FROM archlinux:latest

# Initialize and populate the pacman keyring, then install base-devel
RUN pacman-key --init && \
    pacman-key --populate archlinux && \
    pacman -Syyy && \
    pacman -S --noconfirm base-devel

# Update package database and install essential packages including Go
RUN pacman -S --noconfirm \
        # Go and development tools
        go \
        # Editor and utilities
        git \
        git-lfs \
        git-delta \
        nano \
        vim \
        neovim \
        tree \
        htop \
        jq \
        yq \
        yazi \
        wget \
        fzf \
        ripgrep \
        ripgrep-all \
        atuin \
        less \
        eza \
        zoxide \
        bat \
        zsh \
        # Shell scripting tools
        shellcheck \
        # Network tools
        openssh \
        # Prompt
        starship

# Using UID 1000 to match common host user IDs
RUN useradd -m -u 1000 -s /bin/zsh -G wheel vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/vscode && \
    chmod 0440 /etc/sudoers.d/vscode

# Set up Go environment
ENV GOPATH=/go
ENV PATH=$PATH:/usr/bin:/go/bin
ENV SHELL=/bin/zsh

# Create Go workspace and VS Code directories
RUN mkdir -p /go/{bin,pkg,src} && \
    mkdir -p /home/vscode/.vscode-server && \
    mkdir -p /home/vscode/.cache && \
    mkdir -p /home/vscode/.config && \
    mkdir -p /home/vscode/.gnupg && \
    chown -R vscode:vscode /go /home/vscode

# Copy custom bashrc, starship config, and GPG config
COPY .bashrc /home/vscode/.bashrc
COPY .zshrc /home/vscode/.zshrc
COPY starship.toml /home/vscode/.config/starship.toml
COPY atuin.toml /home/vscode/.config/atuin/config.toml
COPY gpg.conf /home/vscode/.gnupg/gpg.conf
COPY setup-gpg.sh /home/vscode/setup-gpg.sh
COPY init-container.sh /home/vscode/init-container.sh
RUN chown vscode:vscode /home/vscode/.bashrc && \
    chown vscode:vscode /home/vscode/.zshrc && \
    chown -R vscode:vscode /home/vscode/.config && \
    chown -R vscode:vscode /home/vscode/.gnupg && \
    chown vscode:vscode /home/vscode/setup-gpg.sh && \
    chown vscode:vscode /home/vscode/init-container.sh && \
    chmod 700 /home/vscode/.gnupg && \
    chmod 600 /home/vscode/.gnupg/gpg.conf && \
    chmod +x /home/vscode/setup-gpg.sh && \
    chmod +x /home/vscode/init-container.sh

# Switch to vscode user
USER vscode
WORKDIR /home/vscode

# Install paru-bin from AUR (as vscode user)
RUN git clone https://aur.archlinux.org/paru-bin && \
    cd paru-bin && \
    makepkg -si --noconfirm && \
    cd && \
    rm -rf paru-bin

# Install emojify from AUR using paru
RUN paru -S --noconfirm \
        emojify \
        doggo-bin

# Set working directory back to workspace
WORKDIR /workspace

# Default command - keep container running for VS Code
CMD ["sleep", "infinity"]
