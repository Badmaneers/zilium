# User Guide

Complete guide for using Zilium Super Compactor to build Android super partition images.

## Table of Contents

1. [Introduction](#introduction)
2. [Before You Start](#before-you-start)
3. [GUI Usage](#gui-usage)
4. [CLI Usage](#cli-usage)
5. [Configuration Files](#configuration-files)
6. [Common Workflows](#common-workflows)
7. [Tips and Best Practices](#tips-and-best-practices)
8. [Flashing](#flashing)

---

## Introduction

Zilium Super Compactor rebuilds Android super partition images with optimized sizes while maintaining compatibility with stock VBMeta. This is essential when:

- Building custom ROMs
- Modifying stock firmware
- Creating GSI (Generic System Image)
- Repackaging OTA updates
- Porting ROMs between devices

---

## Before You Start

### What You Need

1. **Extracted ROM Files**
   - Individual partition images (system.img, vendor.img, etc.)
   - Configuration JSON file (usually in META folder)
   - Enough disk space (2-3x the total partition size)

2. **Basic Knowledge**
   - Understanding of Android partition structure
   - Familiarity with fastboot/recovery flashing
   - **Always backup your device before flashing!**

### Understanding Super Partitions

Modern Android devices (Android 10+) use **dynamic partitions**:

```
Traditional Layout:              Dynamic Layout (Super):
┌───────────────┐               ┌────────────────────────┐
│ system.img    │               │                        │
├───────────────┤               │    super.img           │
│ vendor.img    │               │  ┌──────────────────┐  │
├───────────────┤      ===>     │  │ system           │  │
│ product.img   │               │  ├──────────────────┤  │
├───────────────┤               │  │ vendor           │  │
│ odm.img       │               │  ├──────────────────┤  │
└───────────────┘               │  │ product          │  │
                                │  ├──────────────────┤  │
                                │  │ odm              │  │
                                │  └──────────────────┘  │
                                └────────────────────────┘
```

---

## GUI Usage

### Step 1: Launch the Application

```bash
# From build directory
./build/gui/zilium-gui

# If installed system-wide
zilium-gui
```

### Step 2: Select Configuration File

1. Click **Browse...** button next to "Select .json file"
2. Navigate to your ROM directory
3. Common locations:
   - `ROM_NAME/META/super_config.json`
   - `extracted/dynamic_partitions_op_list`
   - `config/lpmake_config.json`
4. Select the JSON file and click **Open**

The GUI will automatically:
- Parse the configuration
- Validate partition paths
- Display super partition info
- Show all partitions in the table

### Step 3: Select Output Directory

1. Click **Browse...** button next to "Select Output folder"
2. Choose where to save the compiled super.img
3. Ensure you have enough free space (check "Super Info" tab)

### Step 4: Review Configuration

#### Super Info Tab
- **Device Slot Type**: A/B or Non-A/B (A-only)
- **Block Size**: Usually 4096 bytes
- **Total Size**: Current super partition size
- **Max Super Size**: Maximum allowed size
- **Partition Count**: Number of partitions to include

#### Partitions Tab
View all partitions with:
- **Enabled checkbox**: Toggle to include/exclude partition
- **Name**: Partition name (e.g., system_a)
- **Size**: Declared size from config
- **Path**: Location of partition image file

**To exclude a partition**:
- Uncheck the box next to its name
- Useful for removing unwanted partitions

**To change partition image path**:
- Click the path field
- Type new path or click **Browse...** button

### Step 5: Validate Configuration

Before building, check the **Validation Status** section:

- **✓ Valid**: Configuration is good, ready to build
- **⚠ Warnings**: Build will succeed but check warnings
- **✗ Errors**: Must fix before building

Common issues:
- Missing partition image files
- Incorrect file sizes
- Path permission problems

### Step 6: Start Building

1. Review validation status
2. Click **▶ Start** button
3. Monitor progress:
   - Console log shows detailed output
   - Progress bar indicates completion
   - Status shows current operation

The build process:
1. Validates all inputs
2. Calculates optimal super size
3. Generates metadata
4. Calls lpmake to build super.img
5. Verifies output

### Step 7: Completion

When finished:
- Status shows **Success**
- Console log shows completion message
- **Verify Output Image** button appears
- Output file: `output_directory/super.img`

Click **Verify Output Image** to:
- Check image integrity
- Display super partition info
- Validate metadata

---

## CLI Usage

### Basic Syntax

```bash
zilium-super-compactor [OPTIONS] -c CONFIG_FILE -o OUTPUT_DIR
```

### Common Commands

#### Standard Build
```bash
./zilium-super-compactor -c super_config.json -o output/
```

#### Verbose Output
```bash
./zilium-super-compactor -c super_config.json -o output/ -v
```

#### Custom Super Size
```bash
# Specify exact size (in bytes)
./zilium-super-compactor -c config.json -o output/ --super-size 6000000000

# Auto-calculate optimal size (default)
./zilium-super-compactor -c config.json -o output/ --auto-size
```

#### Dry Run (Validate Only)
```bash
./zilium-super-compactor -c config.json --dry-run
```

#### Exclude Partitions
```bash
# Exclude specific partitions
./zilium-super-compactor -c config.json -o output/ \
  --exclude system_b \
  --exclude vendor_b
```

### Full Command-Line Options

```
Options:
  -c, --config FILE          Configuration JSON file (required)
  -o, --output DIR          Output directory (required)
  -v, --verbose             Enable verbose logging
  -q, --quiet               Suppress non-error output
  
  --super-size SIZE         Custom super partition size in bytes
  --auto-size               Auto-calculate minimum size (default)
  --block-size SIZE         Block size (default: 4096)
  
  --exclude PARTITION       Exclude partition from build
  --include-only PARTITION  Include only specified partitions
  
  --dry-run                 Validate without building
  --force                   Overwrite existing output files
  
  --metadata-slots N        Number of metadata slots (default: 2)
  --metadata-size SIZE      Metadata region size
  
  -h, --help                Show help message
  --version                 Show version information
```

### Examples

#### Example 1: Basic Custom ROM Build
```bash
# Extract ROM
unzip ROM.zip -d extracted/

# Build super.img
./zilium-super-compactor \
  -c extracted/META/super_config.json \
  -o custom_rom/

# Result: custom_rom/super.img
```

#### Example 2: A/B ROM with Slot Selection
```bash
# Build only A slot (smaller size)
./zilium-super-compactor \
  -c config.json \
  -o output/ \
  --exclude system_b \
  --exclude vendor_b \
  --exclude product_b
```

#### Example 3: GSI Build
```bash
# Use custom system with stock vendor
./zilium-super-compactor \
  -c gsi_config.json \
  -o gsi_output/ \
  --verbose
```

#### Example 4: Maximum Compression
```bash
# Auto-calculate smallest possible size
./zilium-super-compactor \
  -c config.json \
  -o output/ \
  --auto-size \
  --verbose

# The tool will calculate:
# min_size = sum(partition_sizes) + metadata_overhead + alignment
```

---

## Configuration Files

### JSON Structure

```json
{
  "lpmake": {
    "metadata_size": 65536,
    "metadata_slots": 2,
    "device_size": 6000000000,
    "block_size": 4096,
    "super_partition_name": "super",
    "virtual_ab": false,
    "partitions": [
      {
        "name": "system_a",
        "size": 2894069760,
        "readonly": true,
        "image": "/path/to/system.img"
      },
      {
        "name": "vendor_a",
        "size": 892534784,
        "readonly": true,
        "image": "/path/to/vendor.img"
      }
    ]
  }
}
```

### Key Fields

- **metadata_size**: Size of metadata region (usually 65536)
- **metadata_slots**: Number of metadata copies (2 for A/B, 1 for A-only)
- **device_size**: Target super partition size
- **block_size**: Partition alignment (usually 4096)
- **super_partition_name**: Name of super partition (usually "super")
- **virtual_ab**: Enable virtual A/B (Android 11+)

### Partition Entry

- **name**: Partition name (e.g., "system_a")
- **size**: Partition size in bytes
- **readonly**: Usually true for system partitions
- **image**: Path to partition image file

### Auto-Generated Configs

If your ROM doesn't include a config file, you can generate one:

```bash
# Use lpunpack to extract super.img
lpunpack super.img extracted/

# Generate config from extracted partitions
lpdump super.img > super_info.txt

# Manually create config.json based on info
```

---

## Common Workflows

### Workflow 1: Stock ROM Modification

**Goal**: Modify stock ROM and rebuild super.img

```bash
# 1. Extract stock ROM
unzip stock_rom.zip -d stock/

# 2. Extract super.img
cd stock/images/
lpunpack super.img extracted/

# 3. Modify partitions
mkdir modified/
cp extracted/system_a.img modified/
# ... edit system_a.img ...

# 4. Create config
cat > modified_config.json << EOF
{
  "lpmake": {
    "metadata_size": 65536,
    "metadata_slots": 2,
    "device_size": 6000000000,
    "block_size": 4096,
    "super_partition_name": "super",
    "partitions": [
      {
        "name": "system_a",
        "size": 2894069760,
        "readonly": true,
        "image": "modified/system_a.img"
      },
      {
        "name": "vendor_a",
        "size": 892534784,
        "readonly": true,
        "image": "extracted/vendor_a.img"
      }
    ]
  }
}
EOF

# 5. Build new super.img
zilium-super-compactor -c modified_config.json -o output/

# 6. Flash
fastboot flash super output/super.img
```

### Workflow 2: Custom ROM from Source

**Goal**: Build super.img from compiled ROM

```bash
# After building ROM with:
# . build/envsetup.sh
# lunch device_name
# make -j$(nproc)

# 1. Locate built images
cd out/target/product/device_name/

# 2. Use existing config
zilium-super-compactor \
  -c META/super_config.json \
  -o ../../..

# 3. Result: out/super.img
```

### Workflow 3: GSI Creation

**Goal**: Create Generic System Image with custom vendor

```bash
# 1. Download GSI system image
wget https://dl.google.com/developers/android/gsi/gsi_gms_arm64-exp-TQ3A.230805.001.img

# 2. Extract stock vendor
lpunpack stock_super.img extracted/

# 3. Create GSI config
cat > gsi_config.json << EOF
{
  "lpmake": {
    "metadata_size": 65536,
    "metadata_slots": 2,
    "device_size": 6000000000,
    "block_size": 4096,
    "super_partition_name": "super",
    "partitions": [
      {
        "name": "system_a",
        "size": 3000000000,
        "readonly": true,
        "image": "gsi_gms_arm64-exp-TQ3A.230805.001.img"
      },
      {
        "name": "vendor_a",
        "size": 892534784,
        "readonly": true,
        "image": "extracted/vendor_a.img"
      }
    ]
  }
}
EOF

# 4. Build GSI super
zilium-super-compactor -c gsi_config.json -o gsi_output/
```

---

## Tips and Best Practices

### 1. Always Backup

```bash
# Before flashing, backup current partitions
adb reboot bootloader
fastboot getvar current-slot
fastboot flash backup_super super_backup.img
```

### 2. Verify Image Integrity

```bash
# After building, verify the image
lpdump output/super.img

# Check size
ls -lh output/super.img

# Compare with original
md5sum original_super.img output/super.img
```

### 3. Test in Recovery First

Instead of flashing to main slots, test in recovery:
```bash
# Flash to recovery partition (if supported)
fastboot boot twrp.img
# Then sideload super.img for testing
```

### 4. Use Minimal Builds for Testing

```bash
# Exclude non-critical partitions for faster testing
zilium-super-compactor -c config.json -o test/ \
  --exclude product_a \
  --exclude odm_a
```

### 5. Monitor Disk Space

```bash
# Check available space before building
df -h /path/to/output/

# Super.img can be large (4-6 GB typically)
# Ensure 2-3x that space is available
```

### 6. Use SSD for Speed

Building on SSD vs HDD:
- **SSD**: 2-5 minutes
- **HDD**: 10-20 minutes

### 7. Keep Original Configs

```bash
# Always save original config
cp stock/META/super_config.json stock/META/super_config.json.backup

# Document your changes
echo "Modified: increased system size to 3GB" > CHANGES.txt
```

---

## Flashing

### Prerequisites

- Device in bootloader/fastboot mode
- Bootloader unlocked
- Latest fastboot binary
- USB debugging enabled (if booting to fastboot from Android)

### Flashing Super Partition

```bash
# Boot to bootloader
adb reboot bootloader

# Verify device is detected
fastboot devices

# Flash super.img
fastboot flash super output/super.img

# Reboot
fastboot reboot
```

### A/B Devices

```bash
# Check current slot
fastboot getvar current-slot

# Flash to inactive slot
fastboot set_active other
fastboot flash super output/super.img
fastboot reboot
```

### Troubleshooting Flash Issues

**Error: "Partition not found"**
```bash
# Use super partition name from config
fastboot flash super_a output/super.img
# OR
fastboot flash super_b output/super.img
```

**Error: "Image too large"**
```bash
# Check max size
fastboot getvar partition-size:super

# Rebuild with smaller size
zilium-super-compactor -c config.json -o output/ \
  --super-size <SIZE_FROM_ABOVE>
```

**Device bootloop after flash**
```bash
# Flash stock firmware to recover
# OR boot to recovery and wipe data
fastboot -w
```

---

## Next Steps

- Check [CLI Reference](CLI_REFERENCE.md) for all command options
- Read [Troubleshooting](TROUBLESHOOTING.md) for common issues
- See [FAQ](FAQ.md) for frequently asked questions

---

**Need Help?** 
- Telegram: [@DumbDragon](https://t.me/DumbDragon)
- GitHub Issues: [Report a problem](https://github.com/Badmaneers/zilium/issues)
