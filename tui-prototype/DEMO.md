# Arch-Base BubbleTea TUI Demo

## Overview

This is a complete conversion of the Arch-Base installer from Gum-based prompts to a professional BubbleTea TUI application written in Go.

## Features Implemented

### ✅ Full Feature Parity

- **System Configuration**: Hostname, timezone, locale, keymap with real-time validation
- **User Configuration**: Username, password, confirmation, group selection with security validation
- **Disk Configuration**: Target disk, EFI size, LUKS encryption, filesystem selection (BTRFS/EXT4/XFS)
- **Package Configuration**: Installation mode selection and package options
- **Configuration Summary**: Complete review of all settings before generation

### ✅ Professional UI Components

- **Progress Header**: Visual progress indicator showing current step
- **Real-time Validation**: Immediate feedback on input validity with colored indicators
- **Keyboard Navigation**: Tab/Arrow key navigation, Enter to proceed, Esc to go back
- **Responsive Design**: Adapts to terminal size with proper borders and spacing
- **Color Scheme**: Consistent professional colors (purple primary, green success, red error)

### ✅ Advanced Validation

- **Hostname**: RFC-compliant validation, length limits, character restrictions
- **Username**: System user conflict detection, character validation, length limits
- **Password**: Minimum length requirements with confirmation matching
- **Disk Paths**: Path validation and format checking
- **Size Inputs**: Format validation for partition sizes

### ✅ Configuration Generation

- **config.local.sh Output**: Generates complete configuration file compatible with existing bash scripts
- **Summary Display**: Shows final configuration before generation
- **Installation Ready**: Direct integration with existing arch-base-install.sh scripts

## Usage

```bash
# Build the application
go build -o arch-tui .

# Run the TUI installer
./arch-tui

# Follow the guided interface through 5 screens:
# 1. Welcome & Feature Overview
# 2. System Configuration (hostname, timezone, locale, keymap)
# 3. User Configuration (username, password, groups)
# 4. Disk Configuration (target disk, encryption, filesystem)
# 5. Package Configuration (install mode, optional packages)
# 6. Summary & Generation (review and generate config.local.sh)
```

## Navigation

- **Tab/↓**: Move to next field
- **Shift+Tab/↑**: Move to previous field
- **Enter**: Proceed to next screen (when validation passes)
- **Esc**: Go back to previous screen
- **Ctrl+C/Q**: Quit application

## Technical Implementation

### Architecture

- **MVC Pattern**: Clear separation of models, views, and update logic
- **Screen-based Navigation**: Each configuration step is a dedicated screen
- **State Management**: Centralized configuration state shared across screens
- **Event Handling**: Proper BubbleTea Update/View pattern implementation

### Dependencies

- **BubbleTea v0.25.0**: Core TUI framework
- **Lipgloss**: Styling and layout
- **Bubbles**: Form components (textinput)

### Validation System

- **Real-time Feedback**: Input validation as user types
- **Visual Indicators**: ✅ for valid, ❌ for invalid inputs
- **Error Messages**: Detailed validation error descriptions
- **Security Focused**: Prevents system user conflicts, validates formats

## Integration with Existing Scripts

The TUI generates a `config.local.sh` file that is fully compatible with the existing bash installation scripts:

```bash
# After running the TUI
./scripts/arch-base-install.sh all
```

## Future Enhancements

- **Mouse Support**: Click navigation and selection
- **Keyboard Shortcuts**: Help system with F1
- **Configuration Import/Export**: Save/load configuration profiles
- **Advanced Package Selection**: Interactive package browser
- **Installation Progress**: Real-time installation monitoring
- **Themes**: Multiple color schemes and styling options

## Comparison with Original Gum Implementation

| Feature           | Gum Version   | BubbleTea Version |
| ----------------- | ------------- | ----------------- |
| User Experience   | Basic prompts | Professional TUI  |
| Validation        | Post-input    | Real-time         |
| Navigation        | Linear only   | Bi-directional    |
| Visual Feedback   | Minimal       | Rich indicators   |
| Error Handling    | Basic         | Comprehensive     |
| Responsiveness    | Fixed         | Terminal adaptive |
| Keyboard Support  | Limited       | Full navigation   |
| Professional Feel | Basic         | Enterprise-grade  |

The BubbleTea implementation provides a significantly enhanced user experience while maintaining complete compatibility with the existing installation infrastructure.
