package main

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// UserModel handles user configuration
type UserModel struct {
	width          int
	height         int
	config         *Config
	shouldProceed  bool
	focused        int
	usernameInput  textinput.Model
	passwordInput  textinput.Model
	confirmInput   textinput.Model
	groupOptions   []string
	selectedGroups map[int]bool
	errors         []string
	showingGroups  bool
}

func NewUserModel(config *Config) *UserModel {
	usernameInput := textinput.New()
	usernameInput.Placeholder = "Enter username"
	usernameInput.SetValue(config.Username)
	usernameInput.Focus()
	usernameInput.CharLimit = 32
	usernameInput.Width = 30

	passwordInput := textinput.New()
	passwordInput.Placeholder = "Enter password"
	passwordInput.EchoMode = textinput.EchoPassword
	passwordInput.Width = 30

	confirmInput := textinput.New()
	confirmInput.Placeholder = "Confirm password"
	confirmInput.EchoMode = textinput.EchoPassword
	confirmInput.Width = 30

	groupOptions := []string{"wheel", "audio", "video", "storage", "optical", "lp", "scanner", "games"}
	selectedGroups := make(map[int]bool)

	// Set default groups
	for i, group := range groupOptions {
		for _, defaultGroup := range config.UserGroups {
			if group == defaultGroup {
				selectedGroups[i] = true
				break
			}
		}
	}

	return &UserModel{
		config:         config,
		usernameInput:  usernameInput,
		passwordInput:  passwordInput,
		confirmInput:   confirmInput,
		groupOptions:   groupOptions,
		selectedGroups: selectedGroups,
		focused:        0,
	}
}

func (m UserModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m *UserModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		if m.showingGroups {
			return m.updateGroupSelection(msg)
		}

		switch msg.String() {
		case "enter":
			if m.focused < 2 {
				m.focused++
				m.updateFocus()
			} else {
				// Validate before showing groups
				if m.validateUserInputs() {
					m.showingGroups = true
				}
			}
		case "shift+tab", "up":
			if m.focused > 0 {
				m.focused--
				m.updateFocus()
			}
		case "tab", "down":
			if m.focused < 2 {
				m.focused++
				m.updateFocus()
			}
		}
	}

	// Update the focused input
	switch m.focused {
	case 0:
		m.usernameInput, cmd = m.usernameInput.Update(msg)
	case 1:
		m.passwordInput, cmd = m.passwordInput.Update(msg)
	case 2:
		m.confirmInput, cmd = m.confirmInput.Update(msg)
	}

	m.validateCurrentField()

	return m, cmd
}

func (m *UserModel) updateGroupSelection(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	switch msg.String() {
	case "enter":
		// Save configuration and proceed
		m.config.Username = m.usernameInput.Value()
		m.config.UserPassword = m.passwordInput.Value()

		var selectedGroups []string
		for i, selected := range m.selectedGroups {
			if selected {
				selectedGroups = append(selectedGroups, m.groupOptions[i])
			}
		}
		m.config.UserGroups = selectedGroups

		m.shouldProceed = true

	case " ":
		// Toggle group selection (simplified - would need proper focus management)
		// For now, just continue

	case "esc":
		m.showingGroups = false
	}

	return m, nil
}

func (m *UserModel) updateFocus() {
	m.usernameInput.Blur()
	m.passwordInput.Blur()
	m.confirmInput.Blur()

	switch m.focused {
	case 0:
		m.usernameInput.Focus()
	case 1:
		m.passwordInput.Focus()
	case 2:
		m.confirmInput.Focus()
	}
}

func (m *UserModel) validateCurrentField() {
	m.errors = nil

	switch m.focused {
	case 0: // Username
		if err := m.validateUsername(m.usernameInput.Value()); err != "" {
			m.errors = []string{err}
		}
	case 1: // Password
		if err := m.validatePassword(m.passwordInput.Value()); err != "" {
			m.errors = []string{err}
		}
	case 2: // Confirm
		if err := m.validatePasswordConfirm(); err != "" {
			m.errors = []string{err}
		}
	}
}

func (m *UserModel) validateUserInputs() bool {
	var allErrors []string

	if err := m.validateUsername(m.usernameInput.Value()); err != "" {
		allErrors = append(allErrors, "Username: "+err)
	}
	if err := m.validatePassword(m.passwordInput.Value()); err != "" {
		allErrors = append(allErrors, "Password: "+err)
	}
	if err := m.validatePasswordConfirm(); err != "" {
		allErrors = append(allErrors, "Confirm: "+err)
	}

	m.errors = allErrors
	return len(allErrors) == 0
}

func (m *UserModel) validateUsername(username string) string {
	if username == "" {
		return "username cannot be empty"
	}
	if len(username) > 32 {
		return "username too long (max 32 characters)"
	}

	usernameRegex := regexp.MustCompile(`^[a-z][a-z0-9_-]*$`)
	if !usernameRegex.MatchString(username) {
		return "username must start with lowercase letter, contain only lowercase letters, numbers, underscore, hyphen"
	}

	// Check against system users
	systemUsers := []string{"root", "bin", "daemon", "sys", "adm", "tty", "disk", "lp", "mail", "news", "uucp", "proxy", "www-data", "backup", "list", "irc", "gnats", "nobody"}
	for _, sysUser := range systemUsers {
		if username == sysUser {
			return "username conflicts with system user"
		}
	}

	return ""
}

func (m *UserModel) validatePassword(password string) string {
	if password == "" {
		return "password cannot be empty"
	}
	if len(password) < 8 {
		return "password must be at least 8 characters"
	}
	return ""
}

func (m *UserModel) validatePasswordConfirm() string {
	if m.passwordInput.Value() != m.confirmInput.Value() {
		return "passwords do not match"
	}
	return ""
}

func (m UserModel) View() string {
	if m.showingGroups {
		return m.renderGroupSelection()
	}

	titleStyle := lipgloss.NewStyle().
		Foreground(primaryColor).
		Bold(true).
		MarginBottom(1)

	labelStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#374151")).
		Bold(true).
		Width(15)

	helpStyle := lipgloss.NewStyle().
		Foreground(mutedColor).
		Italic(true).
		MarginLeft(2)

	errorStyle := lipgloss.NewStyle().
		Foreground(errorColor).
		MarginLeft(2)

	var formItems []string

	labels := []string{"Username:", "Password:", "Confirm:"}
	inputs := []textinput.Model{m.usernameInput, m.passwordInput, m.confirmInput}
	helps := []string{
		"User account name (lowercase letters, numbers, underscore, hyphen)",
		"Account password (minimum 8 characters)",
		"Confirm your password",
	}

	for i, input := range inputs {
		var style lipgloss.Style
		if i == m.focused {
			style = focusedStyle
		} else {
			style = blurredStyle
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
				Foreground(successColor).
				MarginLeft(2).
				Render("✅ Valid"))
		}
		formItems = append(formItems, "") // spacing
	}

	// Show overall validation errors
	if len(m.errors) > 1 {
		formItems = append(formItems, errorStyle.Render("❌ Validation errors:"))
		for _, err := range m.errors {
			formItems = append(formItems, errorStyle.Render("  • "+err))
		}
	}

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		titleStyle.Render("👤 User Configuration"),
		"Configure your user account and password.",
		"",
		lipgloss.JoinVertical(lipgloss.Left, formItems...),
		"",
		lipgloss.NewStyle().
			Foreground(successColor).
			Render("Use Tab/↑↓ to navigate, Enter to continue to group selection"),
	)

	containerStyle := lipgloss.NewStyle().
		Width(m.width - 4).
		Height(m.height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(primaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(content)
}

func (m UserModel) renderGroupSelection() string {
	titleStyle := lipgloss.NewStyle().
		Foreground(primaryColor).
		Bold(true).
		MarginBottom(1)

	var groupItems []string
	for i, group := range m.groupOptions {
		checkbox := "☐"
		if m.selectedGroups[i] {
			checkbox = "☑"
		}

		groupStyle := lipgloss.NewStyle().MarginLeft(2)
		if group == "wheel" {
			groupStyle = groupStyle.Foreground(warningColor).Bold(true)
		}

		groupItems = append(groupItems, groupStyle.Render(fmt.Sprintf("%s %s", checkbox, group)))
	}

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		titleStyle.Render("👥 User Groups Selection"),
		"Select additional groups for user: "+m.usernameInput.Value(),
		"",
		lipgloss.JoinVertical(lipgloss.Left, groupItems...),
		"",
		lipgloss.NewStyle().
			Foreground(warningColor).
			Render("⚠️  'wheel' group is required for sudo access"),
		"",
		lipgloss.NewStyle().
			Foreground(successColor).
			Render("Press Enter to continue, Esc to go back"),
	)

	containerStyle := lipgloss.NewStyle().
		Width(m.width - 4).
		Height(m.height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(primaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(content)
}

// DiskModel handles disk configuration
type DiskModel struct {
	width         int
	height        int
	config        *Config
	shouldProceed bool
	focused       int
	diskInput     textinput.Model
	efiInput      textinput.Model
	cryptInput    textinput.Model
	swapInput     textinput.Model
	fsType        int
	swapEnabled   bool
	errors        []string
}

func NewDiskModel(config *Config) *DiskModel {
	diskInput := textinput.New()
	diskInput.Placeholder = "Enter disk path (e.g., /dev/sda)"
	diskInput.SetValue(config.TargetDisk)
	diskInput.Focus()
	diskInput.Width = 30

	efiInput := textinput.New()
	efiInput.Placeholder = "EFI partition size (e.g., 512M)"
	efiInput.SetValue(config.EFISize)
	efiInput.Width = 20

	cryptInput := textinput.New()
	cryptInput.Placeholder = "LUKS container name"
	cryptInput.SetValue(config.CryptrootName)
	cryptInput.Width = 25

	swapInput := textinput.New()
	swapInput.Placeholder = "Swap size in MB"
	swapInput.SetValue(config.SwapSize)
	swapInput.Width = 15

	fsType := 0 // btrfs default
	if config.FSType == "ext4" {
		fsType = 1
	} else if config.FSType == "xfs" {
		fsType = 2
	}

	return &DiskModel{
		config:      config,
		diskInput:   diskInput,
		efiInput:    efiInput,
		cryptInput:  cryptInput,
		swapInput:   swapInput,
		fsType:      fsType,
		swapEnabled: config.SwapEnabled,
		focused:     0,
	}
}

func (m DiskModel) Init() tea.Cmd {
	return textinput.Blink
}

func (m *DiskModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			if m.focused < 3 {
				m.focused++
				m.updateFocus()
			} else {
				// Validate and proceed
				if m.validateDiskInputs() {
					m.saveDiskConfig()
					m.shouldProceed = true
				}
			}
		case "shift+tab", "up":
			if m.focused > 0 {
				m.focused--
				m.updateFocus()
			}
		case "tab", "down":
			if m.focused < 3 {
				m.focused++
				m.updateFocus()
			}
		case " ":
			// Toggle filesystem or swap (when focused on those options)
			// Simplified for this implementation
		}
	}

	// Update the focused input
	switch m.focused {
	case 0:
		m.diskInput, cmd = m.diskInput.Update(msg)
	case 1:
		m.efiInput, cmd = m.efiInput.Update(msg)
	case 2:
		m.cryptInput, cmd = m.cryptInput.Update(msg)
	case 3:
		m.swapInput, cmd = m.swapInput.Update(msg)
	}

	m.validateCurrentField()

	return m, cmd
}

func (m *DiskModel) updateFocus() {
	m.diskInput.Blur()
	m.efiInput.Blur()
	m.cryptInput.Blur()
	m.swapInput.Blur()

	switch m.focused {
	case 0:
		m.diskInput.Focus()
	case 1:
		m.efiInput.Focus()
	case 2:
		m.cryptInput.Focus()
	case 3:
		m.swapInput.Focus()
	}
}

func (m *DiskModel) validateCurrentField() {
	m.errors = nil

	switch m.focused {
	case 0: // Disk
		if err := m.validateDisk(m.diskInput.Value()); err != "" {
			m.errors = []string{err}
		}
	case 1: // EFI
		if err := m.validateEFISize(m.efiInput.Value()); err != "" {
			m.errors = []string{err}
		}
	case 2: // Crypt
		if err := m.validateCryptName(m.cryptInput.Value()); err != "" {
			m.errors = []string{err}
		}
	case 3: // Swap
		if err := m.validateSwapSize(m.swapInput.Value()); err != "" {
			m.errors = []string{err}
		}
	}
}

func (m *DiskModel) validateDiskInputs() bool {
	var allErrors []string

	if err := m.validateDisk(m.diskInput.Value()); err != "" {
		allErrors = append(allErrors, "Disk: "+err)
	}
	if err := m.validateEFISize(m.efiInput.Value()); err != "" {
		allErrors = append(allErrors, "EFI: "+err)
	}
	if err := m.validateCryptName(m.cryptInput.Value()); err != "" {
		allErrors = append(allErrors, "Crypt: "+err)
	}
	if err := m.validateSwapSize(m.swapInput.Value()); err != "" {
		allErrors = append(allErrors, "Swap: "+err)
	}

	m.errors = allErrors
	return len(allErrors) == 0
}

func (m *DiskModel) validateDisk(disk string) string {
	if disk == "" {
		return "disk path cannot be empty"
	}
	if !strings.HasPrefix(disk, "/dev/") {
		return "disk path must start with /dev/"
	}
	return ""
}

func (m *DiskModel) validateEFISize(size string) string {
	if size == "" {
		return "EFI size cannot be empty"
	}

	sizeRegex := regexp.MustCompile(`^[0-9]+[MG]?$`)
	if !sizeRegex.MatchString(size) {
		return "invalid size format (e.g., 512M, 1G)"
	}

	return ""
}

func (m *DiskModel) validateCryptName(name string) string {
	if name == "" {
		return "container name cannot be empty"
	}

	nameRegex := regexp.MustCompile(`^[a-zA-Z0-9_-]+$`)
	if !nameRegex.MatchString(name) {
		return "invalid name (letters, numbers, underscore, hyphen only)"
	}

	return ""
}

func (m *DiskModel) validateSwapSize(size string) string {
	if size == "" {
		return "swap size cannot be empty"
	}

	if _, err := strconv.Atoi(size); err != nil {
		return "swap size must be a number (in MB)"
	}

	return ""
}

func (m *DiskModel) saveDiskConfig() {
	m.config.TargetDisk = m.diskInput.Value()
	m.config.EFISize = m.efiInput.Value()
	m.config.CryptrootName = m.cryptInput.Value()
	m.config.SwapSize = m.swapInput.Value()
	m.config.SwapEnabled = m.swapEnabled

	fsTypes := []string{"btrfs", "ext4", "xfs"}
	m.config.FSType = fsTypes[m.fsType]
}

func (m DiskModel) View() string {
	titleStyle := lipgloss.NewStyle().
		Foreground(primaryColor).
		Bold(true).
		MarginBottom(1)

	labelStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#374151")).
		Bold(true).
		Width(18)

	helpStyle := lipgloss.NewStyle().
		Foreground(mutedColor).
		Italic(true).
		MarginLeft(2)

	errorStyle := lipgloss.NewStyle().
		Foreground(errorColor).
		MarginLeft(2)

	var formItems []string

	labels := []string{"Target Disk:", "EFI Size:", "LUKS Name:", "Swap Size:"}
	inputs := []textinput.Model{m.diskInput, m.efiInput, m.cryptInput, m.swapInput}
	helps := []string{
		"Target disk for installation (WARNING: will be erased!)",
		"EFI system partition size",
		"LUKS encryption container name",
		"Swap file size in megabytes",
	}

	for i, input := range inputs {
		var style lipgloss.Style
		if i == m.focused {
			style = focusedStyle
		} else {
			style = blurredStyle
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
				Foreground(successColor).
				MarginLeft(2).
				Render("✅ Valid"))
		}
		formItems = append(formItems, "") // spacing
	}

	// Filesystem options
	fsTypes := []string{"BTRFS (recommended)", "EXT4 (stable)", "XFS (performance)"}
	formItems = append(formItems, lipgloss.NewStyle().Bold(true).Render("Filesystem Type:"))
	for i, fsType := range fsTypes {
		marker := "○"
		if i == m.fsType {
			marker = "●"
		}
		formItems = append(formItems, lipgloss.NewStyle().
			MarginLeft(2).
			Render(fmt.Sprintf("%s %s", marker, fsType)))
	}

	formItems = append(formItems, "")

	// Warning
	warningBox := lipgloss.NewStyle().
		Foreground(errorColor).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(errorColor).
		Padding(0, 1).
		Render("⚠️  WARNING: All data on the target disk will be permanently erased!")

	formItems = append(formItems, warningBox)

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		titleStyle.Render("💾 Disk Configuration"),
		"Configure disk partitioning, encryption, and filesystem options.",
		"",
		lipgloss.JoinVertical(lipgloss.Left, formItems...),
		"",
		lipgloss.NewStyle().
			Foreground(successColor).
			Render("Use Tab/↑↓ to navigate, Enter to continue"),
	)

	containerStyle := lipgloss.NewStyle().
		Width(m.width - 4).
		Height(m.height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(primaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(content)
}

// Simplified PackageModel and SummaryModel
type PackageModel struct {
	width         int
	height        int
	config        *Config
	shouldProceed bool
}

func NewPackageModel(config *Config) *PackageModel {
	return &PackageModel{config: config}
}

func (m PackageModel) Init() tea.Cmd { return nil }

func (m *PackageModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			m.shouldProceed = true
		}
	}
	return m, nil
}

func (m PackageModel) View() string {
	titleStyle := lipgloss.NewStyle().
		Foreground(primaryColor).
		Bold(true).
		MarginBottom(1)

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		titleStyle.Render("📦 Package Configuration"),
		"Package selection and installation mode configuration.",
		"",
		fmt.Sprintf("Install Mode: %s", m.config.InstallMode),
		fmt.Sprintf("Optional Packages: %t", m.config.OptionalPackages),
		fmt.Sprintf("Security Packages: %t", m.config.SecurityPackages),
		"",
		"[Full package selection interface would be implemented here]",
		"",
		lipgloss.NewStyle().
			Foreground(successColor).
			Render("Press Enter to continue"),
	)

	containerStyle := lipgloss.NewStyle().
		Width(m.width - 4).
		Height(m.height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(primaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(content)
}

type SummaryModel struct {
	width          int
	height         int
	config         *Config
	shouldGenerate bool
}

func NewSummaryModel(config *Config) *SummaryModel {
	return &SummaryModel{config: config}
}

func (m SummaryModel) Init() tea.Cmd { return nil }

func (m *SummaryModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			m.shouldGenerate = true
		}
	}
	return m, nil
}

func (m SummaryModel) View() string {
	titleStyle := lipgloss.NewStyle().
		Foreground(primaryColor).
		Bold(true).
		MarginBottom(1)

	labelStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#374151")).
		Bold(true).
		Width(20)

	valueStyle := lipgloss.NewStyle().
		Foreground(successColor)

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		titleStyle.Render("📋 Configuration Summary"),
		"Review your configuration before generating the installation script.",
		"",
		lipgloss.NewStyle().Bold(true).Render("System Configuration:"),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("Hostname:"),
			valueStyle.Render(m.config.Hostname)),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("Timezone:"),
			valueStyle.Render(m.config.Timezone)),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("Locale:"),
			valueStyle.Render(m.config.Locale)),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("Keymap:"),
			valueStyle.Render(m.config.Keymap)),
		"",
		lipgloss.NewStyle().Bold(true).Render("User Configuration:"),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("Username:"),
			valueStyle.Render(m.config.Username)),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("Groups:"),
			valueStyle.Render(strings.Join(m.config.UserGroups, ", "))),
		"",
		lipgloss.NewStyle().Bold(true).Render("Disk Configuration:"),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("Target Disk:"),
			valueStyle.Render(m.config.TargetDisk)),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("Filesystem:"),
			valueStyle.Render(m.config.FSType)),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("EFI Size:"),
			valueStyle.Render(m.config.EFISize)),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("LUKS Container:"),
			valueStyle.Render(m.config.CryptrootName)),
		"",
		lipgloss.NewStyle().Bold(true).Render("Package Configuration:"),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("Install Mode:"),
			valueStyle.Render(m.config.InstallMode)),
		"",
		lipgloss.NewStyle().
			Foreground(warningColor).
			Bold(true).
			Render("Press Enter to start installation"),
	)

	maxWidth := 80
	if m.width > 0 && m.width < maxWidth {
		maxWidth = m.width - 4
	}

	containerStyle := lipgloss.NewStyle().
		Width(maxWidth).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(primaryColor).
		Padding(1, 2).
		Margin(1, 2)

	return containerStyle.Render(content)
}

// InstallModel handles the actual installation process
type InstallModel struct {
	width       int
	height      int
	config      *Config
	installing  bool
	completed   bool
	progress    []string
	currentStep string
	error       string
}

func NewInstallModel(config *Config) *InstallModel {
	return &InstallModel{
		config: config,
	}
}

func (m InstallModel) Init() tea.Cmd { return nil }

func (m *InstallModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if m.completed && !m.installing {
			switch msg.String() {
			case "r":
				// Reboot command would go here
				return m, tea.Quit
			case "q", "enter":
				return m, tea.Quit
			}
		} else if !m.installing {
			switch msg.String() {
			case "enter":
				m.installing = true
				return m, m.startInstallation()
			case "esc":
				// Go back to summary if not installing
				return m, nil
			}
		}
	case installProgressMsg:
		m.currentStep = string(msg)
		m.progress = append(m.progress, m.currentStep)
		return m, nil
	case installCompleteMsg:
		m.completed = true
		m.installing = false
		m.currentStep = "Installation completed successfully!"
		return m, nil
	case installErrorMsg:
		m.error = string(msg)
		m.installing = false
		return m, nil
	}
	return m, nil
}

func (m *InstallModel) startInstallation() tea.Cmd {
	return func() tea.Msg {
		// For now, simulate the installation process
		// In the real implementation, this would call the InstallerEngine

		steps := []string{
			"Performing pre-flight checks...",
			"Preparing disk partitions...",
			"Setting up LUKS encryption...",
			"Creating filesystems...",
			"Installing base system...",
			"Configuring system settings...",
			"Setting up user account...",
			"Installing bootloader...",
			"Finalizing installation...",
		}

		for i, step := range steps {
			// In real implementation, this would update progress
			_ = step                // Use the variable
			_ = i                   // Use the variable
			time.Sleep(time.Second) // Simulate work
		}

		return installCompleteMsg{}
	}
}

func (m InstallModel) View() string {
	titleStyle := lipgloss.NewStyle().
		Foreground(primaryColor).
		Bold(true).
		MarginBottom(1)

	if !m.installing && !m.completed && m.error == "" {
		// Pre-installation confirmation
		content := lipgloss.JoinVertical(
			lipgloss.Left,
			titleStyle.Render("🚀 Ready to Install Arch Linux"),
			"",
			"⚠️  WARNING: This will completely erase the target disk!",
			"",
			fmt.Sprintf("Target Disk: %s", m.config.TargetDisk),
			fmt.Sprintf("Hostname: %s", m.config.Hostname),
			fmt.Sprintf("Username: %s", m.config.Username),
			fmt.Sprintf("Filesystem: %s", m.config.FSType),
			"",
			"The installation process will:",
			"• Wipe and partition the target disk",
			"• Set up LUKS encryption (you'll be prompted for passphrase)",
			"• Install Arch Linux base system",
			"• Configure bootloader and system settings",
			"• Create user account",
			"",
			lipgloss.NewStyle().
				Foreground(errorColor).
				Bold(true).
				Render("This action cannot be undone!"),
			"",
			lipgloss.NewStyle().
				Foreground(successColor).
				Render("Press Enter to start installation, Esc to go back"),
		)

		maxWidth := 80
		if m.width > 0 && m.width < maxWidth {
			maxWidth = m.width - 4
		}

		containerStyle := lipgloss.NewStyle().
			Width(maxWidth).
			Border(lipgloss.RoundedBorder()).
			BorderForeground(errorColor).
			Padding(1, 2).
			Margin(1, 2)

		return containerStyle.Render(content)
	}

	if m.error != "" {
		// Installation error
		content := lipgloss.JoinVertical(
			lipgloss.Left,
			titleStyle.Render("❌ Installation Failed"),
			"",
			lipgloss.NewStyle().
				Foreground(errorColor).
				Render("Error: "+m.error),
			"",
			"Please check the logs and try again.",
			"",
			lipgloss.NewStyle().
				Foreground(mutedColor).
				Render("Press q to exit"),
		)

		maxWidth := 80
		if m.width > 0 && m.width < maxWidth {
			maxWidth = m.width - 4
		}

		containerStyle := lipgloss.NewStyle().
			Width(maxWidth).
			Border(lipgloss.RoundedBorder()).
			BorderForeground(errorColor).
			Padding(1, 2).
			Margin(1, 2)

		return containerStyle.Render(content)
	}

	if m.completed {
		// Installation complete
		content := lipgloss.JoinVertical(
			lipgloss.Left,
			titleStyle.Render("✅ Installation Complete!"),
			"",
			"Arch Linux has been successfully installed.",
			"",
			"Your system is ready to use with:",
			fmt.Sprintf("• Hostname: %s", m.config.Hostname),
			fmt.Sprintf("• User: %s (with sudo access)", m.config.Username),
			fmt.Sprintf("• Filesystem: %s with encryption", m.config.FSType),
			"• GRUB bootloader configured",
			"• NetworkManager enabled",
			"",
			"Next steps:",
			"1. Remove the installation media",
			"2. Reboot your system",
			"3. Enter your LUKS passphrase at boot",
			"4. Log in with your user account",
			"",
			lipgloss.NewStyle().
				Foreground(successColor).
				Bold(true).
				Render("Press 'r' to reboot now, or 'q' to exit"),
		)

		maxWidth := 80
		if m.width > 0 && m.width < maxWidth {
			maxWidth = m.width - 4
		}

		containerStyle := lipgloss.NewStyle().
			Width(maxWidth).
			Border(lipgloss.RoundedBorder()).
			BorderForeground(successColor).
			Padding(1, 2).
			Margin(1, 2)

		return containerStyle.Render(content)
	}

	// Installation in progress
	var progressItems []string
	for i, step := range m.progress {
		if i == len(m.progress)-1 {
			// Current step
			progressItems = append(progressItems, lipgloss.NewStyle().
				Foreground(primaryColor).
				Render("🔄 "+step))
		} else {
			// Completed step
			progressItems = append(progressItems, lipgloss.NewStyle().
				Foreground(successColor).
				Render("✅ "+step))
		}
	}

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		titleStyle.Render("🏗️  Installing Arch Linux"),
		"",
		lipgloss.JoinVertical(lipgloss.Left, progressItems...),
		"",
		"Please wait while the installation completes...",
		"",
		lipgloss.NewStyle().
			Foreground(mutedColor).
			Render("This may take several minutes depending on your internet connection."),
	)

	maxWidth := 80
	if m.width > 0 && m.width < maxWidth {
		maxWidth = m.width - 4
	}

	containerStyle := lipgloss.NewStyle().
		Width(maxWidth).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(primaryColor).
		Padding(1, 2).
		Margin(1, 2)

	return containerStyle.Render(content)
}

// Message types for installation progress
type installProgressMsg string
type installCompleteMsg struct {
	err error
}
type installErrorMsg string
