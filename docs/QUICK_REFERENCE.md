# Zilium Quick Reference

Quick reference card for common tasks on Linux and Windows.

## 🚀 Installation

**Linux:**
```bash
# Clone
git clone https://github.com/Badmaneers/zilium.git
cd zilium

# Build
./build.sh          # CLI
./build-gui.sh      # GUI
```

**Windows:**
```batch
REM Clone
git clone https://github.com/Badmaneers/zilium.git
cd zilium

REM Build (edit build-windows.bat to set Qt path first)
build-windows.bat

REM Or download installer from releases
REM https://github.com/Badmaneers/zilium/releases/latest
```

## 📦 Basic Usage

### GUI

**Linux:**
```bash
./build/gui/zilium-gui
```

**Windows:**
```batch
REM From Start Menu or run:
zilium-gui.exe
```

**Steps:**
1. Browse → Select config JSON
2. Browse → Select output folder
3. Click ▶ Start

### CLI

**Linux:**
```bash
./build/zilium-super-compactor -c config.json -o output/
```

**Windows:**
```batch
zilium-super-compactor.exe -c config.json -o output\
```

## ⌨️ Common Commands

### Standard Build
```bash
zilium-super-compactor -c super_config.json -o out/
```

### Verbose Mode
```bash
zilium-super-compactor -c config.json -o out/ -v
```

### Dry Run
```bash
zilium-super-compactor -c config.json --dry-run
```

### Custom Size
```bash
zilium-super-compactor -c config.json -o out/ --super-size 6000000000
```

### Exclude Partitions
```bash
zilium-super-compactor -c config.json -o out/ \
  --exclude system_b \
  --exclude vendor_b
```

## 📝 Config File Example

```json
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
        "image": "/path/to/system.img"
      }
    ]
  }
}
```

## 🔧 Flashing

```bash
# Boot to fastboot
adb reboot bootloader

# Flash super
fastboot flash super output/super.img

# Reboot
fastboot reboot
```

### A/B Devices
```bash
fastboot set_active other
fastboot flash super output/super.img
fastboot reboot
```

## 🐛 Troubleshooting

### Qt6 Not Found
```bash
sudo apt install qt6-base-dev qt6-declarative-dev
```

### Build Fails
```bash
# Clean rebuild
rm -rf build/
./build.sh
```

### Partition Not Found
- Check paths in config JSON
- Use absolute paths
- Verify files exist: `ls -lh /path/to/partition.img`

### Device Won't Boot
```bash
# Try other slot (A/B devices)
fastboot set_active other
fastboot reboot

# Or wipe data
fastboot -w
fastboot reboot
```

## 📊 Verification

### Check Build
```bash
# Verify output exists
ls -lh output/super.img

# Dump partition info
lpdump output/super.img

# Compare sizes
du -h original_super.img output/super.img
```

### Check Device
```bash
# Check super partition
adb shell ls -l /dev/block/by-name/super

# Check slot
fastboot getvar current-slot

# Check partition size
fastboot getvar partition-size:super
```

## 🔍 Useful Commands

### Extract Super
```bash
lpunpack super.img extracted/
```

### List Partitions
```bash
lpdump super.img
```

### Get File Size
```bash
stat -c%s partition.img
du -h partition.img
```

### Calculate Total Size
```bash
# Sum partition sizes
du -c extracted/*.img | tail -1
```

## 📚 Documentation

| Document | Purpose | Platform |
|----------|---------|----------|
| [README.md](../README.md) | Project overview | All |
| [INSTALLATION.md](INSTALLATION.md) | Linux install guide | Linux |
| [WINDOWS_SUPPORT.md](WINDOWS_SUPPORT.md) | Windows guide | Windows |
| [USER_GUIDE.md](USER_GUIDE.md) | Complete guide | All |
| [FAQ.md](FAQ.md) | Common questions | All |
| [CONTRIBUTING.md](CONTRIBUTING.md) | How to contribute | All |

## 🆘 Get Help

- 📖 Docs: `docs/` folder
- 💬 Telegram: [@DumbDragon](https://t.me/DumbDragon)
- 🐙 Issues: [GitHub](https://github.com/Badmaneers/zilium/issues)

## ⚡ Tips

1. **Always backup** before flashing
2. **Use absolute paths** in config files
3. **Build on SSD** for speed (2-5 min vs 10-20 min)
4. **Test in recovery** before main flash
5. **Check free space** (need 2-3x super size)
6. **Verify output** with lpdump
7. **Start with verbose mode** (`-v`) for debugging

## 🎯 Workflows

### Modify Stock ROM
```bash
# 1. Extract
lpunpack super.img extracted/

# 2. Modify partition
# ... edit system.img ...

# 3. Create config
# ... edit config.json ...

# 4. Build
zilium-super-compactor -c config.json -o output/

# 5. Flash
fastboot flash super output/super.img
```

### Build from Source
```bash
# After building ROM
cd out/target/product/device/
zilium-super-compactor -c META/super_config.json -o ../..
```

### GSI Creation
```bash
# 1. Get GSI system image
wget https://dl.google.com/developers/android/gsi/...

# 2. Use stock vendor
lpunpack stock_super.img extracted/

# 3. Create config with GSI system + stock vendor
# ... edit config.json ...

# 4. Build
zilium-super-compactor -c gsi_config.json -o gsi_output/
```

## 📏 Size Calculation

```
Minimum Super Size = 
  Sum(Partition Sizes) + 
  Metadata Size + 
  Alignment Padding

Typical:
  Partitions: 4-5 GB
  Metadata:   65 KB
  Padding:    ~200 MB
  Total:      ~4.2-5.2 GB

Original super often: 6 GB (wasteful)
```

## 🔐 Safety Checklist

Before flashing:
- [ ] Backup current ROM
- [ ] Verify super.img with lpdump
- [ ] Check file size is reasonable
- [ ] Battery >50%
- [ ] Test build in recovery if possible
- [ ] Know how to restore (fastboot/recovery)

---

**Print this page for quick reference!**

*Last updated: October 2025 - Zilium v1.0.1 (with Windows support)*
