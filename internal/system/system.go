package system

import (
	"regexp"
	"strings"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/damienbutt/arch-base/internal/styles"
	"github.com/damienbutt/arch-base/internal/types"
)

type SystemModel struct {
	Width         int
	Height        int
	config        *types.Config
	ShouldProceed bool
	focused       int
	inputs        []textinput.Model
	timezones     []string
	locales       []string
	keymaps       []string
	errors        []string
}

func NewSystemModel(config *types.Config) *SystemModel {
	inputs := make([]textinput.Model, 4)

	// Hostname input
	inputs[0] = textinput.New()
	inputs[0].Placeholder = "Enter hostname (e.g., arch-desktop)"
	inputs[0].SetValue(config.Hostname)
	inputs[0].Focus()
	inputs[0].CharLimit = 63
	inputs[0].Width = 40

	// Timezone input
	inputs[1] = textinput.New()
	inputs[1].Placeholder = "Enter timezone (e.g., America/New_York)"
	inputs[1].SetValue(config.Timezone)
	inputs[1].CharLimit = 50
	inputs[1].Width = 40

	// Locale input
	inputs[2] = textinput.New()
	inputs[2].Placeholder = "Enter locale (e.g., en_US.UTF-8)"
	inputs[2].SetValue(config.Locale)
	inputs[2].CharLimit = 30
	inputs[2].Width = 40

	// Keymap input
	inputs[3] = textinput.New()
	inputs[3].Placeholder = "Enter keymap (e.g., us)"
	inputs[3].SetValue(config.Keymap)
	inputs[3].CharLimit = 20
	inputs[3].Width = 40

	return &SystemModel{
		config:  config,
		inputs:  inputs,
		focused: 0,
		timezones: []string{
			"UTC",
			"America/New_York",
			"America/Los_Angeles",
			"America/Chicago",
			"Europe/London",
			"Europe/Berlin",
			"Europe/Paris",
			"Asia/Tokyo",
			"Asia/Shanghai",
			"Australia/Sydney",
		},
		locales: []string{
			"en_US.UTF-8",
			"en_GB.UTF-8",
			"de_DE.UTF-8",
			"fr_FR.UTF-8",
			"es_ES.UTF-8",
			"it_IT.UTF-8",
			"ja_JP.UTF-8",
			"zh_CN.UTF-8",
		},
		keymaps: []string{
			"us",
			"uk",
			"de",
			"fr",
			"es",
			"it",
			"jp",
			"dvorak",
		},
	}
}

func (m SystemModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m *SystemModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			if m.focused < len(m.inputs)-1 {
				// Move to next field
				m.focused++
				m.inputs[m.focused].Focus()
				m.inputs[m.focused-1].Blur()
				m.errors = nil // Clear errors when moving
			} else {
				// Validate all fields before proceeding
				if m.validateAllFields() {
					// Save values to config
					m.config.Hostname = m.inputs[0].Value()
					m.config.Timezone = m.inputs[1].Value()
					m.config.Locale = m.inputs[2].Value()
					m.config.Keymap = m.inputs[3].Value()
					m.ShouldProceed = true
				}
			}
		case "shift+tab", "up":
			if m.focused > 0 {
				m.focused--
				m.inputs[m.focused].Focus()
				m.inputs[m.focused+1].Blur()
				m.errors = nil
			}
		case "tab", "down":
			if m.focused < len(m.inputs)-1 {
				m.focused++
				m.inputs[m.focused].Focus()
				m.inputs[m.focused-1].Blur()
				m.errors = nil
			}
		}
	}

	// Update the focused input
	m.inputs[m.focused], cmd = m.inputs[m.focused].Update(msg)

	// Real-time validation for current field
	m.validateCurrentField()

	return m, cmd
}

func (m *SystemModel) validateCurrentField() {
	m.errors = nil

	switch m.focused {
	case 0: // Hostname
		if err := m.validateHostname(m.inputs[0].Value()); err != "" {
			m.errors = []string{err}
		}
	case 1: // Timezone
		if err := m.validateTimezone(m.inputs[1].Value()); err != "" {
			m.errors = []string{err}
		}
	case 2: // Locale
		if err := m.validateLocale(m.inputs[2].Value()); err != "" {
			m.errors = []string{err}
		}
	case 3: // Keymap
		if err := m.validateKeymap(m.inputs[3].Value()); err != "" {
			m.errors = []string{err}
		}
	}
}

func (m *SystemModel) validateAllFields() bool {
	var allErrors []string

	if err := m.validateHostname(m.inputs[0].Value()); err != "" {
		allErrors = append(allErrors, "Hostname: "+err)
	}
	if err := m.validateTimezone(m.inputs[1].Value()); err != "" {
		allErrors = append(allErrors, "Timezone: "+err)
	}
	if err := m.validateLocale(m.inputs[2].Value()); err != "" {
		allErrors = append(allErrors, "Locale: "+err)
	}
	if err := m.validateKeymap(m.inputs[3].Value()); err != "" {
		allErrors = append(allErrors, "Keymap: "+err)
	}

	m.errors = allErrors
	return len(allErrors) == 0
}

func (m *SystemModel) validateHostname(hostname string) string {
	if hostname == "" {
		return "hostname cannot be empty"
	}
	if len(hostname) > 63 {
		return "hostname too long (max 63 characters)"
	}

	// RFC 1123 hostname validation
	hostnameRegex := regexp.MustCompile(`^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$`)
	if !hostnameRegex.MatchString(hostname) {
		return "invalid hostname format (letters, numbers, hyphens only)"
	}

	return ""
}

func (m *SystemModel) validateTimezone(timezone string) string {
	if timezone == "" {
		return "timezone cannot be empty"
	}
	// Basic timezone format check
	if !strings.Contains(timezone, "/") && timezone != "UTC" {
		return "invalid timezone format (e.g., America/New_York or UTC)"
	}
	return ""
}

func (m *SystemModel) validateLocale(locale string) string {
	if locale == "" {
		return "locale cannot be empty"
	}
	// Basic locale format check
	localeRegex := regexp.MustCompile(`^[a-z]{2,3}_[A-Z]{2}(\.[A-Za-z0-9-]+)?$`)
	if !localeRegex.MatchString(locale) {
		return "invalid locale format (e.g., en_US.UTF-8)"
	}
	return ""
}

func (m *SystemModel) validateKeymap(keymap string) string {
	if keymap == "" {
		return "keymap cannot be empty"
	}
	// Basic keymap validation
	keymapRegex := regexp.MustCompile(`^[a-zA-Z0-9_-]+$`)
	if !keymapRegex.MatchString(keymap) {
		return "invalid keymap format (letters, numbers, underscore, hyphen only)"
	}
	return ""
}

func (m SystemModel) View() string {
	titleStyle := lipgloss.NewStyle().
		Foreground(styles.PrimaryColor).
		Bold(true).
		MarginBottom(1)

	labelStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#374151")).
		Bold(true).
		Width(15)

	helpStyle := lipgloss.NewStyle().
		Foreground(styles.MutedColor).
		Italic(true).
		MarginLeft(2)

	errorStyle := lipgloss.NewStyle().
		Foreground(styles.ErrorColor).
		MarginLeft(2)

	var formItems []string

	labels := []string{"Hostname:", "Timezone:", "Locale:", "Keymap:"}
	helps := []string{
		"System hostname (letters, numbers, hyphens only)",
		"System timezone (e.g., America/New_York or UTC)",
		"System locale for language and formatting",
		"Keyboard layout code",
	}

	for i, input := range m.inputs {
		var style lipgloss.Style
		if i == m.focused {
			style = styles.FocusedStyle
		} else {
			style = styles.BlurredStyle
		}

		formItem := lipgloss.JoinHorizontal(
			lipgloss.Left,
			labelStyle.Render(labels[i]),
			style.Render(input.View()),
		)

		formItems = append(formItems, formItem)
		formItems = append(formItems, helpStyle.Render(helps[i]))

		// Show validation status
		if i == m.focused && len(m.errors) > 0 {
			formItems = append(formItems, errorStyle.Render("❌ "+m.errors[0]))
		} else if i < m.focused || (i == m.focused && len(m.errors) == 0 && input.Value() != "") {
			formItems = append(formItems, lipgloss.NewStyle().
				Foreground(styles.SuccessColor).
				MarginLeft(2).
				Render("✅ Valid"))
		}
		formItems = append(formItems, "") // spacing
	}

	// Add suggestions for current field
	var suggestions string
	switch m.focused {
	case 1: // Timezone
		suggestions = "💡 Common: " + strings.Join(m.timezones[:3], ", ") + "..."
	case 2: // Locale
		suggestions = "💡 Common: " + strings.Join(m.locales[:3], ", ") + "..."
	case 3: // Keymap
		suggestions = "💡 Common: " + strings.Join(m.keymaps[:4], ", ") + "..."
	}

	if suggestions != "" {
		formItems = append(formItems, lipgloss.NewStyle().
			Foreground(styles.WarningColor).
			MarginTop(1).
			Render(suggestions))
	}

	// Show overall validation errors
	if len(m.errors) > 1 {
		formItems = append(formItems, "")
		formItems = append(formItems, errorStyle.Render("❌ Validation errors:"))
		for _, err := range m.errors {
			formItems = append(formItems, errorStyle.Render("  • "+err))
		}
	}

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		titleStyle.Render("🖥️  System Configuration"),
		"Configure basic system settings for your Arch Linux installation.",
		"",
		lipgloss.JoinVertical(lipgloss.Left, formItems...),
		"",
		lipgloss.NewStyle().
			Foreground(styles.SuccessColor).
			Render("Use Tab/↑↓ to navigate, Enter to continue"),
	)

	// More responsive container styling
	maxWidth := 80
	if m.Width > 0 && m.Width < maxWidth {
		maxWidth = m.Width - 4
	}

	containerStyle := lipgloss.NewStyle().
		Width(maxWidth).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.PrimaryColor).
		Padding(1, 2).
		Margin(1, 2)

	return containerStyle.Render(content)
}
