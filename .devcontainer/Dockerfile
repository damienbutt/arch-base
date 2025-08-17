# Use official Arch Linux image
FROM archlinux:latest

# Set non-interactive mode for package installation
ENV DEBIAN_FRONTEND=noninteractive

# Update package database and install base packages
RUN pacman -Syu --noconfirm && \
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
        openssh \
        sudo

# Install Go
ENV GO_VERSION=1.21.0
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz | tar -xzC /usr/local && \
    ln -s /usr/local/go/bin/go /usr/local/bin/go && \
    ln -s /usr/local/go/bin/gofmt /usr/local/bin/gofmt

# Create vscode user
RUN useradd -m -s /bin/zsh -G wheel vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up Go environment
ENV GOPATH=/go
ENV PATH=$PATH:/usr/local/go/bin:/go/bin

# Create Go workspace
RUN mkdir -p /go/{bin,pkg,src} && \
    chown -R vscode:vscode /go

# Install Arch Linux specific tools
RUN pacman -S --noconfirm \
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

# Switch to vscode user
USER vscode
WORKDIR /home/vscode

# Install Oh My Zsh
RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Install Go tools
RUN go install github.com/goreleaser/goreleaser@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install github.com/evilmartians/lefthook@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install golang.org/x/tools/cmd/godoc@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    go install github.com/securecodewarrior/sast-scan/cmd/gosec@latest

# Set working directory
WORKDIR /workspace

# Expose common ports
EXPOSE 8080 9000 2345

# Default command
CMD ["zsh"]
