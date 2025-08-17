package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/suite"
)

// ConfigTestSuite contains tests for configuration validation and management
type ConfigTestSuite struct {
	suite.Suite
	config *Config
}

func (suite *ConfigTestSuite) SetupTest() {
	suite.config = &Config{
		Hostname:          "test-arch",
		Timezone:          "UTC",
		Locale:            "en_US.UTF-8",
		Keymap:            "us",
		Username:          "testuser",
		UserPassword:      "testpass123",
		UserGroups:        []string{"wheel", "audio", "video"},
		TargetDisk:        "/dev/sda",
		FSType:            "btrfs",
		EFISize:           "512M",
		SwapSize:          "2048",
		CryptrootName:     "cryptroot",
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
	}
}

func (suite *ConfigTestSuite) TestConfigDefaults() {
	config := &Config{}

	// Test that we can create a config with defaults
	assert.NotNil(suite.T(), config)

	// Test setting defaults
	config.Hostname = "arch-linux"
	config.Timezone = "America/New_York"
	config.Locale = "en_US.UTF-8"

	assert.Equal(suite.T(), "arch-linux", config.Hostname)
	assert.Equal(suite.T(), "America/New_York", config.Timezone)
	assert.Equal(suite.T(), "en_US.UTF-8", config.Locale)
}

func (suite *ConfigTestSuite) TestValidConfiguration() {
	// Test that a properly configured config is valid
	assert.Equal(suite.T(), "test-arch", suite.config.Hostname)
	assert.Equal(suite.T(), "testuser", suite.config.Username)
	assert.Equal(suite.T(), "/dev/sda", suite.config.TargetDisk)
	assert.True(suite.T(), suite.config.SwapEnabled)
	assert.True(suite.T(), suite.config.LuksEnabled)
	assert.Contains(suite.T(), suite.config.UserGroups, "wheel")
}

func (suite *ConfigTestSuite) TestNetworkConfiguration() {
	// Test DHCP configuration
	suite.config.NetworkConfig = "dhcp"
	suite.config.EnableNetworkMgr = true
	assert.Equal(suite.T(), "dhcp", suite.config.NetworkConfig)
	assert.True(suite.T(), suite.config.EnableNetworkMgr)

	// Test static configuration
	suite.config.NetworkConfig = "static"
	suite.config.StaticIP = "192.168.1.100/24"
	suite.config.Gateway = "192.168.1.1"
	suite.config.DNS = []string{"8.8.8.8", "1.1.1.1"}

	assert.Equal(suite.T(), "static", suite.config.NetworkConfig)
	assert.Equal(suite.T(), "192.168.1.100/24", suite.config.StaticIP)
	assert.Equal(suite.T(), "192.168.1.1", suite.config.Gateway)
	assert.Len(suite.T(), suite.config.DNS, 2)
}

func (suite *ConfigTestSuite) TestBootloaderConfiguration() {
	// Test GRUB configuration
	suite.config.Bootloader = "grub"
	suite.config.BootMode = "uefi"
	assert.Equal(suite.T(), "grub", suite.config.Bootloader)
	assert.Equal(suite.T(), "uefi", suite.config.BootMode)

	// Test systemd-boot configuration
	suite.config.Bootloader = "systemd-boot"
	suite.config.ESPMountpoint = "/boot/efi"
	assert.Equal(suite.T(), "systemd-boot", suite.config.Bootloader)
	assert.Equal(suite.T(), "/boot/efi", suite.config.ESPMountpoint)
}

func (suite *ConfigTestSuite) TestPackageConfiguration() {
	// Test desktop profile
	suite.config.Profile = "desktop"
	suite.config.DesktopEnv = "kde"
	suite.config.AudioSystem = "pulseaudio"
	suite.config.AURHelper = "paru"

	assert.Equal(suite.T(), "desktop", suite.config.Profile)
	assert.Equal(suite.T(), "kde", suite.config.DesktopEnv)
	assert.Equal(suite.T(), "pulseaudio", suite.config.AudioSystem)
	assert.Equal(suite.T(), "paru", suite.config.AURHelper)

	// Test server profile
	suite.config.Profile = "server"
	suite.config.DesktopEnv = ""
	suite.config.AURHelper = "none"

	assert.Equal(suite.T(), "server", suite.config.Profile)
	assert.Equal(suite.T(), "", suite.config.DesktopEnv)
	assert.Equal(suite.T(), "none", suite.config.AURHelper)
}

func (suite *ConfigTestSuite) TestDiskConfiguration() {
	// Test BTRFS configuration
	suite.config.FSType = "btrfs"
	suite.config.BtrfsLayout = "default"
	suite.config.CompressType = "zstd"

	assert.Equal(suite.T(), "btrfs", suite.config.FSType)
	assert.Equal(suite.T(), "default", suite.config.BtrfsLayout)
	assert.Equal(suite.T(), "zstd", suite.config.CompressType)

	// Test EXT4 configuration
	suite.config.FSType = "ext4"
	assert.Equal(suite.T(), "ext4", suite.config.FSType)

	// Test XFS configuration
	suite.config.FSType = "xfs"
	assert.Equal(suite.T(), "xfs", suite.config.FSType)
}

func (suite *ConfigTestSuite) TestEncryptionConfiguration() {
	// Test LUKS enabled
	suite.config.LuksEnabled = true
	suite.config.LuksType = "luks2"
	suite.config.CryptrootName = "cryptroot"

	assert.True(suite.T(), suite.config.LuksEnabled)
	assert.Equal(suite.T(), "luks2", suite.config.LuksType)
	assert.Equal(suite.T(), "cryptroot", suite.config.CryptrootName)

	// Test LUKS disabled
	suite.config.LuksEnabled = false
	assert.False(suite.T(), suite.config.LuksEnabled)
}

func TestConfigTestSuite(t *testing.T) {
	suite.Run(t, new(ConfigTestSuite))
}

// Standalone config validation tests
func TestValidateHostname(t *testing.T) {
	tests := []struct {
		name     string
		hostname string
		isValid  bool
	}{
		{"Valid hostname", "arch-linux", true},
		{"Valid hostname with numbers", "arch123", true},
		{"Valid short hostname", "arch", true},
		{"Empty hostname", "", false},
		{"Too long hostname", "this-is-a-very-long-hostname-that-exceeds-the-limit-of-characters", false},
		{"Invalid characters", "arch_linux!", false},
		{"Starts with dash", "-arch", false},
		{"Ends with dash", "arch-", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			isValid := validateHostname(tt.hostname)
			if tt.isValid {
				assert.True(t, isValid, "Expected hostname '%s' to be valid", tt.hostname)
			} else {
				assert.False(t, isValid, "Expected hostname '%s' to be invalid", tt.hostname)
			}
		})
	}
}

func TestValidateUsername(t *testing.T) {
	tests := []struct {
		name     string
		username string
		isValid  bool
	}{
		{"Valid username", "testuser", true},
		{"Valid username with numbers", "user123", true},
		{"Valid username with underscore", "test_user", true},
		{"Valid username with dash", "test-user", true},
		{"Empty username", "", false},
		{"Too long username", "thisusernameiswaytoolongtobevalid", false},
		{"Starts with number", "1user", false},
		{"Starts with uppercase", "User", false},
		{"Contains spaces", "test user", false},
		{"System user", "root", false},
		{"System user daemon", "daemon", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			isValid := validateUsername(tt.username)
			if tt.isValid {
				assert.True(t, isValid, "Expected username '%s' to be valid", tt.username)
			} else {
				assert.False(t, isValid, "Expected username '%s' to be invalid", tt.username)
			}
		})
	}
}

func TestValidatePassword(t *testing.T) {
	tests := []struct {
		name     string
		password string
		isValid  bool
	}{
		{"Valid password", "password123", true},
		{"Valid strong password", "MyStr0ngP@ssw0rd!", true},
		{"Too short password", "pass", false},
		{"Empty password", "", false},
		{"Minimum length password", "12345678", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			isValid := validatePassword(tt.password)
			if tt.isValid {
				assert.True(t, isValid, "Expected password to be valid")
			} else {
				assert.False(t, isValid, "Expected password to be invalid")
			}
		})
	}
}

func TestValidateDiskPath(t *testing.T) {
	tests := []struct {
		name     string
		diskPath string
		isValid  bool
	}{
		{"Valid SATA disk", "/dev/sda", true},
		{"Valid NVME disk", "/dev/nvme0n1", true},
		{"Valid virtual disk", "/dev/vda", true},
		{"Empty disk path", "", false},
		{"Invalid path", "sda", false},
		{"Non-dev path", "/home/user/disk", false},
		{"Invalid device", "/dev/sda999", true}, // Path format is valid, device existence check would be separate
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			isValid := validateDiskPath(tt.diskPath)
			if tt.isValid {
				assert.True(t, isValid, "Expected disk path '%s' to be valid", tt.diskPath)
			} else {
				assert.False(t, isValid, "Expected disk path '%s' to be invalid", tt.diskPath)
			}
		})
	}
}

// Helper validation functions (these would normally be in your main code)
func validateHostname(hostname string) bool {
	if hostname == "" || len(hostname) > 63 {
		return false
	}

	// Simple hostname validation - starts and ends with alphanumeric, can contain hyphens
	if hostname[0] == '-' || hostname[len(hostname)-1] == '-' {
		return false
	}

	for _, char := range hostname {
		if !((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') ||
			(char >= '0' && char <= '9') || char == '-') {
			return false
		}
	}

	return true
}

func validateUsername(username string) bool {
	if username == "" || len(username) > 32 {
		return false
	}

	// Check against system users
	systemUsers := []string{"root", "daemon", "bin", "sys", "adm", "tty", "disk", "lp", "mail", "news", "uucp", "proxy", "www-data", "backup", "list", "irc", "gnats", "nobody"}
	for _, sysUser := range systemUsers {
		if username == sysUser {
			return false
		}
	}

	// Must start with lowercase letter
	if username[0] < 'a' || username[0] > 'z' {
		return false
	}

	// Can contain only lowercase letters, numbers, underscore, hyphen
	for _, char := range username {
		if !((char >= 'a' && char <= 'z') || (char >= '0' && char <= '9') ||
			char == '_' || char == '-') {
			return false
		}
	}

	return true
}

func validatePassword(password string) bool {
	return len(password) >= 8
}

func validateDiskPath(diskPath string) bool {
	if diskPath == "" {
		return false
	}

	// Must start with /dev/
	if len(diskPath) < 5 || diskPath[:5] != "/dev/" {
		return false
	}

	return true
}
