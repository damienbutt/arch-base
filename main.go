package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/damienbutt/arch-base/internal/installer"
	"github.com/damienbutt/arch-base/internal/styles"
	"github.com/damienbutt/arch-base/internal/system"
	"github.com/damienbutt/arch-base/internal/types"
	"github.com/damienbutt/arch-base/internal/ui"
)

// Screen types
type Screen int

const (
	welcomeScreen Screen = iota
	systemScreen
	networkScreen
	mirrorScreen
	diskScreen
	userScreen
	bootloaderScreen
	profileScreen
	summaryScreen
	installScreen
)

// Message types
type installCompleteMsg struct {
	err error
}

type Model struct {
	Width      int
	Height     int
	screen     Screen
	quitting   bool
	config     *types.Config
	welcome    *ui.WelcomeModel
	system     *system.SystemModel
	network    *ui.NetworkModel
	mirror     *ui.MirrorModel
	disk       *ui.DiskModel
	user       *ui.UserModel
	bootloader *ui.BootloaderModel
	profile    *ui.ProfileModel
	summary    *ui.SummaryModel
	install    *ui.InstallModel
	installer  *installer.InstallerEngine
}

func initialModel() Model {
	config := &types.Config{
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
		Profile:           "desktop",
		DesktopEnv:        "gnome",
		AudioSystem:       "pipewire",
		Microcode:         "intel",
		BootMode:          "uefi",
		Bootloader:        "grub",
		NetworkConfig:     "dhcp",
		EnableNetworkMgr:  true,
		NTPEnabled:        true,
		ParallelDownloads: 5,
		UserGroups:        []string{"wheel", "audio", "video", "storage"},
	}

	return Model{
		screen:     welcomeScreen,
		config:     config,
		welcome:    ui.NewWelcomeModel(),
		system:     system.NewSystemModel(config),
		network:    ui.NewNetworkModel(config),
		mirror:     ui.NewMirrorModel(config),
		disk:       ui.NewDiskModel(config),
		user:       ui.NewUserModel(config),
		bootloader: ui.NewBootloaderModel(config),
		profile:    ui.NewProfileModel(config),
		summary:    ui.NewSummaryModel(config),
		install:    ui.NewInstallModel(config),
		installer:  installer.NewInstallerEngine(config),
	}
}

func (m Model) Init() tea.Cmd {
	return tea.EnterAltScreen
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.Width = msg.Width
		m.Height = msg.Height

		// Update all screen models with new dimensions
		m.welcome.Width = msg.Width
		m.welcome.Height = msg.Height
		m.system.Width = msg.Width
		m.system.Height = msg.Height
		m.network.Width = msg.Width
		m.network.Height = msg.Height
		m.mirror.Width = msg.Width
		m.mirror.Height = msg.Height
		m.disk.Width = msg.Width
		m.disk.Height = msg.Height
		m.user.Width = msg.Width
		m.user.Height = msg.Height
		m.bootloader.Width = msg.Width
		m.bootloader.Height = msg.Height
		m.profile.Width = msg.Width
		m.profile.Height = msg.Height
		m.summary.Width = msg.Width
		m.summary.Height = msg.Height
		m.install.Width = msg.Width
		m.install.Height = msg.Height

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
		if welcome, ok := newModel.(*ui.WelcomeModel); ok {
			m.welcome = welcome
		}
		cmd = newCmd

		if m.welcome.ShouldProceed {
			m.screen = systemScreen
			m.welcome.ShouldProceed = false
		}
		if m.welcome.ShouldQuit {
			m.quitting = true
			return m, tea.Quit
		}

	case systemScreen:
		newModel, newCmd := m.system.Update(msg)
		if system, ok := newModel.(*system.SystemModel); ok {
			m.system = system
		}
		cmd = newCmd

		if m.system.ShouldProceed {
			m.screen = networkScreen
			m.system.ShouldProceed = false
		}

	case networkScreen:
		newModel, newCmd := m.network.Update(msg)
		if network, ok := newModel.(*ui.NetworkModel); ok {
			m.network = network
		}
		cmd = newCmd

		if m.network.ShouldProceed {
			m.screen = mirrorScreen
			m.network.ShouldProceed = false
		}

	case mirrorScreen:
		newModel, newCmd := m.mirror.Update(msg)
		if mirror, ok := newModel.(*ui.MirrorModel); ok {
			m.mirror = mirror
		}
		cmd = newCmd

		if m.mirror.ShouldProceed {
			m.screen = diskScreen
			m.mirror.ShouldProceed = false
		}

	case diskScreen:
		newModel, newCmd := m.disk.Update(msg)
		if disk, ok := newModel.(*ui.DiskModel); ok {
			m.disk = disk
		}
		cmd = newCmd

		if m.disk.ShouldProceed {
			m.screen = userScreen
			m.disk.ShouldProceed = false
		}

	case userScreen:
		newModel, newCmd := m.user.Update(msg)
		if user, ok := newModel.(*ui.UserModel); ok {
			m.user = user
		}
		cmd = newCmd

		if m.user.ShouldProceed {
			m.screen = bootloaderScreen
			m.user.ShouldProceed = false
		}

	case bootloaderScreen:
		newModel, newCmd := m.bootloader.Update(msg)
		if bootloader, ok := newModel.(*ui.BootloaderModel); ok {
			m.bootloader = bootloader
		}
		cmd = newCmd

		if m.bootloader.ShouldProceed {
			m.screen = profileScreen
			m.bootloader.ShouldProceed = false
		}

	case profileScreen:
		newModel, newCmd := m.profile.Update(msg)
		if profile, ok := newModel.(*ui.ProfileModel); ok {
			m.profile = profile
		}
		cmd = newCmd

		if m.profile.ShouldProceed {
			m.screen = summaryScreen
			m.profile.ShouldProceed = false
		}

	case summaryScreen:
		newModel, newCmd := m.summary.Update(msg)
		if summary, ok := newModel.(*ui.SummaryModel); ok {
			m.summary = summary
		}
		cmd = newCmd

		if m.summary.ShouldGenerate {
			m.screen = installScreen
			m.summary.ShouldGenerate = false
		}

	case installScreen:
		switch msg := msg.(type) {
		case tea.KeyMsg:
			switch msg.String() {
			case "q":
				if m.install.Completed {
					return m, tea.Quit
				}
				return m, nil
			case "escape":
				if !m.install.Installing && !m.install.Completed {
					m.screen = summaryScreen
				}
				return m, nil
			case "enter":
				if !m.install.Installing && !m.install.Completed {
					// Start installation
					m.install.Installing = true
					m.install.Progress = append(m.install.Progress, "Starting installation...")
					return m, tea.Cmd(func() tea.Msg {
						err := m.installer.RunInstallation()
						return installCompleteMsg{err: err}
					})
				}
				return m, nil
			case "r":
				if m.install.Completed {
					// Reboot system
					cmd := exec.Command("reboot")
					cmd.Run()
					return m, tea.Quit
				}
				return m, nil
			}
		case installCompleteMsg:
			m.install.Installing = false
			m.install.Completed = true
			if msg.err != nil {
				m.install.Progress = append(m.install.Progress, "Installation failed: "+msg.err.Error())
			} else {
				m.install.Progress = append(m.install.Progress, "Installation completed successfully!")
			}
			return m, nil
		}
		updatedModel, cmd := m.install.Update(msg)
		if install, ok := updatedModel.(*ui.InstallModel); ok {
			m.install = install
		}
		return m, cmd
	}

	return m, cmd
}

func (m Model) View() string {
	if m.quitting {
		return lipgloss.NewStyle().
			Foreground(styles.SuccessColor).
			Bold(true).
			Render("Thanks for using Arch-Base TUI Installer! 👋")
	}

	if m.Width == 0 || m.Height == 0 {
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
	case networkScreen:
		content = m.network.View()
	case mirrorScreen:
		content = m.mirror.View()
	case diskScreen:
		content = m.disk.View()
	case userScreen:
		content = m.user.View()
	case bootloaderScreen:
		content = m.bootloader.View()
	case profileScreen:
		content = m.profile.View()
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
				Background(styles.PrimaryColor).
				Bold(true)
		} else if i < int(m.screen) {
			// Completed step
			style = style.
				Foreground(styles.SuccessColor).
				Bold(true)
		} else {
			// Future step
			style = style.
				Foreground(styles.MutedColor)
		}

		progressItems = append(progressItems, style.Render(step))
	}

	title := lipgloss.NewStyle().
		Foreground(styles.PrimaryColor).
		Bold(true).
		Render("🏗️  Arch-Base Installation Wizard")

	progress := lipgloss.JoinHorizontal(lipgloss.Left, progressItems...)

	headerStyle := lipgloss.NewStyle().
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.PrimaryColor).
		Padding(1).
		Margin(0, 1, 1, 1).
		Width(m.Width - 4)

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
		if m.install.Completed {
			hints = append(hints, "Reboot (r)")
			hints = append(hints, "Exit (q)")
		} else if !m.install.Installing {
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
		Foreground(styles.MutedColor).
		Render("Navigation: " + strings.Join(hints, " • "))

	return lipgloss.NewStyle().
		Border(lipgloss.NormalBorder(), true, false, false, false).
		BorderForeground(styles.MutedColor).
		Padding(0, 2).
		Width(m.Width).
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
DESKTOP_ENV="%s"
AUDIO_SYSTEM="%s"
ESSENTIAL_PACKAGES="%s"

# Installation Behavior
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
			m.config.Profile,
			m.config.DesktopEnv,
			m.config.AudioSystem,
			strings.Join(m.config.Packages, " "),
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
			fmt.Printf("  • Packages: %s profile with %s\n", m.config.Profile, m.config.DesktopEnv)
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
