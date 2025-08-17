package types

// Configuration structure that matches archinstall functionality
type Config struct {
	// System configuration
	Hostname   string
	Timezone   string
	Locale     string
	Keymap     string
	Region     string
	NTPEnabled bool

	// Boot configuration
	BootMode      string // "uefi" or "bios"
	Bootloader    string // "grub", "systemd-boot", "refind"
	ESPMountpoint string // ESP mount point for UEFI

	// User configuration
	Username     string
	UserGroups   []string
	UserPassword string
	RootPassword string
	EnableSudo   bool

	// Disk configuration
	TargetDisk      string
	PartitionScheme string // "auto", "manual"
	EFISize         string
	RootSize        string
	HomeSize        string
	SwapSize        string
	CryptrootName   string
	FSType          string // "ext4", "btrfs", "xfs"
	BtrfsLayout     string
	CompressType    string
	SwapEnabled     bool
	LuksEnabled     bool
	LuksType        string

	// Network configuration
	NetworkConfig    string // "dhcp", "static", "none"
	StaticIP         string
	Gateway          string
	DNS              []string
	EnableNetworkMgr bool

	// Mirrors and repositories
	MirrorRegion      string
	CustomMirrors     []string
	TestMirrors       bool
	ParallelDownloads int

	// Package configuration
	Profile    string // "desktop", "minimal", "server"
	DesktopEnv string // "gnome", "kde", "xfce", etc.
	Packages   []string
	AURHelper  string // "yay", "paru", "none"
	Microcode  string // "intel", "amd", "none"

	// Audio configuration
	AudioSystem   string // "pulseaudio", "pipewire", "alsa"
	AudioPackages []string

	// Services configuration
	EnabledServices  []string
	DisabledServices []string

	// Security configuration
	FirewallEnabled bool
	SELinuxEnabled  bool
	FailBanEnabled  bool

	// Installation behavior
	AutoReboot        bool
	SkipNonFree       bool
	DryRun            bool
	VerboseLogging    bool
	PostInstallScript string
}
