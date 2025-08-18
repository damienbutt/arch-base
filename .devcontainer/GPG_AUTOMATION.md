# GPG Automation Options

This document outlines the various levels of GPG automation available in the development container.

## 🔧 Current Automation Levels

### Level 1: Manual Setup (Default)
- Run `/home/vscode/setup-gpg.sh` manually when needed
- Full interactive output and testing
- Complete control over when setup occurs

### Level 2: Shell Integration (Automatic)
- GPG setup runs automatically when opening new shell sessions
- Enabled by default via `.bashrc` integration
- Silent operation with minimal output
- Only runs if GPG keys are detected and git not yet configured

### Level 3: Container Environment (Controlled)
- Set `AUTO_SETUP_GPG=true` in docker-compose.yml (✅ ENABLED)
- Provides environment variable control
- Can be disabled by setting to `false` or removing variable
- Integrated with shell-level automation

### Level 4: VS Code Integration (VS Code Lifecycle)
- Runs via `postStartCommand` in devcontainer.json (✅ ENABLED)
- Executes after VS Code connects to container
- Minimal interference with development workflow
- Automatic and transparent

## 🎯 Current Configuration

```bash
# Enabled automation methods:
✅ Shell Integration (.bashrc)
✅ Environment Control (AUTO_SETUP_GPG=true)
✅ VS Code Integration (postStartCommand)
✅ Enhanced setup script with --quiet and --auto flags
```

## 🗝️ How It Works

1. **Container Starts**: VS Code connects and runs postStartCommand
2. **Shell Opens**: .bashrc checks for GPG keys and auto-configures
3. **Manual Override**: Run `/home/vscode/setup-gpg.sh` for full control

## 🛠️ Setup Script Options

```bash
# Interactive mode (full output and testing)
/home/vscode/setup-gpg.sh

# Quiet mode (minimal output, no testing)
/home/vscode/setup-gpg.sh --quiet

# Auto mode (non-interactive, for automation)
/home/vscode/setup-gpg.sh --quiet --auto
```

## 📁 Required Setup

Your GPG keys need to be available in the container via:

1. **Volume Mount** (Recommended):
   ```yaml
   volumes:
     - ${HOME}/.gnupg:/home/vscode/.gnupg:ro
   ```

2. **Manual Import**:
   ```bash
   gpg --import /path/to/your/private-key.asc
   ```

## 🔄 Disable Automation

To disable automatic GPG setup:

1. **Environment Level**: Set `AUTO_SETUP_GPG=false` in docker-compose.yml
2. **Shell Level**: Remove auto-setup code from `.bashrc`
3. **VS Code Level**: Remove `postStartCommand` from devcontainer.json

## ⚡ Quick Test

After container starts, check GPG status:
```bash
git config --global user.signingkey  # Should show your key ID
git config --global commit.gpgsign   # Should show 'true'
echo "test" | gpg --clearsign         # Should sign successfully
```

## 🔍 Troubleshooting

- **No GPG keys found**: Mount your `~/.gnupg` directory or import keys manually
- **Permission issues**: Container automatically fixes GPG directory permissions
- **Pinentry errors**: GPG_TTY is set automatically via environment variables
- **Silent failures**: Run setup script manually without `--quiet` flag for full output
