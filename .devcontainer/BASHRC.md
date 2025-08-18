# Custom Shell Setup

This directory contains custom shell configuration files that get copied into the development container to provide a better terminal experience.

## Files

-   `.bashrc` - Custom bash configuration with aliases and Starship integration
-   `starship.toml` - Starship prompt configuration

## Features

The custom shell setup includes:

### Prompt

-   **Starship prompt** - A beautiful, fast, and customizable prompt
-   **Fallback prompt** - Custom colorful prompt with git branch info if Starship is unavailable
-   **Development-focused** - Shows Go version, git status, docker context, and more

### Aliases

**Git shortcuts:**

-   `gs` - git status
-   `ga` - git add
-   `gaa` - git add .
-   `gc` - git commit
-   `gcm` - git commit -m
-   `gp` - git push
-   `gl` - git pull
-   `gd` - git diff
-   `gb` - git branch
-   `gco` - git checkout
-   `gcb` - git checkout -b
-   `glog` - git log --oneline --graph --decorate

**Go development:**

-   `gob` - go build
-   `gor` - go run
-   `got` - go test
-   `gom` - go mod
-   `gomt` - go mod tidy
-   `gov` - go vet
-   `gof` - go fmt

**Make shortcuts:**

-   `mb` - make build
-   `mr` - make run
-   `mt` - make test
-   `mc` - make clean
-   `mf` - make fmt
-   `ml` - make lint

**General utilities:**

-   `ll` - ls -alF
-   `la` - ls -A
-   `..` - cd ..
-   `...` - cd ../..
-   `cls` - clear
-   `mkd` - mkdir -pv

### Features

-   **Starship prompt** with development-focused modules
-   **History settings** for better command history
-   **Go environment** variables
-   **Startup messages** showing container and Starship status
-   **Tab completion** enabled

## Starship Configuration

The included `starship.toml` provides:

-   **Colorful segments** showing user, directory, git status
-   **Language indicators** for Go, Node.js, Python, Rust
-   **Docker context** display
-   **Time indicator**
-   **Development-optimized** layout and colors

You can customize the prompt by editing `starship.toml`. See the [Starship documentation](https://starship.rs/) for all available options.

## How it works

1. The `.bashrc` and `starship.toml` files are copied into the container during build
2. Starship is initialized if available, with a fallback to a custom prompt
3. The configuration becomes the default shell setup for the `vscode` user
4. Every new terminal session will use Starship with the custom configuration

## Customization

To modify the shell configuration:

1. **For aliases and bash settings:** Edit `.devcontainer/.bashrc`
2. **For prompt customization:** Edit `.devcontainer/starship.toml`
3. Rebuild the container: `docker-compose -f .devcontainer/docker-compose.yml build --no-cache`
4. Restart VS Code and reopen in container

## Starship Documentation

-   [Official Starship site](https://starship.rs/)
-   [Configuration guide](https://starship.rs/config/)
-   [Available modules](https://starship.rs/config/#modules)

## Alternative approach

If you prefer to mount the file as a volume (for real-time updates), add this to `docker-compose.yml`:

```yaml
volumes:
    - ./.bashrc:/home/vscode/.bashrc:ro
```

However, the copy approach is recommended for consistency across environments.
