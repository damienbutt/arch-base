package ui

import (
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/damienbutt/arch-base/internal/styles"
)

type WelcomeModel struct {
	Width         int
	Height        int
	ShouldProceed bool
	ShouldQuit    bool
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
			m.ShouldProceed = true
		case "q", "ctrl+c":
			m.ShouldQuit = true
		}
	}
	return m, nil
}

func (m WelcomeModel) View() string {
	titleStyle := lipgloss.NewStyle().
		Foreground(styles.PrimaryColor).
		Bold(true).
		Align(lipgloss.Center).
		MarginTop(2).
		MarginBottom(1)

	subtitleStyle := lipgloss.NewStyle().
		Foreground(styles.MutedColor).
		Align(lipgloss.Center).
		MarginBottom(2)

	featureStyle := lipgloss.NewStyle().
		Foreground(styles.SuccessColor).
		MarginLeft(2)

	instructionStyle := lipgloss.NewStyle().
		Foreground(styles.WarningColor).
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
	if m.Width > 0 && m.Width < maxWidth {
		maxWidth = m.Width - 4
	}

	containerStyle := lipgloss.NewStyle().
		Width(maxWidth).
		Align(lipgloss.Center, lipgloss.Top).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.PrimaryColor).
		Padding(1, 2).
		Margin(1, 2)

	return containerStyle.Render(content)
}
