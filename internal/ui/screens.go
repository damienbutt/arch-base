package ui

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"

	"github.com/damienbutt/arch-base/internal/styles"
	"github.com/damienbutt/arch-base/internal/types"
)

// UserModel handles user configuration
type UserModel struct {
	Width          int
	Height         int
	config         *types.Config
	ShouldProceed  bool
	focused        int
	usernameInput  textinput.Model
	passwordInput  textinput.Model
	confirmInput   textinput.Model
	groupOptions   []string
	selectedGroups map[int]bool
	errors         []string
	showingGroups  bool
}

func NewUserModel(config *types.Config) *UserModel {
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

		m.ShouldProceed = true

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
			Foreground(styles.SuccessColor).
			Render("Use Tab/↑↓ to navigate, Enter to continue to group selection"),
	)

	containerStyle := lipgloss.NewStyle().
		Width(m.Width - 4).
		Height(m.Height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.PrimaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(content)
}

func (m UserModel) renderGroupSelection() string {
	titleStyle := lipgloss.NewStyle().
		Foreground(styles.PrimaryColor).
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
			groupStyle = groupStyle.Foreground(styles.WarningColor).Bold(true)
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
			Foreground(styles.WarningColor).
			Render("⚠️  'wheel' group is required for sudo access"),
		"",
		lipgloss.NewStyle().
			Foreground(styles.SuccessColor).
			Render("Press Enter to continue, Esc to go back"),
	)

	containerStyle := lipgloss.NewStyle().
		Width(m.Width - 4).
		Height(m.Height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.PrimaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(content)
}

// DiskModel handles disk configuration
type DiskModel struct {
	Width         int
	Height        int
	config        *types.Config
	ShouldProceed bool
	focused       int
	diskInput     textinput.Model
	efiInput      textinput.Model
	cryptInput    textinput.Model
	swapInput     textinput.Model
	fsType        int
	swapEnabled   bool
	errors        []string
}

func NewDiskModel(config *types.Config) *DiskModel {
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
					m.ShouldProceed = true
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
		Foreground(styles.PrimaryColor).
		Bold(true).
		MarginBottom(1)

	labelStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#374151")).
		Bold(true).
		Width(18)

	helpStyle := lipgloss.NewStyle().
		Foreground(styles.MutedColor).
		Italic(true).
		MarginLeft(2)

	errorStyle := lipgloss.NewStyle().
		Foreground(styles.ErrorColor).
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
		Foreground(styles.ErrorColor).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.ErrorColor).
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
			Foreground(styles.SuccessColor).
			Render("Use Tab/↑↓ to navigate, Enter to continue"),
	)

	containerStyle := lipgloss.NewStyle().
		Width(m.Width - 4).
		Height(m.Height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.PrimaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(content)
}

// Simplified PackageModel and SummaryModel
type PackageModel struct {
	Width         int
	Height        int
	config        *types.Config
	ShouldProceed bool
}

func NewPackageModel(config *types.Config) *PackageModel {
	return &PackageModel{config: config}
}

func (m PackageModel) Init() tea.Cmd { return nil }

func (m *PackageModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			m.ShouldProceed = true
		}
	}
	return m, nil
}

func (m PackageModel) View() string {
	titleStyle := lipgloss.NewStyle().
		Foreground(styles.PrimaryColor).
		Bold(true).
		MarginBottom(1)

	content := lipgloss.JoinVertical(
		lipgloss.Left,
		titleStyle.Render("📦 Package Configuration"),
		"Package selection and installation mode configuration.",
		"",
		fmt.Sprintf("Profile: %s", m.config.Profile),
		fmt.Sprintf("Desktop Environment: %s", m.config.DesktopEnv),
		fmt.Sprintf("Audio System: %s", m.config.AudioSystem),
		"",
		"[This is a legacy screen - use ProfileModel instead]",
		"",
		lipgloss.NewStyle().
			Foreground(styles.SuccessColor).
			Render("Press Enter to continue"),
	)

	containerStyle := lipgloss.NewStyle().
		Width(m.Width - 4).
		Height(m.Height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.PrimaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(content)
}

type SummaryModel struct {
	Width          int
	Height         int
	config         *types.Config
	ShouldGenerate bool
}

func NewSummaryModel(config *types.Config) *SummaryModel {
	return &SummaryModel{config: config}
}

func (m SummaryModel) Init() tea.Cmd { return nil }

func (m *SummaryModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			m.ShouldGenerate = true
		}
	}
	return m, nil
}

func (m SummaryModel) View() string {
	titleStyle := lipgloss.NewStyle().
		Foreground(styles.PrimaryColor).
		Bold(true).
		MarginBottom(1)

	labelStyle := lipgloss.NewStyle().
		Foreground(lipgloss.Color("#374151")).
		Bold(true).
		Width(20)

	valueStyle := lipgloss.NewStyle().
		Foreground(styles.SuccessColor)

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
			labelStyle.Render("Profile:"),
			valueStyle.Render(m.config.Profile)),
		lipgloss.JoinHorizontal(lipgloss.Left,
			labelStyle.Render("Desktop Environment:"),
			valueStyle.Render(m.config.DesktopEnv)),
		"",
		lipgloss.NewStyle().
			Foreground(styles.WarningColor).
			Bold(true).
			Render("Press Enter to start installation"),
	)

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

// InstallModel handles the actual installation process
type InstallModel struct {
	Width       int
	Height      int
	config      *types.Config
	Installing  bool
	Completed   bool
	Progress    []string
	currentStep string
	error       string
}

func NewInstallModel(config *types.Config) *InstallModel {
	return &InstallModel{
		config: config,
	}
}

func (m InstallModel) Init() tea.Cmd { return nil }

func (m *InstallModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if m.Completed && !m.Installing {
			switch msg.String() {
			case "r":
				// Reboot command would go here
				return m, tea.Quit
			case "q", "enter":
				return m, tea.Quit
			}
		} else if !m.Installing {
			switch msg.String() {
			case "enter":
				m.Installing = true
				return m, m.startInstallation()
			case "esc":
				// Go back to summary if not installing
				return m, nil
			}
		}
	case installProgressMsg:
		m.currentStep = string(msg)
		m.Progress = append(m.Progress, m.currentStep)
		return m, nil
	case installCompleteMsg:
		m.Completed = true
		m.Installing = false
		m.currentStep = "Installation completed successfully!"
		return m, nil
	case installErrorMsg:
		m.error = string(msg)
		m.Installing = false
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
		Foreground(styles.PrimaryColor).
		Bold(true).
		MarginBottom(1)

	if !m.Installing && !m.Completed && m.error == "" {
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
				Foreground(styles.ErrorColor).
				Bold(true).
				Render("This action cannot be undone!"),
			"",
			lipgloss.NewStyle().
				Foreground(styles.SuccessColor).
				Render("Press Enter to start installation, Esc to go back"),
		)

		maxWidth := 80
		if m.Width > 0 && m.Width < maxWidth {
			maxWidth = m.Width - 4
		}

		containerStyle := lipgloss.NewStyle().
			Width(maxWidth).
			Border(lipgloss.RoundedBorder()).
			BorderForeground(styles.ErrorColor).
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
				Foreground(styles.ErrorColor).
				Render("Error: "+m.error),
			"",
			"Please check the logs and try again.",
			"",
			lipgloss.NewStyle().
				Foreground(styles.MutedColor).
				Render("Press q to exit"),
		)

		maxWidth := 80
		if m.Width > 0 && m.Width < maxWidth {
			maxWidth = m.Width - 4
		}

		containerStyle := lipgloss.NewStyle().
			Width(maxWidth).
			Border(lipgloss.RoundedBorder()).
			BorderForeground(styles.ErrorColor).
			Padding(1, 2).
			Margin(1, 2)

		return containerStyle.Render(content)
	}

	if m.Completed {
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
				Foreground(styles.SuccessColor).
				Bold(true).
				Render("Press 'r' to reboot now, or 'q' to exit"),
		)

		maxWidth := 80
		if m.Width > 0 && m.Width < maxWidth {
			maxWidth = m.Width - 4
		}

		containerStyle := lipgloss.NewStyle().
			Width(maxWidth).
			Border(lipgloss.RoundedBorder()).
			BorderForeground(styles.SuccessColor).
			Padding(1, 2).
			Margin(1, 2)

		return containerStyle.Render(content)
	}

	// Installation in progress
	var progressItems []string
	for i, step := range m.Progress {
		if i == len(m.Progress)-1 {
			// Current step
			progressItems = append(progressItems, lipgloss.NewStyle().
				Foreground(styles.PrimaryColor).
				Render("🔄 "+step))
		} else {
			// Completed step
			progressItems = append(progressItems, lipgloss.NewStyle().
				Foreground(styles.SuccessColor).
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
			Foreground(styles.MutedColor).
			Render("This may take several minutes depending on your internet connection."),
	)

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

// Message types for installation progress
type installProgressMsg string
type installCompleteMsg struct {
	err error
}
type installErrorMsg string

// NetworkModel handles network configuration
type NetworkModel struct {
	Width         int
	Height        int
	config        *types.Config
	ShouldProceed bool
	focused       int
	networkType   int // 0: DHCP, 1: Static, 2: None
	staticIP      textinput.Model
	gateway       textinput.Model
	dns           textinput.Model
	enableNetMgr  bool
	errors        []string
}

func NewNetworkModel(config *types.Config) *NetworkModel {
	staticIP := textinput.New()
	staticIP.Placeholder = "192.168.1.100/24"
	staticIP.SetValue(config.StaticIP)
	staticIP.Width = 20

	gateway := textinput.New()
	gateway.Placeholder = "192.168.1.1"
	gateway.SetValue(config.Gateway)
	gateway.Width = 15

	dns := textinput.New()
	dns.Placeholder = "8.8.8.8,1.1.1.1"
	dns.SetValue(strings.Join(config.DNS, ","))
	dns.Width = 25

	networkType := 0
	if config.NetworkConfig == "static" {
		networkType = 1
	} else if config.NetworkConfig == "none" {
		networkType = 2
	}

	return &NetworkModel{
		config:       config,
		networkType:  networkType,
		staticIP:     staticIP,
		gateway:      gateway,
		dns:          dns,
		enableNetMgr: config.EnableNetworkMgr,
		focused:      0,
	}
}

func (m NetworkModel) Init() tea.Cmd { return textinput.Blink }

func (m *NetworkModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			if m.validateAndSave() {
				m.ShouldProceed = true
			}
		case "tab", "down":
			m.nextField()
		case "shift+tab", "up":
			m.prevField()
		case " ":
			if m.focused == 0 {
				m.networkType = (m.networkType + 1) % 3
			} else if m.focused == 4 {
				m.enableNetMgr = !m.enableNetMgr
			}
		}
	}

	// Update active input field
	if m.networkType == 1 { // Static
		switch m.focused {
		case 1:
			m.staticIP, cmd = m.staticIP.Update(msg)
		case 2:
			m.gateway, cmd = m.gateway.Update(msg)
		case 3:
			m.dns, cmd = m.dns.Update(msg)
		}
	}

	return m, cmd
}

func (m *NetworkModel) nextField() {
	maxField := 4
	if m.networkType != 1 { // Not static
		maxField = 1
	}
	if m.focused < maxField {
		m.focused++
	}
	m.updateFocus()
}

func (m *NetworkModel) prevField() {
	if m.focused > 0 {
		m.focused--
	}
	m.updateFocus()
}

func (m *NetworkModel) updateFocus() {
	m.staticIP.Blur()
	m.gateway.Blur()
	m.dns.Blur()

	if m.networkType == 1 {
		switch m.focused {
		case 1:
			m.staticIP.Focus()
		case 2:
			m.gateway.Focus()
		case 3:
			m.dns.Focus()
		}
	}
}

func (m *NetworkModel) validateAndSave() bool {
	networkTypes := []string{"dhcp", "static", "none"}
	m.config.NetworkConfig = networkTypes[m.networkType]
	m.config.EnableNetworkMgr = m.enableNetMgr

	if m.networkType == 1 { // Static
		m.config.StaticIP = m.staticIP.Value()
		m.config.Gateway = m.gateway.Value()
		m.config.DNS = strings.Split(m.dns.Value(), ",")
	}

	return true
}

func (m NetworkModel) View() string {
	title := styles.TitleStyle.Render("🌐 Network Configuration")

	networkTypes := []string{"DHCP (automatic)", "Static IP", "No network"}
	var networkOptions []string
	for i, option := range networkTypes {
		marker := "○"
		if i == m.networkType {
			marker = "●"
		}
		networkOptions = append(networkOptions, fmt.Sprintf("%s %s", marker, option))
	}

	content := []string{
		title,
		"Configure network settings for the installed system.",
		"",
		"Network Configuration:",
	}
	content = append(content, networkOptions...)

	if m.networkType == 1 { // Static
		content = append(content, []string{
			"",
			"Static IP Settings:",
			fmt.Sprintf("IP Address: %s", m.staticIP.View()),
			fmt.Sprintf("Gateway: %s", m.gateway.View()),
			fmt.Sprintf("DNS Servers: %s", m.dns.View()),
		}...)
	}

	content = append(content, []string{
		"",
		fmt.Sprintf("☐ Enable NetworkManager: %t", m.enableNetMgr),
		"",
		"Use arrows to navigate, Space to toggle, Enter to continue",
	}...)

	containerStyle := lipgloss.NewStyle().
		Width(m.Width - 4).
		Height(m.Height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.PrimaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(lipgloss.JoinVertical(lipgloss.Left, content...))
}

// MirrorModel handles mirror selection and configuration
type MirrorModel struct {
	Width             int
	Height            int
	config            *types.Config
	ShouldProceed     bool
	focused           int
	regions           []string
	selectedRegion    int
	testMirrors       bool
	parallelDownloads textinput.Model
	errors            []string
}

func NewMirrorModel(config *types.Config) *MirrorModel {
	regions := []string{"Worldwide", "United States", "Germany", "United Kingdom", "France", "Canada", "Australia", "Japan", "China"}

	parallelDownloads := textinput.New()
	parallelDownloads.Placeholder = "5"
	parallelDownloads.SetValue(fmt.Sprintf("%d", config.ParallelDownloads))
	parallelDownloads.Width = 5

	return &MirrorModel{
		config:            config,
		regions:           regions,
		selectedRegion:    0,
		testMirrors:       config.TestMirrors,
		parallelDownloads: parallelDownloads,
		focused:           0,
	}
}

func (m MirrorModel) Init() tea.Cmd { return textinput.Blink }

func (m *MirrorModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			if m.validateAndSave() {
				m.ShouldProceed = true
			}
		case "tab", "down":
			m.focused = (m.focused + 1) % 3
			m.updateFocus()
		case "shift+tab", "up":
			m.focused = (m.focused - 1 + 3) % 3
			m.updateFocus()
		case " ":
			if m.focused == 0 {
				m.selectedRegion = (m.selectedRegion + 1) % len(m.regions)
			} else if m.focused == 1 {
				m.testMirrors = !m.testMirrors
			}
		}
	}

	if m.focused == 2 {
		m.parallelDownloads, cmd = m.parallelDownloads.Update(msg)
	}

	return m, cmd
}

func (m *MirrorModel) updateFocus() {
	m.parallelDownloads.Blur()
	if m.focused == 2 {
		m.parallelDownloads.Focus()
	}
}

func (m *MirrorModel) validateAndSave() bool {
	m.config.MirrorRegion = m.regions[m.selectedRegion]
	m.config.TestMirrors = m.testMirrors

	if downloads, err := strconv.Atoi(m.parallelDownloads.Value()); err == nil {
		m.config.ParallelDownloads = downloads
	}

	return true
}

func (m MirrorModel) View() string {
	title := styles.TitleStyle.Render("🪞 Mirror Configuration")

	content := []string{
		title,
		"Configure package mirrors and download settings.",
		"",
		fmt.Sprintf("Region: %s", m.regions[m.selectedRegion]),
		fmt.Sprintf("Test mirrors: %t", m.testMirrors),
		fmt.Sprintf("Parallel downloads: %s", m.parallelDownloads.View()),
		"",
		"Use arrows to navigate, Space to change, Enter to continue",
	}

	containerStyle := lipgloss.NewStyle().
		Width(m.Width - 4).
		Height(m.Height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.PrimaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(lipgloss.JoinVertical(lipgloss.Left, content...))
}

// BootloaderModel handles bootloader configuration
type BootloaderModel struct {
	Width         int
	Height        int
	config        *types.Config
	ShouldProceed bool
	focused       int
	bootloader    int // 0: GRUB, 1: systemd-boot, 2: rEFInd
	espMountpoint textinput.Model
	errors        []string
}

func NewBootloaderModel(config *types.Config) *BootloaderModel {
	espMountpoint := textinput.New()
	espMountpoint.Placeholder = "/boot/efi"
	espMountpoint.SetValue(config.ESPMountpoint)
	espMountpoint.Width = 20

	bootloader := 0
	if config.Bootloader == "systemd-boot" {
		bootloader = 1
	} else if config.Bootloader == "refind" {
		bootloader = 2
	}

	return &BootloaderModel{
		config:        config,
		bootloader:    bootloader,
		espMountpoint: espMountpoint,
		focused:       0,
	}
}

func (m BootloaderModel) Init() tea.Cmd { return textinput.Blink }

func (m *BootloaderModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd

	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			if m.validateAndSave() {
				m.ShouldProceed = true
			}
		case "tab", "down":
			m.focused = (m.focused + 1) % 2
			m.updateFocus()
		case "shift+tab", "up":
			m.focused = (m.focused - 1 + 2) % 2
			m.updateFocus()
		case " ":
			if m.focused == 0 {
				m.bootloader = (m.bootloader + 1) % 3
			}
		}
	}

	if m.focused == 1 {
		m.espMountpoint, cmd = m.espMountpoint.Update(msg)
	}

	return m, cmd
}

func (m *BootloaderModel) updateFocus() {
	m.espMountpoint.Blur()
	if m.focused == 1 {
		m.espMountpoint.Focus()
	}
}

func (m *BootloaderModel) validateAndSave() bool {
	bootloaders := []string{"grub", "systemd-boot", "refind"}
	m.config.Bootloader = bootloaders[m.bootloader]
	m.config.ESPMountpoint = m.espMountpoint.Value()
	return true
}

func (m BootloaderModel) View() string {
	title := styles.TitleStyle.Render("🥾 Bootloader Configuration")

	bootloaders := []string{"GRUB (recommended)", "systemd-boot (UEFI only)", "rEFInd (advanced)"}
	var bootloaderOptions []string
	for i, option := range bootloaders {
		marker := "○"
		if i == m.bootloader {
			marker = "●"
		}
		bootloaderOptions = append(bootloaderOptions, fmt.Sprintf("%s %s", marker, option))
	}

	content := []string{
		title,
		"Configure the system bootloader.",
		"",
		"Bootloader:",
	}
	content = append(content, bootloaderOptions...)
	content = append(content, []string{
		"",
		fmt.Sprintf("ESP Mountpoint: %s", m.espMountpoint.View()),
		"",
		"Use arrows to navigate, Space to change, Enter to continue",
	}...)

	containerStyle := lipgloss.NewStyle().
		Width(m.Width - 4).
		Height(m.Height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.PrimaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(lipgloss.JoinVertical(lipgloss.Left, content...))
}

// ProfileModel handles installation profile selection (replaces simple PackageModel)
type ProfileModel struct {
	Width         int
	Height        int
	config        *types.Config
	ShouldProceed bool
	focused       int
	profile       int // 0: Desktop, 1: Server, 2: Minimal
	desktopEnv    int // 0: GNOME, 1: KDE, 2: XFCE, 3: i3, etc.
	audioSystem   int // 0: PipeWire, 1: PulseAudio, 2: ALSA
	microcode     int // 0: Intel, 1: AMD, 2: None
	aurHelper     int // 0: yay, 1: paru, 2: none
	errors        []string
}

func NewProfileModel(config *types.Config) *ProfileModel {
	profile := 0
	if config.Profile == "server" {
		profile = 1
	} else if config.Profile == "minimal" {
		profile = 2
	}

	desktopEnv := 0
	if config.DesktopEnv == "kde" {
		desktopEnv = 1
	} else if config.DesktopEnv == "xfce" {
		desktopEnv = 2
	} else if config.DesktopEnv == "i3" {
		desktopEnv = 3
	}

	audioSystem := 0
	if config.AudioSystem == "pulseaudio" {
		audioSystem = 1
	} else if config.AudioSystem == "alsa" {
		audioSystem = 2
	}

	microcode := 0
	if config.Microcode == "amd" {
		microcode = 1
	} else if config.Microcode == "none" {
		microcode = 2
	}

	aurHelper := 0
	if config.AURHelper == "paru" {
		aurHelper = 1
	} else if config.AURHelper == "none" {
		aurHelper = 2
	}

	return &ProfileModel{
		config:      config,
		profile:     profile,
		desktopEnv:  desktopEnv,
		audioSystem: audioSystem,
		microcode:   microcode,
		aurHelper:   aurHelper,
		focused:     0,
	}
}

func (m ProfileModel) Init() tea.Cmd { return nil }

func (m *ProfileModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "enter":
			if m.validateAndSave() {
				m.ShouldProceed = true
			}
		case "tab", "down":
			maxField := 4
			if m.profile != 0 { // Not desktop
				maxField = 2 // Skip desktop env and audio
			}
			m.focused = (m.focused + 1) % (maxField + 1)
		case "shift+tab", "up":
			maxField := 4
			if m.profile != 0 {
				maxField = 2
			}
			m.focused = (m.focused - 1 + maxField + 1) % (maxField + 1)
		case " ":
			switch m.focused {
			case 0:
				m.profile = (m.profile + 1) % 3
			case 1:
				if m.profile == 0 {
					m.desktopEnv = (m.desktopEnv + 1) % 4
				}
			case 2:
				if m.profile == 0 {
					m.audioSystem = (m.audioSystem + 1) % 3
				}
			case 3:
				m.microcode = (m.microcode + 1) % 3
			case 4:
				m.aurHelper = (m.aurHelper + 1) % 3
			}
		}
	}
	return m, nil
}

func (m *ProfileModel) validateAndSave() bool {
	profiles := []string{"desktop", "server", "minimal"}
	m.config.Profile = profiles[m.profile]

	if m.profile == 0 { // Desktop
		desktopEnvs := []string{"gnome", "kde", "xfce", "i3"}
		m.config.DesktopEnv = desktopEnvs[m.desktopEnv]

		audioSystems := []string{"pipewire", "pulseaudio", "alsa"}
		m.config.AudioSystem = audioSystems[m.audioSystem]
	}

	microcodes := []string{"intel", "amd", "none"}
	m.config.Microcode = microcodes[m.microcode]

	aurHelpers := []string{"yay", "paru", "none"}
	m.config.AURHelper = aurHelpers[m.aurHelper]

	return true
}

func (m ProfileModel) View() string {
	title := styles.TitleStyle.Render("📦 Installation Profile")

	profiles := []string{"Desktop (full GUI)", "Server (no GUI)", "Minimal (base only)"}
	var profileOptions []string
	for i, option := range profiles {
		marker := "○"
		if i == m.profile {
			marker = "●"
		}
		profileOptions = append(profileOptions, fmt.Sprintf("%s %s", marker, option))
	}

	content := []string{
		title,
		"Select installation profile and software packages.",
		"",
		"Installation Profile:",
	}
	content = append(content, profileOptions...)

	if m.profile == 0 { // Desktop
		desktopEnvs := []string{"GNOME", "KDE Plasma", "XFCE", "i3wm"}
		audioSystems := []string{"PipeWire", "PulseAudio", "ALSA only"}

		content = append(content, []string{
			"",
			fmt.Sprintf("Desktop Environment: %s", desktopEnvs[m.desktopEnv]),
			fmt.Sprintf("Audio System: %s", audioSystems[m.audioSystem]),
		}...)
	}

	microcodes := []string{"Intel", "AMD", "None"}
	aurHelpers := []string{"yay", "paru", "none"}

	content = append(content, []string{
		"",
		fmt.Sprintf("Microcode: %s", microcodes[m.microcode]),
		fmt.Sprintf("AUR Helper: %s", aurHelpers[m.aurHelper]),
		"",
		"Use arrows to navigate, Space to change, Enter to continue",
	}...)

	containerStyle := lipgloss.NewStyle().
		Width(m.Width - 4).
		Height(m.Height - 8).
		Border(lipgloss.RoundedBorder()).
		BorderForeground(styles.PrimaryColor).
		Padding(2).
		Margin(1)

	return containerStyle.Render(lipgloss.JoinVertical(lipgloss.Left, content...))
}
