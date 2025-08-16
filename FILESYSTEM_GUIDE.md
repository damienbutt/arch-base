# Filesystem Configuration Guide

The Arch-Base installation system now supports multiple root filesystem types with customizable options for each. This gives you the flexibility to choose the best filesystem for your specific use case.

## Supported Filesystems

### BTRFS (Default)

- **Best for**: Desktop systems, development machines, systems requiring snapshots
- **Features**: Compression, snapshots, subvolumes, self-healing
- **Subvolume layouts**: Default, Minimal, or Custom configurations

### EXT4

- **Best for**: Servers, stable systems, maximum compatibility
- **Features**: Mature, stable, excellent performance
- **Options**: Configurable features and optimizations

### XFS

- **Best for**: High-performance storage, large files, server workloads
- **Features**: Excellent scalability, parallel I/O, large file support
- **Options**: Customizable allocation group settings

## BTRFS Subvolume Layouts

### Default Layout

```
@           -> /       (root filesystem)
@home       -> /home   (user directories)
@snapshots  -> /.snapshots (system snapshots)
@log        -> /var/log     (system logs)
@cache      -> /var/cache   (package cache)
@swap       -> /swap        (swap file location)
```

### Minimal Layout

```
@           -> /       (root filesystem)
@home       -> /home   (user directories)
```

### Custom Layout Options

You can select any combination of:

- `@` - Root filesystem (always included)
- `@home` - User home directories
- `@snapshots` - System snapshots
- `@log` - System logs (/var/log)
- `@cache` - Package cache (/var/cache)
- `@swap` - Swap file location
- `@opt` - Optional software (/opt)
- `@srv` - Service data (/srv)
- `@tmp` - Temporary files (/tmp)

## Interactive Configuration

When using the interactive configuration wizard, you'll be prompted to:

1. **Select Filesystem Type**: Choose between BTRFS, EXT4, or XFS
2. **Configure BTRFS Options** (if selected):
    - Choose subvolume layout (Default/Minimal/Custom)
    - Select compression algorithm (zstd/lzo/zlib/none)
    - Customize subvolume selection

## Configuration File Examples

### BTRFS with Default Layout

```bash
FS_TYPE="btrfs"
COMPRESS_TYPE="zstd"
BTRFS_SUBVOLUME_LAYOUT="default"
BTRFS_CUSTOM_SUBVOLUMES="@,@home,@snapshots,@log,@cache,@swap"
```

### BTRFS with Minimal Layout

```bash
FS_TYPE="btrfs"
COMPRESS_TYPE="zstd"
BTRFS_SUBVOLUME_LAYOUT="minimal"
BTRFS_CUSTOM_SUBVOLUMES="@,@home"
```

### BTRFS with Custom Layout

```bash
FS_TYPE="btrfs"
COMPRESS_TYPE="lzo"
BTRFS_SUBVOLUME_LAYOUT="custom"
BTRFS_CUSTOM_SUBVOLUMES="@,@home,@snapshots,@opt"
```

### EXT4 Configuration

```bash
FS_TYPE="ext4"
EXT4_FEATURES="^64bit,ext_attr,dir_index,filetype,sparse_super,large_file,huge_file,uninit_bg,dir_nlink,extra_isize"
```

### XFS Configuration

```bash
FS_TYPE="xfs"
XFS_OPTIONS="-f -s size=4096 -d agcount=32"
```

## Package Dependencies

The system automatically installs the appropriate filesystem tools based on your selection:

- **BTRFS**: `btrfs-progs` package
- **EXT4**: `e2fsprogs` package (usually included in base)
- **XFS**: `xfsprogs` package

## Swap File Handling

Swap files are created differently depending on the filesystem:

### BTRFS

- Uses dedicated `@swap` subvolume if available
- Applies no-copy-on-write attribute (`chattr +C`)
- Falls back to root filesystem if `@swap` not configured

### EXT4/XFS

- Creates swap file in root filesystem
- Standard swap file creation process

## Performance Considerations

### BTRFS

- **Compression**: Reduces storage space, may increase CPU usage
- **SSD Optimization**: Automatic `ssd` and `discard=async` mount options
- **Subvolumes**: Allow independent snapshots and maintenance

### EXT4

- **SSD Optimization**: Automatic `discard` mount option for SSDs
- **Journaling**: Provides data integrity with minimal overhead
- **Compatibility**: Maximum compatibility across Linux distributions

### XFS

- **Parallel I/O**: Excellent for multi-threaded applications
- **Large Files**: Optimized for files > 1GB
- **Allocation Groups**: Configurable for specific workloads

## Use Case Recommendations

### Desktop/Development Systems

```bash
FS_TYPE="btrfs"
BTRFS_SUBVOLUME_LAYOUT="default"
COMPRESS_TYPE="zstd"
```

- Snapshots before system updates
- Compression saves space
- Separate home directory protection

### Servers/Production

```bash
FS_TYPE="ext4"
# or for high-performance storage:
FS_TYPE="xfs"
XFS_OPTIONS="-f -s size=4096"
```

- Maximum stability and performance
- Proven reliability in production
- Excellent support across tools

### Storage/File Servers

```bash
FS_TYPE="xfs"
XFS_OPTIONS="-f -s size=4096 -d agcount=32"
SWAPFILE_ENABLED="false"  # Use dedicated swap partition
```

- Optimized for large files
- Excellent scalability
- Parallel I/O performance

## Migration and Compatibility

- **From BTRFS**: Snapshots allow easy rollback if needed
- **To Different FS**: Full reinstallation required
- **Backup Strategy**: Consider filesystem-specific backup tools
    - BTRFS: `btrfs send/receive`, snapper
    - EXT4/XFS: Traditional tools (rsync, tar, dd)

This flexible filesystem configuration ensures your Arch-Base installation can be optimized for any use case while maintaining the system's minimal and configurable philosophy.
