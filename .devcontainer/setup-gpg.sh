#!/bin/bash
# GPG Setup Script for Development Container
# This script helps set up GPG for commit signing in the container

set -e

# Parse arguments
QUIET=false
AUTO_CONFIGURE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --quiet)
            QUIET=true
            shift
            ;;
        --auto)
            AUTO_CONFIGURE=true
            shift
            ;;
        *)
            echo "Usage: $0 [--quiet] [--auto]"
            echo "  --quiet: Suppress output except errors"
            echo "  --auto: Automatically configure git without prompts"
            exit 1
            ;;
    esac
done

# Helper function for conditional output
log() {
    if [ "$QUIET" = false ]; then
        echo "$@"
    fi
}

log "🔐 GPG Setup for Commit Signing"
log "================================"

# Check if GPG is available
if ! command -v gpg &> /dev/null; then
    echo "❌ GPG is not installed in the container"
    exit 1
fi

log "✅ GPG is available: $(gpg --version | head -1)"

# Function to import GPG key from file
import_gpg_key() {
    local key_file="$1"
    if [ -f "$key_file" ]; then
        log "📥 Importing GPG key from: $key_file"
        if gpg --import "$key_file" 2>/dev/null; then
            log "✅ GPG key imported successfully"
            return 0
        else
            echo "❌ Failed to import GPG key from: $key_file"
            return 1
        fi
    else
        echo "❌ GPG key file not found: $key_file"
        return 1
    fi
}

# Function to configure git user
configure_git_user() {
    if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
        log "👤 Configuring git user information..."
        git config --global user.name "$GIT_USER_NAME"
        git config --global user.email "$GIT_USER_EMAIL"
        log "✅ Git user configured: $GIT_USER_NAME <$GIT_USER_EMAIL>"
    fi
}

# Configure git user first if environment variables are set
configure_git_user

# Try to import GPG key if specified in environment
if [ -n "$GPG_KEY_FILE" ] && [ ! -f "$GPG_KEY_FILE" ]; then
    # Try relative to workspace
    if [ -f "/workspace/$GPG_KEY_FILE" ]; then
        GPG_KEY_FILE="/workspace/$GPG_KEY_FILE"
    fi
fi

if [ -n "$GPG_KEY_FILE" ]; then
    import_gpg_key "$GPG_KEY_FILE"
fi

# Check if GPG keys are available
if ! gpg --list-secret-keys &>/dev/null; then
    if [ "$QUIET" = false ]; then
        echo ""
        echo "🗝️  No GPG keys found in the container."
        echo ""
        echo "To set up GPG for commit signing:"
        echo "1. Import your GPG keys from the host:"
        echo "   gpg --import /path/to/your/private-key.asc"
        echo ""
        echo "2. Or copy your GPG directory (if not already mounted):"
        echo "   cp -r ~/.gnupg/* /home/vscode/.gnupg/"
        echo ""
        echo "3. Configure git to use your GPG key:"
        echo "   git config --global user.signingkey YOUR_KEY_ID"
        echo "   git config --global commit.gpgsign true"
        echo ""
        echo "4. Test with:"
        echo "   echo 'test' | gpg --clearsign"
        echo ""
    fi
    exit 0
fi

# List available keys
log ""
log "🗝️  Available GPG keys:"
if [ "$QUIET" = false ]; then
    gpg --list-secret-keys --keyid-format LONG
fi

# Get the key ID - prefer environment variable if set
if [ -n "$GPG_KEY_ID" ]; then
    # Verify the specified key exists
    if gpg --list-secret-keys --keyid-format LONG | grep -q "$GPG_KEY_ID"; then
        KEY_ID="$GPG_KEY_ID"
        log ""
        log "🎯 Using specified key: $KEY_ID"
    else
        echo "❌ Specified GPG key ID not found: $GPG_KEY_ID"
        echo "Available keys:"
        gpg --list-secret-keys --keyid-format LONG
        exit 1
    fi
else
    # Auto-detect first available key
    KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep -E '^sec' | head -1 | sed 's/.*\/\([A-F0-9]*\) .*/\1/')
    if [ -n "$KEY_ID" ]; then
        log ""
        log "🎯 Auto-detected key: $KEY_ID"
    fi
fi

    # Check if git is configured
    CURRENT_SIGNING_KEY=$(git config --global user.signingkey 2>/dev/null || echo "")
    CURRENT_SIGN_COMMITS=$(git config --global commit.gpgsign 2>/dev/null || echo "false")

    if [ "$CURRENT_SIGNING_KEY" != "$KEY_ID" ] || [ "$CURRENT_SIGN_COMMITS" != "true" ]; then
        log ""
        log "⚙️  Configuring git for GPG signing..."
        git config --global user.signingkey "$KEY_ID"
        git config --global commit.gpgsign true
        git config --global gpg.program gpg
        log "✅ Git configured for GPG signing"
    else
        log "✅ Git is already configured for GPG signing"
    fi

    # Test GPG (skip in quiet mode to avoid pinentry issues)
    if [ "$QUIET" = false ] && [ "$AUTO_CONFIGURE" = false ]; then
        log ""
        log "🧪 Testing GPG signing..."
        if echo "test message" | gpg --clearsign --default-key "$KEY_ID" >/dev/null 2>&1; then
            log "✅ GPG signing test successful!"
            log ""
            log "🎉 You can now sign commits with: git commit -S"
            log "   Or all commits will be signed automatically if commit.gpgsign=true"
        else
            log "❌ GPG signing test failed"
            log "   This might be due to pinentry issues in the container"
            log "   Try: export GPG_TTY=\$(tty)"
        fi
    fi
else
    echo "❌ No GPG key ID found"
    exit 1
fi

if [ "$QUIET" = false ]; then
    echo ""
    echo "📋 Current git GPG configuration:"
    echo "   user.signingkey: $(git config --global user.signingkey 2>/dev/null || echo 'not set')"
    echo "   commit.gpgsign: $(git config --global commit.gpgsign 2>/dev/null || echo 'not set')"
    echo "   gpg.program: $(git config --global gpg.program 2>/dev/null || echo 'not set')"
fi
