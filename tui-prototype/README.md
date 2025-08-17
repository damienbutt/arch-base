# Arch-Base BubbleTea TUI Installer

A professional terminal user interface for the Arch-Base installation system, built with Go and Charm's BubbleTea framework.

## ✨ Features

- **Professional TUI**: Modern terminal interface with progress indicators, real-time validation, and responsive design
- **Complete Feature Parity**: All functionality from the original bash/Gum implementation
- **Real-time Validation**: Immediate feedback on input validity with visual indicators
- **Bi-directional Navigation**: Move forward and backward through configuration screens
- **Security-focused Validation**: Comprehensive input validation preventing system conflicts

## 🚀 Quick Start

```bash
# Build the application
go build -o arch-tui .

# Run the TUI installer
./arch-tui

# Generated config.local.sh can be used with existing scripts
cd .. && ./scripts/arch-base-install.sh all
```

## 📋 Configuration Screens

1. **Welcome**: Feature overview and introduction
2. **System**: Hostname, timezone, locale, keymap configuration
3. **User**: Username, password, and group selection
4. **Disk**: Target disk, encryption, and filesystem options
5. **Package**: Installation mode and package selection
6. **Summary**: Review configuration and generate config.local.sh

## ⌨️ Navigation

- **Tab/↓**: Next field
- **Shift+Tab/↑**: Previous field
- **Enter**: Continue to next screen
- **Esc**: Return to previous screen
- **Ctrl+C/Q**: Quit

## 🏗️ Architecture

- **Framework**: BubbleTea v0.25.0 with Lipgloss styling
- **Pattern**: Model-View-Update (MVU) architecture
- **Validation**: Real-time input validation with security checks
- **Compatibility**: Generates config.local.sh for existing bash scripts

## 📦 Dependencies

```bash
go mod tidy
```

- `github.com/charmbracelet/bubbletea` - TUI framework
- `github.com/charmbracelet/lipgloss` - Styling and layout
- `github.com/charmbracelet/bubbles` - Form components

See [DEMO.md](DEMO.md) for detailed feature documentation and comparison with the original Gum implementation.

## 🏗️ BubbleTea Implementation (Go)

The Go files in this directory show the structure for a real BubbleTea application:

- `main.go` - Core application structure and navigation
- `welcome.go` - Welcome screen component
- `system.go` - System configuration with interactive forms
- `screens.go` - Additional screen components (user, disk, packages, summary)

## ✨ Advantages of BubbleTea over Gum

### **Current Gum Approach:**

- ❌ Sequential prompts (no back navigation)
- ❌ Limited visual feedback
- ❌ No real-time validation
- ❌ Basic form layouts
- ❌ No mouse support

### **BubbleTea Approach:**

- ✅ **Multi-screen navigation** with back/forward
- ✅ **Real-time validation** with visual feedback
- ✅ **Professional forms** with tab navigation
- ✅ **Mouse support** for clicking and scrolling
- ✅ **Rich components** (tables, progress bars, charts)
- ✅ **Smooth animations** and transitions
- ✅ **Vim-like keybindings** for power users
- ✅ **Responsive layouts** that adapt to terminal size
- ✅ **Single binary** with no runtime dependencies

## 🎨 Visual Features in Full Implementation

### **Interactive Forms**

```
╭─ System Configuration ────────────────────────────────────╮
│                                                           │
│  Hostname:     [arch-desktop             ] ✅ Valid      │
│  Timezone:     [America/New_York         ] 🔍 Detected   │
│  Locale:       [en_US.UTF-8             ] ✅ Available   │
│  Keymap:       [us                      ] ✅ Valid      │
│                                                           │
│  💡 Use Tab to navigate, Enter to continue              │
╰───────────────────────────────────────────────────────────╯
```

### **Disk Selection with Visual Preview**

```
╭─ Disk Configuration ──────────────────────────────────────╮
│                                                           │
│  📊 Available Disks:                                     │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ /dev/nvme0n1  512GB NVMe [████████████████████] 95% │ │
│  │ /dev/sda1     1TB HDD   [██████████░░░░░░░░░░] 60%  │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                           │
│  ⚠️  WARNING: This will erase all data on selected disk  │
│                                                           │
╰───────────────────────────────────────────────────────────╯
```

### **Package Browser with Search**

```
╭─ Package Selection ───────────────────────────────────────╮
│                                                           │
│  Search: [kde                          ] 🔍              │
│                                                           │
│  📦 Results (24 packages):                               │
│  ┌─────────────────────────────────────────────────────┐ │
│  │ ☑ kde-plasma-desktop    Complete KDE desktop       │ │
│  │ ☑ konsole              Terminal emulator           │ │
│  │ ☐ kdevelop             Development environment     │ │
│  │ ☐ krita                Image editor                │ │
│  └─────────────────────────────────────────────────────┘ │
│                                                           │
╰───────────────────────────────────────────────────────────╯
```

## 🔧 Implementation Plan

### **Phase 1: Core TUI Framework**

1. Set up BubbleTea application structure
2. Implement navigation between screens
3. Create basic forms with validation
4. Design consistent visual theme

### **Phase 2: Screen Implementation**

1. Welcome screen with animated intro
2. System configuration with input validation
3. User setup with group selection
4. Disk configuration with visual disk browser
5. Package selection with search and filtering
6. Summary screen with configuration preview

### **Phase 3: Advanced Features**

1. Real-time validation feedback
2. Mouse support for all interactions
3. Keyboard shortcuts and vim-like navigation
4. Progress tracking during configuration
5. Help system with contextual hints
6. Configuration import/export

### **Phase 4: Integration**

1. Generate compatible `config.local.sh` files
2. Seamless handoff to existing bash installation scripts
3. Error handling and recovery
4. Installation progress monitoring

## 🚀 Benefits

1. **Professional Appearance**: Looks like a modern installer
2. **Better UX**: Navigate back/forward, see all options at once
3. **Real-time Feedback**: Instant validation and helpful hints
4. **Maintainable**: Structured Go code vs complex bash scripts
5. **Cross-platform**: Works anywhere Go runs
6. **Single Binary**: No runtime dependencies or package installation

## 📦 Dependencies

For the full Go implementation:

```bash
go mod init arch-base-tui
go get github.com/charmbracelet/bubbletea
go get github.com/charmbracelet/bubbles
go get github.com/charmbracelet/lipgloss
```

## 🎯 Next Steps

1. **Run the demo**: `./demo.sh` to see the concept
2. **Review the Go code**: See the structure in `main.go` and related files
3. **Decide on implementation**: Full BubbleTea rewrite vs enhanced Gum
4. **Plan integration**: How to maintain compatibility with existing scripts

The BubbleTea approach would create a truly professional installation experience that rivals commercial installers while maintaining the power and flexibility of your current system.
