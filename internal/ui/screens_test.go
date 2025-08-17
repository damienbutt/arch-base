package ui

import (
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/damienbutt/arch-base/internal/types"
)

// TestUIModels tests basic UI model creation
func TestUIModels(t *testing.T) {
	config := &types.Config{
		Hostname: "test-arch",
		Username: "testuser",
	}

	// Test that we can create models with the config
	assert.NotNil(t, config)
	assert.Equal(t, "test-arch", config.Hostname)
	assert.Equal(t, "testuser", config.Username)

	// Basic model tests (simplified)
	welcomeModel := NewWelcomeModel()
	assert.NotNil(t, welcomeModel)

	networkModel := NewNetworkModel(config)
	assert.NotNil(t, networkModel)

	mirrorModel := NewMirrorModel(config)
	assert.NotNil(t, mirrorModel)

	diskModel := NewDiskModel(config)
	assert.NotNil(t, diskModel)

	userModel := NewUserModel(config)
	assert.NotNil(t, userModel)

	bootloaderModel := NewBootloaderModel(config)
	assert.NotNil(t, bootloaderModel)

	profileModel := NewProfileModel(config)
	assert.NotNil(t, profileModel)

	summaryModel := NewSummaryModel(config)
	assert.NotNil(t, summaryModel)

	installModel := NewInstallModel(config)
	assert.NotNil(t, installModel)
}

// TestInstallModel tests the install model state
func TestInstallModel(t *testing.T) {
	config := &types.Config{
		Hostname: "test-arch",
	}

	model := NewInstallModel(config)
	assert.NotNil(t, model)
	assert.False(t, model.Installing)
	assert.False(t, model.Completed)
	assert.Empty(t, model.Progress)
}

// TestSummaryModel tests the summary model
func TestSummaryModel(t *testing.T) {
	config := &types.Config{
		Hostname: "test-arch",
	}

	model := NewSummaryModel(config)
	assert.NotNil(t, model)
	assert.False(t, model.ShouldGenerate)
}
