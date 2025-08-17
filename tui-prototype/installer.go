package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"
)

// InstallerEngine handles the actual Arch Linux installation
type InstallerEngine struct {
	config *Config
	logger *Logger
}

// Logger provides structured logging for the installation process
type Logger struct {
	logFile *os.File
	verbose bool
}

func NewLogger(logPath string, verbose bool) (*Logger, error) {
	// Create log directory if it doesn't exist
	logDir := filepath.Dir(logPath)
	if err := os.MkdirAll(logDir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create log directory: %v", err)
	}

	logFile, err := os.OpenFile(logPath, os.O_CREATE|os.O_WRONLY|os.O_APPEND, 0644)
	if err != nil {
		return nil, fmt.Errorf("failed to create log file: %v", err)
	}

	return &Logger{
		logFile: logFile,
		verbose: verbose,
	}, nil
}

func (l *Logger) Info(message string) {
	l.log("INFO", message)
	if l.verbose {
		fmt.Printf("ℹ️  %s\n", message)
	}
}

func (l *Logger) Success(message string) {
	l.log("SUCCESS", message)
	fmt.Printf("✅ %s\n", message)
}

func (l *Logger) Warning(message string) {
	l.log("WARNING", message)
	fmt.Printf("⚠️  %s\n", message)
}

func (l *Logger) Error(message string) {
	l.log("ERROR", message)
	fmt.Printf("❌ %s\n", message)
}

func (l *Logger) Fatal(message string) {
	l.log("FATAL", message)
	fmt.Printf("💀 %s\n", message)
	l.Close()
	os.Exit(1)
}

func (l *Logger) log(level, message string) {
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logLine := fmt.Sprintf("[%s] [%s] %s\n", timestamp, level, message)
	l.logFile.WriteString(logLine)
}

func (l *Logger) Close() {
	if l.logFile != nil {
		l.logFile.Close()
	}
}

func NewInstallerEngine(config *Config) *InstallerEngine {
	logger, err := NewLogger("/tmp/arch-base-install/install.log", true)
	if err != nil {
		fmt.Printf("Warning: Could not create logger: %v\n", err)
		logger = &Logger{verbose: true} // Fallback to stdout only
	}

	return &InstallerEngine{
		config: config,
		logger: logger,
	}
}

// RunInstallation performs the complete Arch Linux installation
func (e *InstallerEngine) RunInstallation() error {
	e.logger.Info("Starting Arch-Base installation")
	e.logger.Info(fmt.Sprintf("Target disk: %s", e.config.TargetDisk))
	e.logger.Info(fmt.Sprintf("Hostname: %s", e.config.Hostname))
	e.logger.Info(fmt.Sprintf("Username: %s", e.config.Username))

	// Pre-flight checks
	if err := e.preflightChecks(); err != nil {
		return fmt.Errorf("preflight checks failed: %v", err)
	}

	// Disk preparation
	if err := e.prepareDisk(); err != nil {
		return fmt.Errorf("disk preparation failed: %v", err)
	}

	// Install base system
	if err := e.installBaseSystem(); err != nil {
		return fmt.Errorf("base system installation failed: %v", err)
	}

	// Configure system
	if err := e.configureSystem(); err != nil {
		return fmt.Errorf("system configuration failed: %v", err)
	}

	// Setup user
	if err := e.setupUser(); err != nil {
		return fmt.Errorf("user setup failed: %v", err)
	}

	// Install bootloader
	if err := e.installBootloader(); err != nil {
		return fmt.Errorf("bootloader installation failed: %v", err)
	}

	// Post-installation setup
	if err := e.postInstallation(); err != nil {
		return fmt.Errorf("post-installation setup failed: %v", err)
	}

	e.logger.Success("Arch-Base installation completed successfully!")
	return nil
}

// preflightChecks validates the system and environment
func (e *InstallerEngine) preflightChecks() error {
	e.logger.Info("Performing pre-flight checks...")

	// Check if running as root
	if os.Geteuid() != 0 {
		return fmt.Errorf("installer must be run as root")
	}

	// Check if we're in an Arch Linux environment
	if _, err := os.Stat("/etc/arch-release"); os.IsNotExist(err) {
		return fmt.Errorf("this installer must be run from an Arch Linux environment")
	}

	// Check internet connectivity
	if err := e.runCommand("ping", "-c", "1", "archlinux.org"); err != nil {
		return fmt.Errorf("no internet connectivity")
	}

	// Check if target disk exists
	if _, err := os.Stat(e.config.TargetDisk); os.IsNotExist(err) {
		return fmt.Errorf("target disk %s does not exist", e.config.TargetDisk)
	}

	// Update package database
	e.logger.Info("Updating package database...")
	if err := e.runCommand("pacman", "-Sy", "--noconfirm"); err != nil {
		return fmt.Errorf("failed to update package database: %v", err)
	}

	e.logger.Success("Pre-flight checks completed")
	return nil
}

// prepareDisk handles disk partitioning, encryption, and filesystem creation
func (e *InstallerEngine) prepareDisk() error {
	e.logger.Info("Preparing disk...")

	disk := e.config.TargetDisk

	// Unmount any existing mounts
	e.logger.Info("Unmounting any existing filesystems...")
	e.runCommand("umount", "-R", "/mnt")
	e.runCommand("swapoff", "-a")

	// Wipe the disk
	e.logger.Info(fmt.Sprintf("Wiping disk %s...", disk))
	if err := e.runCommand("wipefs", "-af", disk); err != nil {
		return fmt.Errorf("failed to wipe disk: %v", err)
	}

	// Create partition table
	e.logger.Info("Creating GPT partition table...")
	if err := e.runCommand("parted", "-s", disk, "mklabel", "gpt"); err != nil {
		return fmt.Errorf("failed to create partition table: %v", err)
	}

	// Create EFI partition
	e.logger.Info("Creating EFI partition...")
	if err := e.runCommand("parted", "-s", disk, "mkpart", "primary", "fat32", "1MiB", e.config.EFISize); err != nil {
		return fmt.Errorf("failed to create EFI partition: %v", err)
	}

	// Create root partition
	e.logger.Info("Creating root partition...")
	if err := e.runCommand("parted", "-s", disk, "mkpart", "primary", e.config.EFISize, "100%"); err != nil {
		return fmt.Errorf("failed to create root partition: %v", err)
	}

	// Set EFI partition flag
	if err := e.runCommand("parted", "-s", disk, "set", "1", "esp", "on"); err != nil {
		return fmt.Errorf("failed to set EFI flag: %v", err)
	}

	// Wait for partitions to be created
	time.Sleep(2 * time.Second)

	// Format EFI partition
	efiPartition := disk + "1"
	if strings.Contains(disk, "nvme") {
		efiPartition = disk + "p1"
	}

	e.logger.Info("Formatting EFI partition...")
	if err := e.runCommand("mkfs.fat", "-F32", efiPartition); err != nil {
		return fmt.Errorf("failed to format EFI partition: %v", err)
	}

	// Setup LUKS encryption
	rootPartition := disk + "2"
	if strings.Contains(disk, "nvme") {
		rootPartition = disk + "p2"
	}

	e.logger.Info("Setting up LUKS encryption...")
	if err := e.setupLUKSEncryption(rootPartition); err != nil {
		return fmt.Errorf("LUKS setup failed: %v", err)
	}

	// Create filesystem
	if err := e.createFilesystem(); err != nil {
		return fmt.Errorf("filesystem creation failed: %v", err)
	}

	e.logger.Success("Disk preparation completed")
	return nil
}

// setupLUKSEncryption configures LUKS encryption for the root partition
func (e *InstallerEngine) setupLUKSEncryption(partition string) error {
	e.logger.Info("Configuring LUKS encryption...")

	// Create LUKS container with user password
	fmt.Printf("Setting up LUKS encryption for %s\n", partition)
	fmt.Println("You will be prompted to enter a passphrase for disk encryption.")
	fmt.Print("This passphrase will be required every time you boot the system.\n\n")

	cmd := exec.Command("cryptsetup", "luksFormat", "--type", "luks2", partition)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to create LUKS container: %v", err)
	}

	// Open LUKS container
	fmt.Println("\nNow enter the same passphrase to open the encrypted container:")
	cmd = exec.Command("cryptsetup", "open", partition, e.config.CryptrootName)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to open LUKS container: %v", err)
	}

	return nil
}

// createFilesystem creates and mounts the filesystem
func (e *InstallerEngine) createFilesystem() error {
	cryptDevice := "/dev/mapper/" + e.config.CryptrootName

	e.logger.Info(fmt.Sprintf("Creating %s filesystem...", e.config.FSType))

	switch e.config.FSType {
	case "btrfs":
		if err := e.runCommand("mkfs.btrfs", "-f", cryptDevice); err != nil {
			return fmt.Errorf("failed to create btrfs filesystem: %v", err)
		}
		return e.setupBtrfsSubvolumes(cryptDevice)

	case "ext4":
		return e.runCommand("mkfs.ext4", "-F", cryptDevice)

	case "xfs":
		return e.runCommand("mkfs.xfs", "-f", cryptDevice)

	default:
		return fmt.Errorf("unsupported filesystem type: %s", e.config.FSType)
	}
}

// setupBtrfsSubvolumes creates and mounts BTRFS subvolumes
func (e *InstallerEngine) setupBtrfsSubvolumes(device string) error {
	e.logger.Info("Setting up BTRFS subvolumes...")

	// Mount root temporarily
	if err := e.runCommand("mount", device, "/mnt"); err != nil {
		return fmt.Errorf("failed to mount root: %v", err)
	}

	// Create subvolumes
	subvolumes := []string{"@", "@home", "@log", "@cache", "@snapshots"}
	if e.config.SwapEnabled {
		subvolumes = append(subvolumes, "@swap")
	}

	for _, subvol := range subvolumes {
		e.logger.Info(fmt.Sprintf("Creating subvolume %s", subvol))
		if err := e.runCommand("btrfs", "subvolume", "create", "/mnt/"+subvol); err != nil {
			return fmt.Errorf("failed to create subvolume %s: %v", subvol, err)
		}
	}

	// Unmount root
	if err := e.runCommand("umount", "/mnt"); err != nil {
		return fmt.Errorf("failed to unmount root: %v", err)
	}

	// Mount subvolumes
	mountOptions := "defaults,noatime,compress=zstd,commit=120"

	// Mount root subvolume
	if err := e.runCommand("mount", "-o", mountOptions+",subvol=@", device, "/mnt"); err != nil {
		return fmt.Errorf("failed to mount root subvolume: %v", err)
	}

	// Create mount points and mount other subvolumes
	mountPoints := map[string]string{
		"@home":      "/mnt/home",
		"@log":       "/mnt/var/log",
		"@cache":     "/mnt/var/cache",
		"@snapshots": "/mnt/.snapshots",
	}

	if e.config.SwapEnabled {
		mountPoints["@swap"] = "/mnt/swap"
	}

	for subvol, mountPoint := range mountPoints {
		if err := os.MkdirAll(mountPoint, 0755); err != nil {
			return fmt.Errorf("failed to create mount point %s: %v", mountPoint, err)
		}

		if err := e.runCommand("mount", "-o", mountOptions+",subvol="+subvol, device, mountPoint); err != nil {
			return fmt.Errorf("failed to mount subvolume %s: %v", subvol, err)
		}
	}

	return nil
}

// installBaseSystem installs the base Arch Linux system
func (e *InstallerEngine) installBaseSystem() error {
	e.logger.Info("Installing base system...")

	// Mount EFI partition
	if err := os.MkdirAll("/mnt/boot", 0755); err != nil {
		return fmt.Errorf("failed to create boot directory: %v", err)
	}

	efiPartition := e.config.TargetDisk + "1"
	if strings.Contains(e.config.TargetDisk, "nvme") {
		efiPartition = e.config.TargetDisk + "p1"
	}

	if err := e.runCommand("mount", efiPartition, "/mnt/boot"); err != nil {
		return fmt.Errorf("failed to mount EFI partition: %v", err)
	}

	// Install essential packages
	basePackages := []string{
		"base", "base-devel", "linux", "linux-firmware",
		"grub", "efibootmgr", "cryptsetup", "btrfs-progs",
		"networkmanager", "sudo", "vim", "git",
	}

	// Add user-selected packages
	allPackages := append(basePackages, e.config.Packages...)
	args := append([]string{"-S", "--noconfirm"}, allPackages...)

	e.logger.Info("Installing packages with pacstrap...")
	if err := e.runCommand("pacstrap", append([]string{"/mnt"}, args...)...); err != nil {
		return fmt.Errorf("pacstrap failed: %v", err)
	}

	// Generate fstab
	e.logger.Info("Generating fstab...")
	cmd := exec.Command("genfstab", "-U", "/mnt")
	output, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to generate fstab: %v", err)
	}

	fstabPath := "/mnt/etc/fstab"
	if err := os.WriteFile(fstabPath, output, 0644); err != nil {
		return fmt.Errorf("failed to write fstab: %v", err)
	}

	e.logger.Success("Base system installation completed")
	return nil
}

// configureSystem configures basic system settings
func (e *InstallerEngine) configureSystem() error {
	e.logger.Info("Configuring system...")

	// Set timezone
	e.logger.Info(fmt.Sprintf("Setting timezone to %s", e.config.Timezone))
	if err := e.archChroot("ln", "-sf", "/usr/share/zoneinfo/"+e.config.Timezone, "/etc/localtime"); err != nil {
		return fmt.Errorf("failed to set timezone: %v", err)
	}

	if err := e.archChroot("hwclock", "--systohc"); err != nil {
		return fmt.Errorf("failed to set hardware clock: %v", err)
	}

	// Configure locale
	e.logger.Info(fmt.Sprintf("Configuring locale %s", e.config.Locale))
	localeGen := "/mnt/etc/locale.gen"
	content, err := os.ReadFile(localeGen)
	if err != nil {
		return fmt.Errorf("failed to read locale.gen: %v", err)
	}

	// Uncomment the desired locale
	localePattern := regexp.MustCompile(`^#` + regexp.QuoteMeta(e.config.Locale))
	newContent := localePattern.ReplaceAllString(string(content), e.config.Locale)

	if err := os.WriteFile(localeGen, []byte(newContent), 0644); err != nil {
		return fmt.Errorf("failed to write locale.gen: %v", err)
	}

	if err := e.archChroot("locale-gen"); err != nil {
		return fmt.Errorf("failed to generate locale: %v", err)
	}

	// Set locale.conf
	localeConf := fmt.Sprintf("LANG=%s\n", e.config.Locale)
	if err := os.WriteFile("/mnt/etc/locale.conf", []byte(localeConf), 0644); err != nil {
		return fmt.Errorf("failed to write locale.conf: %v", err)
	}

	// Set keymap
	e.logger.Info(fmt.Sprintf("Setting keymap to %s", e.config.Keymap))
	vconsoleConf := fmt.Sprintf("KEYMAP=%s\n", e.config.Keymap)
	if err := os.WriteFile("/mnt/etc/vconsole.conf", []byte(vconsoleConf), 0644); err != nil {
		return fmt.Errorf("failed to write vconsole.conf: %v", err)
	}

	// Set hostname
	e.logger.Info(fmt.Sprintf("Setting hostname to %s", e.config.Hostname))
	if err := os.WriteFile("/mnt/etc/hostname", []byte(e.config.Hostname+"\n"), 0644); err != nil {
		return fmt.Errorf("failed to write hostname: %v", err)
	}

	// Configure hosts file
	hostsContent := fmt.Sprintf(`127.0.0.1	localhost
::1		localhost
127.0.1.1	%s.localdomain	%s
`, e.config.Hostname, e.config.Hostname)
	if err := os.WriteFile("/mnt/etc/hosts", []byte(hostsContent), 0644); err != nil {
		return fmt.Errorf("failed to write hosts file: %v", err)
	}

	e.logger.Success("System configuration completed")
	return nil
}

// setupUser creates and configures the user account
func (e *InstallerEngine) setupUser() error {
	e.logger.Info("Setting up user account...")

	// Set root password
	fmt.Println("\nSetting root password:")
	if err := e.archChrootInteractive("passwd"); err != nil {
		return fmt.Errorf("failed to set root password: %v", err)
	}

	// Create user
	e.logger.Info(fmt.Sprintf("Creating user %s", e.config.Username))
	if err := e.archChroot("useradd", "-m", "-G", strings.Join(e.config.UserGroups, ","), e.config.Username); err != nil {
		return fmt.Errorf("failed to create user: %v", err)
	}

	// Set user password
	fmt.Printf("\nSetting password for user %s:\n", e.config.Username)
	if err := e.archChrootInteractive("passwd", e.config.Username); err != nil {
		return fmt.Errorf("failed to set user password: %v", err)
	}

	// Configure sudo
	sudoersLine := fmt.Sprintf("%%wheel ALL=(ALL:ALL) ALL\n")
	sudoersPath := "/mnt/etc/sudoers.d/wheel"
	if err := os.WriteFile(sudoersPath, []byte(sudoersLine), 0440); err != nil {
		return fmt.Errorf("failed to configure sudo: %v", err)
	}

	e.logger.Success("User setup completed")
	return nil
}

// installBootloader installs and configures GRUB
func (e *InstallerEngine) installBootloader() error {
	e.logger.Info("Installing GRUB bootloader...")

	// Install GRUB for EFI
	if err := e.archChroot("grub-install", "--target=x86_64-efi", "--efi-directory=/boot", "--bootloader-id=GRUB"); err != nil {
		return fmt.Errorf("GRUB installation failed: %v", err)
	}

	// Configure GRUB for LUKS
	grubDefault := "/mnt/etc/default/grub"
	content, err := os.ReadFile(grubDefault)
	if err != nil {
		return fmt.Errorf("failed to read GRUB config: %v", err)
	}

	// Get LUKS UUID
	rootPartition := e.config.TargetDisk + "2"
	if strings.Contains(e.config.TargetDisk, "nvme") {
		rootPartition = e.config.TargetDisk + "p2"
	}

	cmd := exec.Command("blkid", "-s", "UUID", "-o", "value", rootPartition)
	uuidBytes, err := cmd.Output()
	if err != nil {
		return fmt.Errorf("failed to get LUKS UUID: %v", err)
	}
	uuid := strings.TrimSpace(string(uuidBytes))

	// Update GRUB configuration
	cryptdevice := fmt.Sprintf("cryptdevice=UUID=%s:%s", uuid, e.config.CryptrootName)
	cmdlineLinux := fmt.Sprintf(`GRUB_CMDLINE_LINUX="%s root=/dev/mapper/%s"`, cryptdevice, e.config.CryptrootName)

	// Replace or add the GRUB_CMDLINE_LINUX line
	lines := strings.Split(string(content), "\n")
	found := false
	for i, line := range lines {
		if strings.HasPrefix(line, "GRUB_CMDLINE_LINUX=") {
			lines[i] = cmdlineLinux
			found = true
			break
		}
	}
	if !found {
		lines = append(lines, cmdlineLinux)
	}

	newContent := strings.Join(lines, "\n")
	if err := os.WriteFile(grubDefault, []byte(newContent), 0644); err != nil {
		return fmt.Errorf("failed to update GRUB config: %v", err)
	}

	// Configure mkinitcpio for encryption
	mkinitcpioConf := "/mnt/etc/mkinitcpio.conf"
	content, err = os.ReadFile(mkinitcpioConf)
	if err != nil {
		return fmt.Errorf("failed to read mkinitcpio.conf: %v", err)
	}

	// Update HOOKS line to include encrypt
	lines = strings.Split(string(content), "\n")
	for i, line := range lines {
		if strings.HasPrefix(line, "HOOKS=") && !strings.Contains(line, "encrypt") {
			// Add encrypt hook before filesystems
			line = strings.Replace(line, "filesystems", "encrypt filesystems", 1)
			lines[i] = line
			break
		}
	}

	newContent = strings.Join(lines, "\n")
	if err := os.WriteFile(mkinitcpioConf, []byte(newContent), 0644); err != nil {
		return fmt.Errorf("failed to update mkinitcpio.conf: %v", err)
	}

	// Regenerate initramfs
	if err := e.archChroot("mkinitcpio", "-P"); err != nil {
		return fmt.Errorf("failed to regenerate initramfs: %v", err)
	}

	// Generate GRUB configuration
	if err := e.archChroot("grub-mkconfig", "-o", "/boot/grub/grub.cfg"); err != nil {
		return fmt.Errorf("failed to generate GRUB config: %v", err)
	}

	e.logger.Success("Bootloader installation completed")
	return nil
}

// postInstallation performs final system configuration
func (e *InstallerEngine) postInstallation() error {
	e.logger.Info("Performing post-installation setup...")

	// Enable NetworkManager
	if err := e.archChroot("systemctl", "enable", "NetworkManager"); err != nil {
		e.logger.Warning("Failed to enable NetworkManager")
	}

	// Create swap file if enabled
	if e.config.SwapEnabled {
		if err := e.createSwapFile(); err != nil {
			e.logger.Warning(fmt.Sprintf("Failed to create swap file: %v", err))
		}
	}

	// Install AUR helper if requested
	if e.config.Profile != "minimal" && e.config.AURHelper != "none" {
		if err := e.installAURHelper(); err != nil {
			e.logger.Warning(fmt.Sprintf("Failed to install AUR helper: %v", err))
		}
	}

	e.logger.Success("Post-installation setup completed")
	return nil
}

// createSwapFile creates and enables a swap file
func (e *InstallerEngine) createSwapFile() error {
	e.logger.Info("Creating swap file...")

	swapSize, err := strconv.Atoi(e.config.SwapSize)
	if err != nil {
		return fmt.Errorf("invalid swap size: %v", err)
	}

	// Create swap directory if using BTRFS
	if e.config.FSType == "btrfs" {
		if err := e.archChroot("mkdir", "-p", "/swap"); err != nil {
			return fmt.Errorf("failed to create swap directory: %v", err)
		}

		// Create swap file
		if err := e.archChroot("truncate", "-s", "0", "/swap/swapfile"); err != nil {
			return fmt.Errorf("failed to create swap file: %v", err)
		}

		if err := e.archChroot("chattr", "+C", "/swap/swapfile"); err != nil {
			return fmt.Errorf("failed to set swap file attributes: %v", err)
		}

		if err := e.archChroot("dd", "if=/dev/zero", "of=/swap/swapfile", fmt.Sprintf("bs=1M", "count=%d", swapSize)); err != nil {
			return fmt.Errorf("failed to allocate swap file: %v", err)
		}
	} else {
		// Standard swap file creation
		if err := e.archChroot("dd", "if=/dev/zero", "of=/swapfile", fmt.Sprintf("bs=1M", "count=%d", swapSize)); err != nil {
			return fmt.Errorf("failed to create swap file: %v", err)
		}
	}

	// Set permissions and enable swap
	swapPath := "/swapfile"
	if e.config.FSType == "btrfs" {
		swapPath = "/swap/swapfile"
	}

	if err := e.archChroot("chmod", "600", swapPath); err != nil {
		return fmt.Errorf("failed to set swap file permissions: %v", err)
	}

	if err := e.archChroot("mkswap", swapPath); err != nil {
		return fmt.Errorf("failed to make swap: %v", err)
	}

	// Add to fstab
	fstabEntry := fmt.Sprintf("%s none swap defaults 0 0\n", swapPath)
	fstabFile, err := os.OpenFile("/mnt/etc/fstab", os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		return fmt.Errorf("failed to open fstab: %v", err)
	}
	defer fstabFile.Close()

	if _, err := fstabFile.WriteString(fstabEntry); err != nil {
		return fmt.Errorf("failed to write swap entry to fstab: %v", err)
	}

	return nil
}

// installAURHelper installs Paru AUR helper
func (e *InstallerEngine) installAURHelper() error {
	e.logger.Info("Installing Paru AUR helper...")

	// This would require running as the user, so we'll create a script for first boot
	installScript := fmt.Sprintf(`#!/bin/bash
# Install Paru AUR helper
cd /tmp
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si --noconfirm
cd /
rm -rf /tmp/paru
`)

	scriptPath := "/mnt/home/" + e.config.Username + "/install-paru.sh"
	if err := os.WriteFile(scriptPath, []byte(installScript), 0755); err != nil {
		return fmt.Errorf("failed to create AUR helper install script: %v", err)
	}

	// Change ownership to user
	if err := e.archChroot("chown", e.config.Username+":"+e.config.Username, "/home/"+e.config.Username+"/install-paru.sh"); err != nil {
		e.logger.Warning("Failed to change ownership of install script")
	}

	return nil
}

// Helper functions

func (e *InstallerEngine) runCommand(name string, args ...string) error {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	e.logger.Info(fmt.Sprintf("Running: %s %s", name, strings.Join(args, " ")))
	return cmd.Run()
}

func (e *InstallerEngine) archChroot(args ...string) error {
	fullArgs := append([]string{"/mnt"}, args...)
	return e.runCommand("arch-chroot", fullArgs...)
}

func (e *InstallerEngine) archChrootInteractive(args ...string) error {
	fullArgs := append([]string{"/mnt"}, args...)
	cmd := exec.Command("arch-chroot", fullArgs...)
	cmd.Stdin = os.Stdin
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	e.logger.Info(fmt.Sprintf("Running interactively: arch-chroot %s", strings.Join(fullArgs, " ")))
	return cmd.Run()
}
