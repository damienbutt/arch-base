# Starship Quick Reference

## Current Configuration Features

The current `starship.toml` includes these modules:

-   **OS Symbol** - Shows the operating system
-   **Username** - Current user (always shown)
-   **Directory** - Current path with smart truncation
-   **Git Branch** - Current git branch with symbol
-   **Git Status** - Shows git working directory status
-   **Language Versions** - Go, Node.js, Python, Rust versions when detected
-   **Docker Context** - Current docker context if available
-   **Time** - Current time (hour:minute)

## Quick Customizations

### Change Colors

Edit the `bg:` and `fg:` values in each module. Example:

```toml
[directory]
style = "bg:#YOUR_COLOR"
```

### Add/Remove Modules

Add to the `format` string or comment out modules you don't want:

```toml
format = """
[](#9A348E)\
$os\
$username\
# $directory\  <- This would hide the directory
"""
```

### Customize Git Display

```toml
[git_branch]
symbol = "🌱 "  # Change the git symbol
format = '[ $symbol $branch ]($style)'
```

### Add More Languages

Available language modules:

-   `$c`
-   `$cpp`
-   `$java`
-   `$kotlin`
-   `$lua`
-   `$php`
-   `$ruby`
-   `$swift`
-   And many more...

## Useful Starship Commands

-   `starship config` - Edit configuration
-   `starship print-config` - Show current config
-   `starship explain` - Explain current prompt
-   `starship preset` - Use preset configurations

## Presets

You can use Starship presets for quick setup:

```bash
starship preset nerd-font-symbols -o ~/.config/starship.toml
```

Available presets:

-   `bracketed-segments`
-   `gruvbox-rainbow`
-   `nerd-font-symbols`
-   `no-nerd-font`
-   `plain-text-symbols`
-   `pure-preset`
-   `tokyo-night`

## Testing Changes

After editing `starship.toml`, start a new terminal session or run:

```bash
exec bash
```

## More Information

-   [Starship Configuration](https://starship.rs/config/)
-   [Advanced Configuration](https://starship.rs/advanced-config/)
-   [Custom Commands](https://starship.rs/config/#custom-commands)
