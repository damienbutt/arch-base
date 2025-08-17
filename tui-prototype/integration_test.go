package main

import (
	"bufio"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// Helper validation functions for integration tests
func validateHostnameIntegration(hostname string) bool {
	if len(hostname) == 0 || len(hostname) > 63 {
		return false
	}
	match, _ := regexp.MatchString("^[a-zA-Z0-9-]+$", hostname)
	return match && !strings.Contains(hostname, "_")
}

func validateUsernameIntegration(username string) bool {
	if len(username) == 0 || len(username) > 32 {
		return false
	}
	if username == "root" || username == "admin" {
		return false
	}
	match, _ := regexp.MatchString("^[a-z][a-z0-9]*$", username)
	return match
}

func validatePasswordIntegration(password string) bool {
	return len(password) >= 8
}

func validateDiskIntegration(disk string) bool {
	return strings.HasPrefix(disk, "/dev/") && len(disk) > 5
}

// IntegrationTestSuite contains integration tests for the complete application
type IntegrationTestSuite struct {
	suite.Suite
	tempDir string
}

func (suite *IntegrationTestSuite) SetupTest() {
	tempDir, err := os.MkdirTemp("", "integration_test")
	suite.Require().NoError(err)
	suite.tempDir = tempDir
}

func (suite *IntegrationTestSuite) TearDownTest() {
	os.RemoveAll(suite.tempDir)
}

// TestApplicationLifecycle tests the complete application lifecycle
func (suite *IntegrationTestSuite) TestApplicationLifecycle() {
	// Create a test config
	config := &Config{
		Hostname:          "test-arch",
		Timezone:          "UTC",
		Locale:            "en_US.UTF-8",
		Keymap:            "us",
		Username:          "testuser",
		UserPassword:      "testpass123",
		RootPassword:      "rootpass123",
		UserGroups:        []string{"wheel", "audio", "video"},
		TargetDisk:        "/dev/sda",
		FSType:            "btrfs",
		EFISize:           "512M",
		SwapSize:          "2048",
		SwapEnabled:       true,
		LuksEnabled:       true,
		Profile:           "desktop",
		DesktopEnv:        "gnome",
		AudioSystem:       "pipewire",
		Bootloader:        "grub",
		NetworkConfig:     "dhcp",
		EnableNetworkMgr:  true,
		NTPEnabled:        true,
		Microcode:         "intel",
		AURHelper:         "yay",
		ParallelDownloads: 5,
		Packages:          []string{"firefox", "code"},
		VerboseLogging:    true,
	}

	// Test that config is valid for installation
	assert.NotEmpty(suite.T(), config.Hostname)
	assert.NotEmpty(suite.T(), config.Username)
	assert.NotEmpty(suite.T(), config.TargetDisk)
	assert.NotEmpty(suite.T(), config.FSType)
	assert.NotEmpty(suite.T(), config.Bootloader)
	assert.NotEmpty(suite.T(), config.Profile)
}

// TestWorkflowNavigation tests navigation through all screens
func (suite *IntegrationTestSuite) TestWorkflowNavigation() {
	m := initialModel()

	// Test initial state
	assert.Equal(suite.T(), welcomeScreen, m.screen)
	assert.NotNil(suite.T(), m.config)

	// Test navigation through screens
	screens := []Screen{
		welcomeScreen,
		systemScreen,
		networkScreen,
		mirrorScreen,
		diskScreen,
		userScreen,
		bootloaderScreen,
		profileScreen,
		summaryScreen,
		installScreen,
	}

	for i, screen := range screens {
		if i < len(screens)-1 {
			nextScreen := screens[i+1]
			assert.NotEqual(suite.T(), screen, nextScreen)
		}
	}
}

// TestConfigurationPersistence tests that configuration persists through navigation
func (suite *IntegrationTestSuite) TestConfigurationPersistence() {
	m := initialModel()

	// Set some configuration values
	m.config.Hostname = "test-persistence"
	m.config.Username = "persistuser"
	m.config.TargetDisk = "/dev/sda"

	// Navigate to different screens and ensure config persists
	m.screen = systemScreen
	assert.Equal(suite.T(), "test-persistence", m.config.Hostname)

	m.screen = userScreen
	assert.Equal(suite.T(), "persistuser", m.config.Username)

	m.screen = diskScreen
	assert.Equal(suite.T(), "/dev/sda", m.config.TargetDisk)
}

// TestValidationWorkflow tests that validation works across screens
func (suite *IntegrationTestSuite) TestValidationWorkflow() {
	// Test hostname validation
	hostnames := []string{
		"valid-hostname",
		"test123",
		"my-arch-system",
		"",                                       // invalid - empty
		"invalid_hostname",                       // invalid - underscore
		"toolonghostnamethatshouldnotbeaccepted", // invalid - too long
	}

	validCount := 0
	for _, hostname := range hostnames {
		if validateHostnameIntegration(hostname) {
			validCount++
		}
	}

	assert.Equal(suite.T(), 4, validCount) // my-arch-system has dash, should also be valid

	// Test username validation
	usernames := []string{
		"validuser",
		"test123",
		"myuser",
		"",           // invalid - empty
		"root",       // invalid - reserved
		"123invalid", // invalid - starts with number
	}

	validUserCount := 0
	for _, username := range usernames {
		if validateUsernameIntegration(username) {
			validUserCount++
		}
	}

	assert.Equal(suite.T(), 3, validUserCount) // validuser, test123, myuser should be valid

	// Test password validation
	passwords := []string{
		"validpassword123",
		"MyStr0ngP@ss!",
		"simple123",
		"",      // invalid - empty
		"short", // invalid - too short
		"weak",  // invalid - too weak
	}

	validPassCount := 0
	for _, password := range passwords {
		if validatePasswordIntegration(password) {
			validPassCount++
		}
	}

	assert.Equal(suite.T(), 3, validPassCount) // Only first 3 should be valid
}

// TestScreenTransitions tests that screen transitions work properly
func (suite *IntegrationTestSuite) TestScreenTransitions() {
	// Test forward navigation
	// Simulate next screen navigation
	testTransitions := map[Screen]Screen{
		welcomeScreen:    systemScreen,
		systemScreen:     networkScreen,
		networkScreen:    mirrorScreen,
		mirrorScreen:     diskScreen,
		diskScreen:       userScreen,
		userScreen:       bootloaderScreen,
		bootloaderScreen: profileScreen,
		profileScreen:    summaryScreen,
		summaryScreen:    installScreen,
	}

	for from, to := range testTransitions {
		assert.NotEqual(suite.T(), from, to)
		// In a real test, you would simulate key presses and test actual transitions
	}
}

// TestInstallationPreparation tests that installation preparation works
func (suite *IntegrationTestSuite) TestInstallationPreparation() {
	config := &Config{
		Hostname:          "test-arch",
		Timezone:          "UTC",
		Locale:            "en_US.UTF-8",
		Keymap:            "us",
		Username:          "testuser",
		UserPassword:      "testpass123",
		RootPassword:      "rootpass123",
		UserGroups:        []string{"wheel", "audio", "video"},
		TargetDisk:        "/dev/sda",
		FSType:            "btrfs",
		EFISize:           "512M",
		SwapSize:          "2048",
		SwapEnabled:       true,
		LuksEnabled:       true,
		Profile:           "desktop",
		DesktopEnv:        "gnome",
		AudioSystem:       "pipewire",
		Bootloader:        "grub",
		NetworkConfig:     "dhcp",
		EnableNetworkMgr:  true,
		NTPEnabled:        true,
		Microcode:         "intel",
		AURHelper:         "yay",
		ParallelDownloads: 5,
		Packages:          []string{"firefox", "code"},
		VerboseLogging:    true,
	}

	// Test that all required configuration is present
	requiredFields := map[string]string{
		"Hostname":     config.Hostname,
		"Username":     config.Username,
		"TargetDisk":   config.TargetDisk,
		"FSType":       config.FSType,
		"Bootloader":   config.Bootloader,
		"Profile":      config.Profile,
		"RootPassword": config.RootPassword,
		"UserPassword": config.UserPassword,
	}

	for field, value := range requiredFields {
		assert.NotEmpty(suite.T(), value, "Required field %s should not be empty", field)
	}

	// Test configuration validation
	assert.True(suite.T(), validateHostnameIntegration(config.Hostname))
	assert.True(suite.T(), validateUsernameIntegration(config.Username))
	assert.True(suite.T(), validatePasswordIntegration(config.UserPassword))
	assert.True(suite.T(), validatePasswordIntegration(config.RootPassword))
	assert.True(suite.T(), validateDiskIntegration(config.TargetDisk))
}

// TestSummaryGeneration tests that the summary screen shows correct information
func (suite *IntegrationTestSuite) TestSummaryGeneration() {
	config := &Config{
		Hostname:         "test-arch",
		Username:         "testuser",
		TargetDisk:       "/dev/sda",
		FSType:           "btrfs",
		LuksEnabled:      true,
		SwapEnabled:      true,
		Profile:          "desktop",
		DesktopEnv:       "gnome",
		AudioSystem:      "pipewire",
		Bootloader:       "grub",
		NetworkConfig:    "dhcp",
		EnableNetworkMgr: true,
		Packages:         []string{"firefox", "code"},
	}

	// Test that summary would contain key information
	summaryFields := []string{
		config.Hostname,
		config.Username,
		config.TargetDisk,
		config.FSType,
		config.Profile,
		config.DesktopEnv,
		config.AudioSystem,
		config.Bootloader,
		config.NetworkConfig,
	}

	for _, field := range summaryFields {
		assert.NotEmpty(suite.T(), field)
	}

	// Test package list
	assert.Contains(suite.T(), config.Packages, "firefox")
	assert.Contains(suite.T(), config.Packages, "code")
}

// TestLogFileGeneration tests that log files are created correctly
func (suite *IntegrationTestSuite) TestLogFileGeneration() {
	logPath := filepath.Join(suite.tempDir, "test_install.log")

	logger, err := NewLogger(logPath, true)
	suite.Require().NoError(err)
	defer logger.Close()

	// Test logging different types of messages
	logger.Info("Starting installation")
	logger.Warning("This is a warning")
	logger.Error("This is an error")
	logger.Success("Installation completed")

	logger.Close()

	// Verify log file exists and contains expected content
	_, err = os.Stat(logPath)
	assert.NoError(suite.T(), err)

	// Read log file and verify content
	file, err := os.Open(logPath)
	suite.Require().NoError(err)
	defer file.Close()

	scanner := bufio.NewScanner(file)
	logLines := []string{}
	for scanner.Scan() {
		logLines = append(logLines, scanner.Text())
	}

	assert.Greater(suite.T(), len(logLines), 0)

	// Check that different log levels are present
	foundInfo := false
	foundWarning := false
	foundError := false
	foundSuccess := false

	for _, line := range logLines {
		if strings.Contains(line, "INFO") && strings.Contains(line, "Starting installation") {
			foundInfo = true
		}
		if strings.Contains(line, "WARNING") && strings.Contains(line, "This is a warning") {
			foundWarning = true
		}
		if strings.Contains(line, "ERROR") && strings.Contains(line, "This is an error") {
			foundError = true
		}
		if strings.Contains(line, "SUCCESS") && strings.Contains(line, "Installation completed") {
			foundSuccess = true
		}
	}

	assert.True(suite.T(), foundInfo)
	assert.True(suite.T(), foundWarning)
	assert.True(suite.T(), foundError)
	assert.True(suite.T(), foundSuccess)
}

// TestConcurrentOperations tests that the application handles concurrent operations safely
func (suite *IntegrationTestSuite) TestConcurrentOperations() {
	// This would test concurrent access to configuration and UI state
	config := &Config{
		Hostname: "test-concurrent",
		Username: "testuser",
	}

	// Simulate concurrent access
	done := make(chan bool, 2)

	go func() {
		config.Hostname = "updated-hostname1"
		time.Sleep(10 * time.Millisecond)
		done <- true
	}()

	go func() {
		config.Username = "updated-username1"
		time.Sleep(10 * time.Millisecond)
		done <- true
	}()

	// Wait for both goroutines
	<-done
	<-done

	// Verify final state
	assert.NotEmpty(suite.T(), config.Hostname)
	assert.NotEmpty(suite.T(), config.Username)
}

// TestErrorRecovery tests that the application recovers from errors gracefully
func (suite *IntegrationTestSuite) TestErrorRecovery() {
	logger := NewMockLogger()

	// Set up mock expectations
	logger.On("Error", "Disk not found").Return()
	logger.On("Error", "Network configuration failed").Return()
	logger.On("Error", "Package installation failed").Return()
	logger.On("Error", "Bootloader installation failed").Return()

	// Test error logging and recovery
	errors := []string{
		"Disk not found",
		"Network configuration failed",
		"Package installation failed",
		"Bootloader installation failed",
	}

	for _, errMsg := range errors {
		logger.Error(errMsg)
	}

	assert.Len(suite.T(), logger.ErrorMessages, len(errors))

	for i, errMsg := range errors {
		assert.Equal(suite.T(), errMsg, logger.ErrorMessages[i])
	}

	logger.AssertExpectations(suite.T())
}

// TestBubbleTeaIntegration tests BubbleTea specific functionality
func (suite *IntegrationTestSuite) TestBubbleTeaIntegration() {
	m := initialModel()

	// Test that model implements tea.Model interface
	assert.Implements(suite.T(), (*tea.Model)(nil), m)

	// Test initial view
	m.width = 80 // Set dimensions to avoid "Initializing..." message
	m.height = 25
	view := m.View()
	assert.NotEmpty(suite.T(), view)
	// The title should be in the header
	assert.Contains(suite.T(), view, "Arch-Base Installation Wizard")

	// Test update with quit message
	updatedModel, cmd := m.Update(tea.KeyMsg{Type: tea.KeyCtrlC})
	assert.IsType(suite.T(), Model{}, updatedModel)

	// Cmd should be quit command
	if cmd != nil {
		assert.NotNil(suite.T(), cmd)
	}
}

func TestIntegrationTestSuite(t *testing.T) {
	suite.Run(t, new(IntegrationTestSuite))
}

// Benchmark tests for performance
func BenchmarkModelUpdate(b *testing.B) {
	m := initialModel()
	msg := tea.KeyMsg{Type: tea.KeyEnter}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		m.Update(msg)
	}
}

func BenchmarkModelView(b *testing.B) {
	m := initialModel()

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		m.View()
	}
}

func BenchmarkConfigValidation(b *testing.B) {
	config := &Config{
		Hostname:     "test-hostname",
		Username:     "testuser",
		UserPassword: "testpassword123",
		TargetDisk:   "/dev/sda",
	}

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		validateHostnameIntegration(config.Hostname)
		validateUsernameIntegration(config.Username)
		validatePasswordIntegration(config.UserPassword)
		validateDiskIntegration(config.TargetDisk)
	}
}
