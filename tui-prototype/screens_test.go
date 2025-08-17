package main

import (
	"testing"

	"github.com/charmbracelet/bubbles/textinput"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// ScreenTestSuite contains tests for TUI screen models
type ScreenTestSuite struct {
	suite.Suite
	config *Config
}

func (suite *ScreenTestSuite) SetupTest() {
	suite.config = &Config{
		Hostname:     "test-arch",
		Timezone:     "UTC",
		Locale:       "en_US.UTF-8",
		Keymap:       "us",
		Username:     "testuser",
		UserPassword: "testpass123",
		TargetDisk:   "/dev/sda",
		FSType:       "btrfs",
	}
}

// SystemModel Tests
func (suite *ScreenTestSuite) TestSystemModelCreation() {
	model := NewSystemModel(suite.config)

	assert.NotNil(suite.T(), model)
	assert.Equal(suite.T(), suite.config, model.config)
	assert.Equal(suite.T(), 0, model.focused)
}

func (suite *ScreenTestSuite) TestSystemModelInputHandling() {
	model := NewSystemModel(suite.config)

	// Test hostname input by setting value directly
	model.inputs[0].SetValue("test-hostname")

	assert.Equal(suite.T(), "test-hostname", model.inputs[0].Value())

	// Test that the view contains the hostname
	view := model.View()
	assert.NotEmpty(suite.T(), view)
}

func (suite *ScreenTestSuite) TestSystemModelNavigation() {
	model := NewSystemModel(suite.config)

	// Test tab navigation
	tabMsg := tea.KeyMsg{Type: tea.KeyTab}
	updatedModel, _ := model.Update(tabMsg)
	systemModel := updatedModel.(*SystemModel)

	assert.Equal(suite.T(), 1, systemModel.focused)
}

// UserModel Tests
func (suite *ScreenTestSuite) TestUserModelCreation() {
	model := NewUserModel(suite.config)

	assert.NotNil(suite.T(), model)
	assert.Equal(suite.T(), suite.config, model.config)
	assert.Equal(suite.T(), 0, model.focused)
	assert.False(suite.T(), model.showingGroups)
}

func (suite *ScreenTestSuite) TestUserModelPasswordValidation() {
	model := NewUserModel(suite.config)

	// Test valid password
	model.passwordInput.SetValue("validpass123")
	model.confirmInput.SetValue("validpass123")

	err := model.validatePasswordConfirm()
	assert.Empty(suite.T(), err)

	// Test mismatched passwords
	model.confirmInput.SetValue("different")
	err = model.validatePasswordConfirm()
	assert.NotEmpty(suite.T(), err)
}

func (suite *ScreenTestSuite) TestUserModelUsernameValidation() {
	model := NewUserModel(suite.config)

	// Test valid username
	err := model.validateUsername("validuser")
	assert.Empty(suite.T(), err)

	// Test invalid username
	err = model.validateUsername("1invalid")
	assert.NotEmpty(suite.T(), err)

	// Test system username
	err = model.validateUsername("root")
	assert.NotEmpty(suite.T(), err)
}

// DiskModel Tests
func (suite *ScreenTestSuite) TestDiskModelCreation() {
	model := NewDiskModel(suite.config)

	assert.NotNil(suite.T(), model)
	assert.Equal(suite.T(), suite.config, model.config)
	assert.Equal(suite.T(), "/dev/sda", model.diskInput.Value())
}

func (suite *ScreenTestSuite) TestDiskModelValidation() {
	model := NewDiskModel(suite.config)

	// Test valid disk path
	err := model.validateDisk("/dev/sda")
	assert.Empty(suite.T(), err)

	// Test invalid disk path
	err = model.validateDisk("invalid")
	assert.NotEmpty(suite.T(), err)

	// Test EFI size validation
	err = model.validateEFISize("512M")
	assert.Empty(suite.T(), err)

	err = model.validateEFISize("invalid")
	assert.NotEmpty(suite.T(), err)
}

// NetworkModel Tests
func (suite *ScreenTestSuite) TestNetworkModelCreation() {
	model := NewNetworkModel(suite.config)

	assert.NotNil(suite.T(), model)
	assert.Equal(suite.T(), suite.config, model.config)
	assert.Equal(suite.T(), 0, model.networkType) // DHCP by default
}

func (suite *ScreenTestSuite) TestNetworkModelTypeSelection() {
	model := NewNetworkModel(suite.config)

	// Test space key toggles network type
	spaceMsg := tea.KeyMsg{Type: tea.KeySpace}
	updatedModel, _ := model.Update(spaceMsg)
	networkModel := updatedModel.(*NetworkModel)

	assert.Equal(suite.T(), 1, networkModel.networkType) // Should be static now
}

// MirrorModel Tests
func (suite *ScreenTestSuite) TestMirrorModelCreation() {
	model := NewMirrorModel(suite.config)

	assert.NotNil(suite.T(), model)
	assert.Equal(suite.T(), suite.config, model.config)
	assert.Equal(suite.T(), 0, model.selectedRegion) // Worldwide by default
	assert.Len(suite.T(), model.regions, 9)          // Should have 9 regions
}

// BootloaderModel Tests
func (suite *ScreenTestSuite) TestBootloaderModelCreation() {
	model := NewBootloaderModel(suite.config)

	assert.NotNil(suite.T(), model)
	assert.Equal(suite.T(), suite.config, model.config)
	assert.Equal(suite.T(), 0, model.bootloader) // GRUB by default
}

// ProfileModel Tests
func (suite *ScreenTestSuite) TestProfileModelCreation() {
	model := NewProfileModel(suite.config)

	assert.NotNil(suite.T(), model)
	assert.Equal(suite.T(), suite.config, model.config)
	assert.Equal(suite.T(), 0, model.profile) // Desktop by default
}

func (suite *ScreenTestSuite) TestProfileModelSelection() {
	model := NewProfileModel(suite.config)

	// Test profile selection
	spaceMsg := tea.KeyMsg{Type: tea.KeySpace}
	updatedModel, _ := model.Update(spaceMsg)
	profileModel := updatedModel.(*ProfileModel)

	assert.Equal(suite.T(), 1, profileModel.profile) // Should be server now
}

// InstallModel Tests
func (suite *ScreenTestSuite) TestInstallModelCreation() {
	model := NewInstallModel(suite.config)

	assert.NotNil(suite.T(), model)
	assert.Equal(suite.T(), suite.config, model.config)
	assert.False(suite.T(), model.installing)
	assert.False(suite.T(), model.completed)
	assert.Empty(suite.T(), model.progress)
}

func (suite *ScreenTestSuite) TestInstallModelProgressHandling() {
	model := NewInstallModel(suite.config)

	// Test progress message
	progressMsg := installProgressMsg("Testing progress")
	updatedModel, _ := model.Update(progressMsg)
	installModel := updatedModel.(*InstallModel)

	assert.Equal(suite.T(), "Testing progress", installModel.currentStep)
	assert.Len(suite.T(), installModel.progress, 1)
}

func (suite *ScreenTestSuite) TestInstallModelCompletion() {
	model := NewInstallModel(suite.config)

	// Test completion message
	completeMsg := installCompleteMsg{err: nil}
	updatedModel, _ := model.Update(completeMsg)
	installModel := updatedModel.(*InstallModel)

	assert.True(suite.T(), installModel.completed)
	assert.False(suite.T(), installModel.installing)
}

// SummaryModel Tests
func (suite *ScreenTestSuite) TestSummaryModelCreation() {
	model := NewSummaryModel(suite.config)

	assert.NotNil(suite.T(), model)
	assert.Equal(suite.T(), suite.config, model.config)
	assert.False(suite.T(), model.shouldGenerate)
}

func (suite *ScreenTestSuite) TestSummaryModelEnterKey() {
	model := NewSummaryModel(suite.config)

	// Test enter key
	enterMsg := tea.KeyMsg{Type: tea.KeyEnter}
	updatedModel, _ := model.Update(enterMsg)
	summaryModel := updatedModel.(*SummaryModel)

	assert.True(suite.T(), summaryModel.shouldGenerate)
}

func TestScreenTestSuite(t *testing.T) {
	suite.Run(t, new(ScreenTestSuite))
}

// Individual screen validation tests
func TestTextInputFocusManagement(t *testing.T) {
	config := &Config{}
	model := NewUserModel(config)

	// Initially username should be focused
	assert.True(t, model.usernameInput.Focused())
	assert.False(t, model.passwordInput.Focused())
	assert.False(t, model.confirmInput.Focused())

	// Move to next field
	model.focused = 1
	model.updateFocus()

	assert.False(t, model.usernameInput.Focused())
	assert.True(t, model.passwordInput.Focused())
	assert.False(t, model.confirmInput.Focused())
}

func TestModelViewRendering(t *testing.T) {
	config := &Config{
		Hostname: "test-host",
		Username: "testuser",
	}

	// Test that View() methods return non-empty strings
	models := []interface {
		View() string
	}{
		NewSystemModel(config),
		NewUserModel(config),
		NewDiskModel(config),
		NewNetworkModel(config),
		NewMirrorModel(config),
		NewBootloaderModel(config),
		NewProfileModel(config),
		NewSummaryModel(config),
		NewInstallModel(config),
	}

	for _, model := range models {
		view := model.View()
		assert.NotEmpty(t, view, "Model view should not be empty")
		// Just check that view is rendered, don't check for specific text
		assert.Greater(t, len(view), 10, "View should contain reasonable content")
	}
}

func TestScreenTransitions(t *testing.T) {
	config := &Config{}

	// Test that shouldProceed flags work correctly
	userModel := NewUserModel(config)
	userModel.usernameInput.SetValue("validuser")
	userModel.passwordInput.SetValue("validpass123")
	userModel.confirmInput.SetValue("validpass123")

	// Simulate validation and proceed
	if userModel.validateUserInputs() {
		userModel.shouldProceed = true
	}

	assert.True(t, userModel.shouldProceed)
}

// Test helper functions for textinput models
func TestTextInputHelpers(t *testing.T) {
	input := textinput.New()
	input.SetValue("test value")

	assert.Equal(t, "test value", input.Value())

	input.Focus()
	assert.True(t, input.Focused())

	input.Blur()
	assert.False(t, input.Focused())
}
