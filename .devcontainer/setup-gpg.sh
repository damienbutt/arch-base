#!/bin/bash
# GPG Setup Script for Development Container
# This script helps set up GPG for commit signing in the container

set -e

echo "🔐 GPG Setup for Commit Signing"
echo "================================"

# Check if GPG is available
if ! command -v gpg &> /dev/null; then
    echo "❌ GPG is not installed in the container"
    exit 1
fi

echo "✅ GPG is available: $(gpg --version | head -1)"

# Check if GPG keys are available
if ! gpg --list-secret-keys &>/dev/null; then
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
    exit 0
fi

# List available keys
echo ""
echo "🗝️  Available GPG keys:"
gpg --list-secret-keys --keyid-format LONG

# Get the key ID
KEY_ID=$(gpg --list-secret-keys --keyid-format LONG | grep -E '^sec' | head -1 | sed 's/.*\/\([A-F0-9]*\) .*/\1/')

if [ -n "$KEY_ID" ]; then
    echo ""
    echo "🎯 Primary key found: $KEY_ID"

    # Check if git is configured
    CURRENT_SIGNING_KEY=$(git config --global user.signingkey 2>/dev/null || echo "")
    CURRENT_SIGN_COMMITS=$(git config --global commit.gpgsign 2>/dev/null || echo "false")

    if [ "$CURRENT_SIGNING_KEY" != "$KEY_ID" ] || [ "$CURRENT_SIGN_COMMITS" != "true" ]; then
        echo ""
        echo "⚙️  Configuring git for GPG signing..."
        git config --global user.signingkey "$KEY_ID"
        git config --global commit.gpgsign true
        git config --global gpg.program gpg
        echo "✅ Git configured for GPG signing"
    else
        echo "✅ Git is already configured for GPG signing"
    fi

    # Test GPG
    echo ""
    echo "🧪 Testing GPG signing..."
    if echo "test message" | gpg --clearsign --default-key "$KEY_ID" >/dev/null 2>&1; then
        echo "✅ GPG signing test successful!"
        echo ""
        echo "🎉 You can now sign commits with: git commit -S"
        echo "   Or all commits will be signed automatically if commit.gpgsign=true"
    else
        echo "❌ GPG signing test failed"
        echo "   This might be due to pinentry issues in the container"
        echo "   Try: export GPG_TTY=\$(tty)"
    fi
else
    echo "❌ No GPG key ID found"
fi

echo ""
echo "📋 Current git GPG configuration:"
echo "   user.signingkey: $(git config --global user.signingkey 2>/dev/null || echo 'not set')"
echo "   commit.gpgsign: $(git config --global commit.gpgsign 2>/dev/null || echo 'not set')"
echo "   gpg.program: $(git config --global gpg.program 2>/dev/null || echo 'not set')"
