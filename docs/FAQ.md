# Frequently Asked Questions (FAQ)

Common questions and answers about Zilium Super Compactor.

## Table of Contents

- [General Questions](#general-questions)
- [Installation](#installation)
- [Usage](#usage)
- [Technical](#technical)
- [Troubleshooting](#troubleshooting)
- [Device Compatibility](#device-compatibility)
- [Advanced Topics](#advanced-topics)

---

## General Questions

### What is Zilium Super Compactor?

Zilium is a tool that rebuilds Android super partition images with optimized sizes while maintaining compatibility with stock VBMeta. It's designed for ROM developers, modders, and enthusiasts working with modern Android devices.

### Why do I need this tool?

When you extract a ROM's super partition, it often contains unused space. Zilium optimizes this by:
- Reducing super partition size to the minimum required
- Maintaining stock VBMeta compatibility (no need to disable verification)
- Supporting both A/B and non-A/B devices
- Providing a user-friendly GUI and powerful CLI

### Is it safe to use?

Yes, when used correctly. However:
- ✅ The tool itself is safe and doesn't modify your device directly
- ⚠️ Always backup before flashing
- ⚠️ Understand what you're flashing
- ⚠️ Flashing wrong images can brick your device

### Is it free and open source?

Yes! Zilium is released under the MIT License. The source code is available on [GitHub](https://github.com/Badmaneers/zilium).

### Which devices are supported?

Zilium supports devices that use Android's dynamic partitions (Android 10+), particularly:
- Realme devices
- OPPO devices
- OnePlus devices
- Any device with super partition and dynamic partitions

### Do I need an unlocked bootloader?

**For using Zilium**: No, the tool just builds the image.

**For flashing the result**: Yes, flashing custom super.img requires an unlocked bootloader.

---

## Installation

### What are the system requirements?

**Minimum:**
- Linux OS (Ubuntu 20.04+, Arch, Fedora, etc.)
- 4 GB RAM
- 10 GB free disk space
- GCC 9+ or Clang 10+

**Recommended:**
- 8 GB RAM
- SSD with 20 GB+ space
- Modern CPU (4+ cores)

### Do I need Qt6 to use Zilium?

Only if you want the GUI. The CLI works without Qt6:
```bash
# CLI only
./build.sh --cli-only

# With GUI
./build.sh
./build-gui.sh
```

### Can I use it on Windows or macOS?

Currently, Zilium only supports Linux. Windows and macOS support are planned for future releases. 

Workarounds:
- **Windows**: Use WSL2 (Windows Subsystem for Linux)
- **macOS**: Use a Linux VM or wait for native support

### How do I update Zilium?

```bash
cd zilium
git pull origin main
./build.sh
./build-gui.sh
```

---

## Usage

### Where do I get the configuration JSON file?

The config file is usually included in your ROM's META folder:
- `ROM_NAME/META/super_config.json`
- `extracted/dynamic_partitions_op_list`
- `config/lpmake_config.json`

If not available, you can generate one by examining your super.img with `lpdump`.

### Can I use Zilium without a config file?

Not directly. The config file tells Zilium:
- Which partitions to include
- Partition sizes
- Super partition metadata

However, you can create a minimal config manually if you have the partition images.

### How long does building take?

Depends on:
- **Super size**: Larger partitions take longer
- **Storage type**: SSD (2-5 min) vs HDD (10-20 min)
- **CPU**: More cores help

Typical build: **3-7 minutes**

### Can I cancel a build in progress?

**GUI**: Click the "⏹ Stop" button

**CLI**: Press Ctrl+C

The incomplete output will be deleted automatically.

### How do I know if the build succeeded?

**GUI**: 
- Status shows "Success"
- Console shows completion message
- Verify button appears

**CLI**:
- Exit code 0
- Success message in output
- super.img exists in output directory

---

## Technical

### What's the difference between A/B and non-A/B?

**A/B (seamless updates):**
- Two sets of partitions (system_a, system_b, etc.)
- Updates install to inactive slot
- Can rollback if update fails
- **Zilium**: Supports both slots or just one

**Non-A/B (A-only):**
- Single set of partitions (system, vendor, etc.)
- Traditional update method
- **Zilium**: Supports this configuration

### What is VBMeta and why does it matter?

**VBMeta** (Verified Boot Metadata) verifies partition integrity. Stock ROMs have VBMeta enabled.

**Problem**: Custom super.img often breaks VBMeta verification, requiring disabling it (security risk).

**Zilium's Solution**: Builds super.img that works with stock VBMeta without disabling verification.

### How does size optimization work?

Zilium calculates the minimum required super size:

```
min_size = sum(partition_sizes) + metadata_overhead + alignment_padding
```

For example:
- system: 3 GB
- vendor: 1 GB  
- product: 500 MB
- odm: 200 MB
- metadata: 65 KB

**Original super**: 6 GB (lots of unused space)
**Zilium super**: ~4.7 GB (just what's needed)

### Can I add custom partitions?

Yes! Edit your config JSON:

```json
{
  "lpmake": {
    "partitions": [
      {
        "name": "custom_a",
        "size": 1073741824,
        "readonly": true,
        "image": "/path/to/custom.img"
      }
    ]
  }
}
```

### What partition types are supported?

Common partitions:
- ✅ system
- ✅ vendor
- ✅ product
- ✅ odm
- ✅ system_ext
- ✅ Custom partitions

Not supported in super:
- ❌ boot (separate partition)
- ❌ recovery (separate partition)
- ❌ vbmeta (separate partition)

---

## Troubleshooting

### "Partition image not found" error

**Cause**: The path in config JSON is incorrect or file doesn't exist.

**Solution**:
```bash
# Check if file exists
ls -lh /path/from/config.json

# Update path in GUI or edit JSON
# Use absolute paths to avoid confusion
```

### "Size mismatch" warning

**Cause**: Declared size in config doesn't match actual file size.

**Solution**:
```bash
# Get actual size
stat -c%s partition.img

# Update config JSON with correct size
# Or let Zilium auto-detect (GUI does this)
```

### "Not enough space" error

**Cause**: Output directory doesn't have enough free space.

**Solution**:
```bash
# Check available space
df -h /output/directory

# Free up space or use different location
# Need at least super_size + 1GB free
```

### Build succeeds but device won't boot

**Possible causes:**

1. **Wrong slot on A/B device**
   ```bash
   fastboot set_active other
   fastboot reboot
   ```

2. **Incomplete flash**
   ```bash
   fastboot flash super super.img
   fastboot reboot
   ```

3. **Missing partitions**
   - Check that all required partitions are included
   - Don't exclude critical partitions like system or vendor

4. **Corrupted super.img**
   ```bash
   # Verify integrity
   lpdump super.img
   
   # Rebuild if necessary
   ```

### GUI doesn't start

**Qt6 not found:**
```bash
# Install Qt6
sudo apt install qt6-base-dev qt6-declarative-dev

# If installed, add to library path
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
```

**Missing QML modules:**
```bash
sudo apt install qml6-module-qtquick-controls \
                 qml6-module-qtquick-layouts
```

### "lpmake: command not found"

**Cause**: LP tools not found in expected locations.

**Solution**:
```bash
# Check if lpmake exists
ls -l lpunpack_and_lpmake/bin/lpmake

# If missing, rebuild
cd lpunpack_and_lpmake
./make.sh

# Or use system lpmake if available
sudo apt install android-sdk-libsparse-utils
```

---

## Device Compatibility

### My device uses super partition, will it work?

Probably! If your device:
- ✅ Runs Android 10 or later
- ✅ Has a super partition
- ✅ Uses dynamic partitions

Then Zilium should work.

### How do I check if my device uses super partition?

```bash
# Boot device and connect via ADB
adb shell ls -l /dev/block/by-name/super

# If it exists, you have super partition
# Output: lrwxrwxrwx 1 root root ... /dev/block/by-name/super -> /dev/block/sda12
```

### Can I use Zilium for Samsung devices?

Samsung uses a different partition layout. While some newer Samsung devices have super partitions, they may require device-specific modifications. Test carefully!

### What about Xiaomi, Motorola, Nokia?

These brands' devices may work if they use standard super partition implementation. Check your device's partition layout first.

---

## Advanced Topics

### Can I script Zilium for batch processing?

Yes! CLI is perfect for scripting:

```bash
#!/bin/bash
# Build multiple ROM variants

for variant in gapps nogapps minimal; do
    echo "Building $variant..."
    ./zilium-super-compactor \
        -c configs/${variant}_config.json \
        -o output/${variant}/
done
```

### How do I integrate Zilium into my ROM build process?

```makefile
# Add to your ROM's Makefile
super.img: $(PARTITIONS)
    zilium-super-compactor \
        -c $(CONFIG_JSON) \
        -o $(OUT_DIR)
```

### Can I modify Zilium's output?

Yes! After Zilium builds super.img, you can:
1. Extract with `lpunpack`
2. Modify individual partition images
3. Rebuild with Zilium

### What's the difference between Zilium and lpmake?

**lpmake** (AOSP tool):
- Low-level tool
- Complex command-line syntax
- Manual size calculation
- No validation

**Zilium**:
- User-friendly wrapper around lpmake
- Automatic size optimization
- Built-in validation
- GUI available
- Better error messages

### Can I contribute to Zilium?

Absolutely! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. Contributions welcome:
- Bug reports
- Feature requests
- Code contributions
- Documentation improvements
- Translations (future)

### Is there an API for programmatic use?

The CLI is the API. Use it from any language:

**Python:**
```python
import subprocess

result = subprocess.run([
    './zilium-super-compactor',
    '-c', 'config.json',
    '-o', 'output/'
], capture_output=True)

if result.returncode == 0:
    print("Success!")
```

**Bash:**
```bash
if zilium-super-compactor -c config.json -o out/; then
    echo "Success!"
else
    echo "Failed!"
    exit 1
fi
```

### How do I report bugs or request features?

1. **Search existing issues**: [GitHub Issues](https://github.com/Badmaneers/zilium/issues)
2. **Create new issue**: Use the issue templates
3. **Provide details**: OS, version, steps to reproduce
4. **Include logs**: Console output, error messages

### Where can I get help?

- 📖 **Documentation**: Check docs/ folder
- 💬 **Telegram**: [@DumbDragon](https://t.me/DumbDragon)
- 🐙 **GitHub Issues**: Ask questions
- 🌐 **XDA Forum**: Community support (future)

---

## Still Have Questions?

If your question isn't answered here:

1. Check the [User Guide](USER_GUIDE.md)
2. Read the [Troubleshooting Guide](TROUBLESHOOTING.md)
3. Search [GitHub Issues](https://github.com/Badmaneers/zilium/issues)
4. Ask on [Telegram](https://t.me/DumbDragon)
5. Create a new [GitHub Issue](https://github.com/Badmaneers/zilium/issues/new)

---

**Last Updated**: January 2025

**Zilium Version**: 1.0.0
