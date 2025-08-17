package main

import (
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type WelcomeModel struct {
	width         int
	height        int
	shouldProceed bool
	shouldQuit    bool
}

func NewWelcomeModel() *WelcomeModel {
	return &WelcomeModel{}
}

func (m WelcomeModel) Init() tea.Cmd {
	return nil
}

func (m *WelcomeModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter", " ":
			m.shouldProceed = true
		case "q", "ctrl+c":
			m.shouldQuit = true
		}
	}
	return m, nil
}

func (m WelcomeModel) View() string {
	titleStyle := lipgloss.NewStyle().
		Foreground(primaryColor).
		Bold(true).
		Align(lipgloss.Center).
		MarginTop(2).
		MarginBottom(1)

	subtitleStyle := lipgloss.NewStyle().
		Foreground(mutedColor).
		Align(lipgloss.Center).
		MarginBottom(2)

	featureStyle := lipgloss.NewStyle().
		Foreground(successColor).
		MarginLeft(2)

	instructionStyle := lipgloss.NewStyle().
		Foreground(warningColor).
		Bold(true).
		Align(lipgloss.Center).
		MarginTop(2)

	content := lipgloss.JoinVertical(
		lipgloss.Center,
		titleStyle.Render("🎉 Welcome to Arch-Base TUI Installer"),
		subtitleStyle.Render("A beautiful, interactive way to configure your Arch Linux installation"),
		"",
		lipgloss.NewStyle().Bold(true).Render("✨ Features:"),
		featureStyle.Render("• Beautiful terminal user interface with real-time validation"),
		featureStyle.Render("• Step-by-step configuration wizard with back navigation"),
		featureStyle.Render("• Compatible with existing Arch-Base installation scripts"),
		featureStyle.Render("• Professional-grade TUI components and visual feedback"),
		featureStyle.Render("• Multi-filesystem support with BTRFS customization"),
		featureStyle.Render("• LUKS encryption with keyfile automation"),
		"",
		lipgloss.NewStyle().Bold(true).Render("🛡️  What this wizard will configure:"),
		featureStyle.Render("• System settings (hostname, timezone, locale, keymap)"),
		featureStyle.Render("• User account with group selection and validation"),
		featureStyle.Render("• Disk partitioning with filesystem and encryption options"),
		featureStyle.Render("• Package selection with preset installation modes"),
		featureStyle.Render("• Installation behaviour and final configuration"),
		"",
		instructionStyle.Render("Press Enter to begin configuration • Press q to quit"),
	)

	// More responsive container styling
	maxWidth := 80
	if m.width > 0 && m.width < maxWidth {
		maxWidth = m.width - 4
	}

	containerStyle := lipgloss.NewStyle().
		Width(maxWidth).
		Align(lipgloss.Center, lipgloss.Top).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(primaryColor).
		Padding(1, 2).
		Margin(1, 2)

	return containerStyle.Render(content)
}
