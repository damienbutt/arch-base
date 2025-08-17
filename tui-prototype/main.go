package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// Screen types
type Screen int

const (
	welcomeScreen Screen = iota
	systemScreen
	userScreen
	diskScreen
	packageScreen
	summaryScreen
	installScreen
)

type Model struct {
	width     int
	height    int
	screen    Screen
	quitting  bool
	config    *Config
	welcome   *WelcomeModel
	system    *SystemModel
	user      *UserModel
	disk      *DiskModel
	packages  *PackageModel
	summary   *SummaryModel
	install   *InstallModel
	installer *InstallerEngine
}

// Configuration structure that matches your bash scripts
type Config struct {
	// System configuration
	Hostname string
	Timezone string
	Locale   string
	Keymap   string

	// User configuration
	Username     string
	UserGroups   []string
	UserPassword string

	// Disk configuration
	TargetDisk    string
	EFISize       string
	CryptrootName string
	FSType        string
	BtrfsLayout   string
	CompressType  string
	SwapEnabled   bool
	SwapSize      string
	LuksType      string

	// Package configuration
	InstallMode       string
	Packages          []string
	OptionalPackages  bool
	SecurityPackages  bool
	EssentialPackages string

	// Installation behaviour
	AutoReboot  bool
	SkipNonFree bool
	DryRun      bool
}

// Color scheme
var (
	primaryColor    = lipgloss.Color("#7C3AED")
	successColor    = lipgloss.Color("#10B981")
	warningColor    = lipgloss.Color("#F59E0B")
	errorColor      = lipgloss.Color("#EF4444")
	mutedColor      = lipgloss.Color("#6B7280")
	backgroundColor = lipgloss.Color("#1F2937")
)

// Common styles
var (
	titleStyle = lipgloss.NewStyle().
			Foreground(primaryColor).
			Bold(true).
			Margin(0, 0, 1, 0)

	subtitleStyle = lipgloss.NewStyle().
			Foreground(mutedColor).
			Margin(0, 0, 1, 0)

	focusedStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(primaryColor).
			Padding(0, 1)

	blurredStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(mutedColor).
			Padding(0, 1)

	buttonStyle = lipgloss.NewStyle().
			Background(primaryColor).
			Foreground(lipgloss.Color("#FFFFFF")).
			Padding(0, 3).
			Margin(0, 1)

	containerStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(primaryColor).
			Padding(1, 2).
			Margin(1, 0)
)

func initialModel() Model {
	config := &Config{
		// Set reasonable defaults matching your current script
		Hostname:          "arch-base",
		Timezone:          "UTC",
		Locale:            "en_US.UTF-8",
		Keymap:            "us",
		EFISize:           "512M",
		CryptrootName:     "cryptroot",
		FSType:            "btrfs",
		BtrfsLayout:       "default",
		CompressType:      "zstd",
		SwapEnabled:       true,
		SwapSize:          "2048",
		LuksType:          "luks2",
		InstallMode:       "standard",
		OptionalPackages:  true,
		SecurityPackages:  true,
		EssentialPackages: "base base-devel linux linux-firmware",
		UserGroups:        []string{"wheel", "audio", "video", "storage"},
	}

	return Model{
		screen:   welcomeScreen,
		config:   config,
		welcome:  NewWelcomeModel(),
		system:   NewSystemModel(config),
		user:     NewUserModel(config),
		disk:     NewDiskModel(config),
		packages: NewPackageModel(config),
		summary:  NewSummaryModel(config),
		install:  NewInstallModel(config),
	}
}

func (m Model) Init() tea.Cmd {
	return tea.EnterAltScreen
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height

		// Update all screen models with new dimensions
		m.welcome.width = msg.Width
		m.welcome.height = msg.Height
		m.system.width = msg.Width
		m.system.height = msg.Height
		m.user.width = msg.Width
		m.user.height = msg.Height
		m.disk.width = msg.Width
		m.disk.height = msg.Height
		m.packages.width = msg.Width
		m.packages.height = msg.Height
		m.summary.width = msg.Width
		m.summary.height = msg.Height

		return m, nil

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c":
			m.quitting = true
			return m, tea.Quit
		case "q":
			if m.screen == welcomeScreen {
				m.quitting = true
				return m, tea.Quit
			}
		case "esc":
			if m.screen > welcomeScreen {
				m.screen--
				return m, nil
			}
		}
	}

	// Handle screen-specific updates - IMPORTANT: Pass all messages to current screen
	var cmd tea.Cmd
	switch m.screen {
	case welcomeScreen:
		newModel, newCmd := m.welcome.Update(msg)
		if welcome, ok := newModel.(*WelcomeModel); ok {
			m.welcome = welcome
		}
		cmd = newCmd

		if m.welcome.shouldProceed {
			m.screen = systemScreen
			m.welcome.shouldProceed = false
		}
		if m.welcome.shouldQuit {
			m.quitting = true
			return m, tea.Quit
		}

	case systemScreen:
		newModel, newCmd := m.system.Update(msg)
		if system, ok := newModel.(*SystemModel); ok {
			m.system = system
		}
		cmd = newCmd

		if m.system.shouldProceed {
			m.screen = userScreen
			m.system.shouldProceed = false
		}

	case userScreen:
		newModel, newCmd := m.user.Update(msg)
		if user, ok := newModel.(*UserModel); ok {
			m.user = user
		}
		cmd = newCmd

		if m.user.shouldProceed {
			m.screen = diskScreen
			m.user.shouldProceed = false
		}

	case diskScreen:
		newModel, newCmd := m.disk.Update(msg)
		if disk, ok := newModel.(*DiskModel); ok {
			m.disk = disk
		}
		cmd = newCmd

		if m.disk.shouldProceed {
			m.screen = packageScreen
			m.disk.shouldProceed = false
		}

	case packageScreen:
		newModel, newCmd := m.packages.Update(msg)
		if pkg, ok := newModel.(*PackageModel); ok {
			m.packages = pkg
		}
		cmd = newCmd

		if m.packages.shouldProceed {
			m.screen = summaryScreen
			m.packages.shouldProceed = false
		}

	case summaryScreen:
		newModel, newCmd := m.summary.Update(msg)
		if summary, ok := newModel.(*SummaryModel); ok {
			m.summary = summary
		}
		cmd = newCmd

		if m.summary.shouldGenerate {
			m.screen = installScreen
			m.summary.shouldGenerate = false
		}

	case installScreen:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "q":
				if m.install.completed {
					return m, tea.Quit
				}
				return m, nil
			case "escape":
				if !m.install.installing && !m.install.completed {
					m.screen = summaryScreen
				}
				return m, nil
			case "enter":
				if !m.install.installing && !m.install.completed {
					// Start installation
					m.install.installing = true
					m.install.progress = append(m.install.progress, "Starting installation...")
					return m, tea.Cmd(func() tea.Msg {
						err := m.installer.RunInstallation()
						return installCompleteMsg{err: err}
					})
				}
				return m, nil
			case "r":
				if m.install.completed {
					// Reboot system
					cmd := exec.Command("reboot")
					cmd.Run()
					return m, tea.Quit
				}
				return m, nil
			}
		case installCompleteMsg:
			m.install.installing = false
			m.install.completed = true
			if msg.err != nil {
				m.install.progress = append(m.install.progress, "Installation failed: "+msg.err.Error())
			} else {
				m.install.progress = append(m.install.progress, "Installation completed successfully!")
			}
			return m, nil
		}
		updatedModel, cmd := m.install.Update(msg)
		if install, ok := updatedModel.(*InstallModel); ok {
			m.install = install
		}
		return m, cmd

	}

	return m, cmd
}

func (m Model) View() string {
	if m.quitting {
		return lipgloss.NewStyle().
			Foreground(successColor).
			Bold(true).
			Render("Thanks for using Arch-Base TUI Installer! 👋")
	}

	if m.width == 0 || m.height == 0 {
		return "Initializing..."
	}

	// Header with progress
	header := m.renderHeader()

	// Main content based on current screen
	var content string
	switch m.screen {
	case welcomeScreen:
		content = m.welcome.View()
	case systemScreen:
		content = m.system.View()
	case userScreen:
		content = m.user.View()
	case diskScreen:
		content = m.disk.View()
	case packageScreen:
		content = m.packages.View()
	case summaryScreen:
		content = m.summary.View()
	case installScreen:
		content = m.install.View()
	}

	// Footer with navigation hints
	footer := m.renderFooter()

	// Simple vertical layout - let content manage its own sizing
	return lipgloss.JoinVertical(
		lipgloss.Left,
		header,
		content,
		footer,
	)
}

func (m Model) renderHeader() string {
	// Progress indicators
	steps := []string{"Welcome", "System", "User", "Disk", "Packages", "Summary", "Install"}
	var progressItems []string

	for i, step := range steps {
		style := lipgloss.NewStyle().
			Padding(0, 1).
			Margin(0, 1)

		if i == int(m.screen) {
			// Current step
			style = style.
				Foreground(lipgloss.Color("#FFFFFF")).
				Background(primaryColor).
				Bold(true)
		} else if i < int(m.screen) {
			// Completed step
			style = style.
				Foreground(successColor).
				Bold(true)
		} else {
			// Future step
			style = style.
				Foreground(mutedColor)
		}

		progressItems = append(progressItems, style.Render(step))
	}

	title := lipgloss.NewStyle().
		Foreground(primaryColor).
		Bold(true).
		Render("🏗️  Arch-Base Installation Wizard")

	progress := lipgloss.JoinHorizontal(lipgloss.Left, progressItems...)

	headerStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(primaryColor).
		Padding(1).
		Margin(0, 1, 1, 1).
		Width(m.width - 4)

	return headerStyle.Render(
		lipgloss.JoinVertical(
			lipgloss.Center,
			title,
			"",
			progress,
		),
	)
}

func (m Model) renderFooter() string {
	var hints []string

	if m.screen > welcomeScreen {
		hints = append(hints, "← Previous (Esc)")
	}

	switch m.screen {
	case welcomeScreen:
		hints = append(hints, "Continue (Enter)")
		hints = append(hints, "Quit (q)")
	case installScreen:
		if m.install.completed {
			hints = append(hints, "Reboot (r)")
			hints = append(hints, "Exit (q)")
		} else if !m.install.installing {
			hints = append(hints, "Start Installation (Enter)")
			hints = append(hints, "← Back (Esc)")
		} else {
			hints = append(hints, "Installation in progress...")
		}
	case summaryScreen:
		hints = append(hints, "Start Installation (Enter)")
	default:
		hints = append(hints, "Continue (Enter/Tab)")
	}

	hints = append(hints, "Exit (Ctrl+C)")

	footerText := lipgloss.NewStyle().
		Foreground(mutedColor).
		Render("Navigation: " + strings.Join(hints, " • "))

	return lipgloss.NewStyle().
		Border(lipgloss.NormalBorder(), true, false, false, false).
		BorderForeground(mutedColor).
		Padding(0, 2).
		Width(m.width).
		Render(footerText)
}

func (m Model) generateConfig() tea.Cmd {
	return func() tea.Msg {
		// Generate the config.local.sh file compatible with your existing scripts
		configContent := fmt.Sprintf(`#!/bin/bash
# Generated by Arch-Base TUI Configuration Wizard
# Generated on: %s

# System Configuration
HOSTNAME="%s"
TIMEZONE="%s"
LOCALE="%s"
KEYMAP="%s"

# User Configuration
USERNAME="%s"
USER_GROUPS="%s"

# Disk Configuration
TARGET_DISK="%s"
EFI_SIZE="%s"
CRYPTROOT_NAME="%s"
LUKS_TYPE="%s"
FS_TYPE="%s"
BTRFS_SUBVOLUME_LAYOUT="%s"
COMPRESS_TYPE="%s"
SWAPFILE_ENABLED="%t"
SWAPFILE_SIZE_MB="%s"

# Package Configuration
INSTALL_MODE="%s"
INSTALL_OPTIONAL_PACKAGES="%t"
INSTALL_SECURITY_PACKAGES="%t"
ESSENTIAL_PACKAGES="%s"

# Installation Behaviour
AUTO_REBOOT="%t"
SKIP_NON_FREE="%t"
DRY_RUN="%t"
`,
			"$(date)",
			m.config.Hostname,
			m.config.Timezone,
			m.config.Locale,
			m.config.Keymap,
			m.config.Username,
			strings.Join(m.config.UserGroups, ","),
			m.config.TargetDisk,
			m.config.EFISize,
			m.config.CryptrootName,
			m.config.LuksType,
			m.config.FSType,
			m.config.BtrfsLayout,
			m.config.CompressType,
			m.config.SwapEnabled,
			m.config.SwapSize,
			m.config.InstallMode,
			m.config.OptionalPackages,
			m.config.SecurityPackages,
			m.config.EssentialPackages,
			m.config.AutoReboot,
			m.config.SkipNonFree,
			m.config.DryRun,
		)

		// Write to config.local.sh
		configPath := "../scripts/config.local.sh"
		err := os.WriteFile(configPath, []byte(configContent), 0644)
		if err != nil {
			fmt.Printf("❌ Error writing config: %v\n", err)
		} else {
			fmt.Println("✅ Configuration saved to scripts/config.local.sh")
			fmt.Println("🚀 Run './scripts/arch-base-install.sh all' to start installation")
			fmt.Println("")
			fmt.Println("Configuration summary:")
			fmt.Printf("  • Hostname: %s\n", m.config.Hostname)
			fmt.Printf("  • User: %s\n", m.config.Username)
			fmt.Printf("  • Disk: %s (%s)\n", m.config.TargetDisk, m.config.FSType)
			fmt.Printf("  • Packages: %s mode\n", m.config.InstallMode)
		}

		return nil
	}
}

func main() {
	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Printf("Error running program: %v", err)
		os.Exit(1)
	}
}
