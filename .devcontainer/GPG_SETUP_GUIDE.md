# GPG Key Automation Setup Guide

This guide shows you how to set up automatic GPG key importing and git configuration for your development container.

## 🚀 Quick Setup

### Step 1: Create Environment Configuration

Copy the template file:

```bash
cp .devcontainer/.env.template .devcontainer/.env
```

### Step 2: Configure Your GPG Key

Choose **one** of the following methods:

#### Method A: Mount Existing GPG Directory (Recommended)

```bash
# In .devcontainer/.env
AUTO_SETUP_GPG=true
GPG_KEY_ID=YOUR_KEY_ID_HERE
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your.email@example.com"
```

Find your key ID:

```bash
gpg --list-secret-keys --keyid-format LONG
```

#### Method B: Import Key File

```bash
# Export your private key
gpg --export-secret-keys YOUR_KEY_ID > .devcontainer/private-key.asc

# In .devcontainer/.env
AUTO_SETUP_GPG=true
GPG_KEY_FILE=./private-key.asc
GIT_USER_NAME="Your Name"
GIT_USER_EMAIL="your.email@example.com"
```

## 📁 File Structure

```
.devcontainer/
├── .env                    # Your local configuration (git-ignored)
├── .env.template          # Template for configuration
├── setup-gpg.sh          # Enhanced GPG setup script
├── private-key.asc        # Optional: Your exported GPG key
└── GPG_SETUP_GUIDE.md    # This file
```

## 🔧 Environment Variables

| Variable         | Description                    | Example              |
| ---------------- | ------------------------------ | -------------------- |
| `AUTO_SETUP_GPG` | Enable automatic GPG setup     | `true`               |
| `GPG_KEY_ID`     | Specific GPG key ID to use     | `ABC123DEF456789`    |
| `GPG_KEY_FILE`   | Path to GPG key file to import | `./private-key.asc`  |
| `GIT_USER_NAME`  | Git user name                  | `"John Doe"`         |
| `GIT_USER_EMAIL` | Git user email                 | `"john@example.com"` |

## 🎯 How It Works

1. **Container Starts**: Environment variables are loaded from `.env` file
2. **GPG Setup Runs**: Script automatically:
    - Configures git user (name/email)
    - Imports GPG key (if `GPG_KEY_FILE` specified)
    - Detects or uses specified key ID
    - Configures git for commit signing
3. **Ready to Use**: All commits are automatically signed

## 🔍 Verification

After container starts, verify the setup:

```bash
# Check git configuration
git config --global user.name
git config --global user.email
git config --global user.signingkey
git config --global commit.gpgsign

# Test GPG signing
echo "test" | gpg --clearsign

# Test signed commit
git commit --allow-empty -m "test signed commit"
```

## 🛠️ Troubleshooting

### No GPG keys found

-   Ensure `.gnupg` directory is mounted or key file exists
-   Check file paths are correct in `.env`
-   Verify key file permissions (should be readable)

### Specified key not found

-   Verify `GPG_KEY_ID` matches output of `gpg --list-secret-keys`
-   Key ID should be the long form (16 characters)

### Git user not configured

-   Ensure `GIT_USER_NAME` and `GIT_USER_EMAIL` are set in `.env`
-   Check for quotes around values with spaces

### Permission denied errors

-   Key files should have appropriate permissions
-   Container automatically fixes `.gnupg` directory permissions

## 🔒 Security Notes

-   **Never commit** `.env` files or private keys to version control
-   Use `.env` for local configuration only
-   Consider using GPG directory mounting over key file import
-   Private key files should have restricted permissions (600)

## 🎛️ Manual Override

You can always run the setup script manually:

```bash
# Interactive mode with full output
/home/vscode/setup-gpg.sh

# Quiet mode for automation
/home/vscode/setup-gpg.sh --quiet --auto
```
