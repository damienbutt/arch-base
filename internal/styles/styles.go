package styles

import "github.com/charmbracelet/lipgloss"

// Color scheme
var (
	PrimaryColor    = lipgloss.Color("#7C3AED")
	SuccessColor    = lipgloss.Color("#10B981")
	WarningColor    = lipgloss.Color("#F59E0B")
	ErrorColor      = lipgloss.Color("#EF4444")
	MutedColor      = lipgloss.Color("#6B7280")
	BackgroundColor = lipgloss.Color("#1F2937")
)

// Common styles
var (
	TitleStyle = lipgloss.NewStyle().
			Foreground(PrimaryColor).
			Bold(true).
			Margin(0, 0, 1, 0)

	SubtitleStyle = lipgloss.NewStyle().
			Foreground(MutedColor).
			Margin(0, 0, 1, 0)

	FocusedStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(PrimaryColor).
			Padding(0, 1)

	BlurredStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(MutedColor).
			Padding(0, 1)

	ButtonStyle = lipgloss.NewStyle().
			Background(PrimaryColor).
			Foreground(lipgloss.Color("#FFFFFF")).
			Padding(0, 3).
			Margin(0, 1)

	ContainerStyle = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).
			BorderForeground(PrimaryColor).
			Padding(1, 2).
			Margin(1, 0)
)
