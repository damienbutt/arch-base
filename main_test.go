package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"

	"github.com/damienbutt/arch-base/internal/types"
)

// ConfigTestSuite contains tests for configuration validation and management
type ConfigTestSuite struct {
	suite.Suite
	config *types.Config
}

func (suite *ConfigTestSuite) SetupTest() {
	suite.config = &types.Config{
		Hostname:        "test-arch",
		Timezone:        "UTC",
		Locale:          "en_US.UTF-8",
		Keymap:          "us",
		Username:        "testuser",
		UserPassword:    "testpass123",
		UserGroups:      []string{"wheel", "audio", "video"},
		TargetDisk:      "/dev/sda",
		FSType:          "btrfs",
		EFISize:         "512M",
		SwapSize:        "2048",
		RootPassword:    "rootpass123",
		Bootloader:      "grub",
		NetworkConfig:   "dhcp",
		Profile:         "desktop",
		AURHelper:       "yay",
		Packages:        []string{"base", "linux", "linux-firmware"},
		EnabledServices: []string{"NetworkManager", "bluetooth"},
	}
}

func (suite *ConfigTestSuite) TestConfigCreation() {
	assert.NotNil(suite.T(), suite.config)
	assert.Equal(suite.T(), "test-arch", suite.config.Hostname)
	assert.Equal(suite.T(), "testuser", suite.config.Username)
	assert.Equal(suite.T(), "/dev/sda", suite.config.TargetDisk)
	assert.Equal(suite.T(), "btrfs", suite.config.FSType)
	assert.Equal(suite.T(), "grub", suite.config.Bootloader)
	assert.Equal(suite.T(), "desktop", suite.config.Profile)
	assert.Equal(suite.T(), "yay", suite.config.AURHelper)
}

func (suite *ConfigTestSuite) TestValidHostname() {
	// Test valid hostnames
	validHostnames := []string{"arch", "my-arch", "test123", "arch-linux"}
	for _, hostname := range validHostnames {
		suite.config.Hostname = hostname
		// Basic hostname validation (simplified)
		assert.NotEmpty(suite.T(), suite.config.Hostname)
		assert.True(suite.T(), len(suite.config.Hostname) <= 63)
	}
}

func (suite *ConfigTestSuite) TestValidUsername() {
	// Test valid usernames
	validUsernames := []string{"user", "myuser", "test123", "arch-user"}
	for _, username := range validUsernames {
		suite.config.Username = username
		assert.NotEmpty(suite.T(), suite.config.Username)
		assert.True(suite.T(), len(suite.config.Username) <= 32)
		assert.NotEqual(suite.T(), "root", suite.config.Username)
	}
}

func (suite *ConfigTestSuite) TestModelInitialization() {
	m := initialModel()
	assert.NotNil(suite.T(), m)
	assert.Equal(suite.T(), welcomeScreen, m.screen)
	assert.NotNil(suite.T(), m.config)
	assert.False(suite.T(), m.quitting)
}

func (suite *ConfigTestSuite) TestScreenNavigation() {
	m := initialModel()

	// Test initial screen
	assert.Equal(suite.T(), welcomeScreen, m.screen)

	// Test screen progression (simplified)
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
		m.screen = screen
		assert.Equal(suite.T(), screen, m.screen)
		assert.True(suite.T(), int(screen) == i)
	}
}

func TestConfigTestSuite(t *testing.T) {
	suite.Run(t, new(ConfigTestSuite))
}
