#!/bin/bash
# Container initialization script
# Runs once when the container starts

set -e

echo "🚀 Initializing development container..."

# Ensure GPG TTY is set
export GPG_TTY=$(tty 2>/dev/null || echo "/dev/console")

# Initialize GPG if keys are available and auto-setup is enabled
if [ "$AUTO_SETUP_GPG" = "true" ] && command -v gpg &>/dev/null; then
    if gpg --list-secret-keys &>/dev/null && [ -z "$(git config --global user.signingkey 2>/dev/null)" ]; then
        echo "🔧 Running automatic GPG setup..."
        /home/vscode/setup-gpg.sh --quiet --auto || echo "⚠️  GPG auto-setup failed (non-critical)"
    fi
fi

# Ensure proper permissions on mounted GPG directory
if [ -d "/home/vscode/.gnupg" ]; then
    chown -R vscode:vscode /home/vscode/.gnupg 2>/dev/null || true
    chmod 700 /home/vscode/.gnupg 2>/dev/null || true
    chmod 600 /home/vscode/.gnupg/* 2>/dev/null || true
fi

echo "✅ Container initialization complete"

# Execute the original command or keep container running
exec "$@"
