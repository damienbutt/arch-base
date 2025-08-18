# GPG Setup for Development Container

This guide explains how to set up GPG commit signing in the development container.

## What's Configured

The development container includes:

-   **GPG installed** - `gnupg` and `pinentry` packages
-   **GPG configuration** - Custom `gpg.conf` for container environment
-   **Environment variables** - `GPG_TTY` and `GNUPGHOME` set correctly
-   **Volume mount** - Your host `~/.gnupg` directory is mounted read-only
-   **Setup script** - `~/setup-gpg.sh` to configure git automatically

## Quick Setup

1. **Start the container** and open a terminal
2. **Run the setup script**:
    ```bash
    ~/setup-gpg.sh
    ```
3. **Test signing**:
    ```bash
    git commit -S -m "test signed commit"
    ```

## Manual Setup

If the automatic setup doesn't work, you can configure manually:

### 1. Check GPG Keys

```bash
gpg --list-secret-keys --keyid-format LONG
```

### 2. Configure Git

```bash
# Replace YOUR_KEY_ID with your actual key ID
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
git config --global gpg.program gpg
```

### 3. Set GPG TTY

```bash
export GPG_TTY=$(tty)
```

## Troubleshooting

### Problem: "gpg: signing failed: No secret key"

**Solution**: Your GPG keys aren't available in the container.

```bash
# Check if keys are mounted
ls -la ~/.gnupg/
# If empty, your keys didn't mount properly
```

### Problem: "gpg: signing failed: Inappropriate ioctl for device"

**Solution**: Set the GPG TTY environment variable.

```bash
export GPG_TTY=$(tty)
# Add this to your shell profile to persist
echo 'export GPG_TTY=$(tty)' >> ~/.bashrc
```

### Problem: GPG asks for passphrase but doesn't show prompt

**Solution**: Configure pinentry for container environment.

```bash
echo "pinentry-mode loopback" >> ~/.gnupg/gpg.conf
```

### Problem: Permission denied on GPG directory

**Solution**: Fix permissions.

```bash
chmod 700 ~/.gnupg
chmod 600 ~/.gnupg/*
```

## How It Works

1. **Host GPG Directory**: Your `~/.gnupg` directory is mounted into the container at `/home/vscode/.gnupg`
2. **Environment**: `GPG_TTY` is set to enable proper terminal interaction
3. **Configuration**: Custom `gpg.conf` optimizes GPG for container use
4. **Git Integration**: Git is configured to use GPG for commit signing

## Alternative: Import Keys

If volume mounting doesn't work, you can import your keys manually:

```bash
# Export from host (run on your macOS machine)
gpg --armor --export-secret-keys YOUR_KEY_ID > private-key.asc

# Import in container
gpg --import private-key.asc

# Clean up
rm private-key.asc
```

## Verifying Setup

```bash
# Check GPG functionality
echo "test" | gpg --clearsign

# Check git configuration
git config --list | grep -E "(signingkey|gpgsign|gpg\.program)"

# Test commit signing
git commit --allow-empty -S -m "test signed commit"
```

## Security Notes

-   The container mounts your GPG directory **read-only** for security
-   GPG keys remain on your host system
-   The container cannot modify your GPG keyring
-   Always verify your setup in a test repository first
