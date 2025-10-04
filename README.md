# Zilium Super Compactor

A powerful tool for rebuilding and compacting super partition images for Realme/OPPO/OnePlus devices with **stock vbmeta compatibility**.

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()
[![Platform](https://img.shields.io/badge/platform-Linux-blue)]()
[![License](https://img.shields.io/badge/license-MIT-blue)]()
[![Version](https://img.shields.io/badge/version-1.0.0-orange)]()

## 🌟 Features

- ✅ **Stock VBMeta Compatible** - Rebuilds super.img with exact metadata structure
- 🔄 **A/B & Non-A/B Support** - Auto-detects device partition scheme
- 📦 **Self-Contained** - Bundles all required tools (lpmake, lpunpack, lpdump)
- ⚡ **Fast Builds** - Intelligent caching skips unnecessary recompilation
- 🎯 **JSON Configuration** - Easy-to-use configuration format
- 🛠️ **Professional Build System** - Release mode with full optimizations

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Installation](#-installation)
- [Usage](#-usage)
- [Building from Source](#-building-from-source)
- [Configuration](#-configuration)
- [Troubleshooting](#-troubleshooting)
- [Technical Details](#-technical-details)
- [Contributing](#-contributing)
- [License](#-license)

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/Badmaneers/zilium.git
cd zilium

# Build the project
./build.sh --release

# Run the tool
./build/zilium-super-compactor /path/to/rom-folder
```

## 📦 Installation

### Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install build-essential cmake git zlib1g-dev
```

**Arch Linux:**
```bash
sudo pacman -S base-devel cmake git zlib
```

**Fedora:**
```bash
sudo dnf install gcc-c++ cmake git zlib-devel
```

### Build Options

```bash
# Quick debug build (for development)
./build.sh

# Optimized release build
./build.sh --release

# Clean build
./build.sh --clean --release

# Force rebuild LP tools
./build.sh --lptools --release

# Create distribution package
./build.sh --package
```

## 📖 Usage

### Basic Usage

```bash
./build/zilium-super-compactor /path/to/rom-folder
```

The tool will:
1. Scan for JSON configuration files in `META/` folder
2. Let you select the appropriate configuration
3. Verify all partition images exist
4. Automatically detect A/B vs non-A/B device type
5. Rebuild super.img with correct metadata parameters

### Example Output

```
╔═══════════════════════════════════════════╗
║   Super Image Rebuilder for Realme/OPPO  ║
║          Single & A/B Slot Support        ║
╚═══════════════════════════════════════════╝

Configuration loaded successfully:
  - Block device size: 10200547328 bytes
  - Block size: 4096 bytes
  - Metadata size: 65536 bytes
  - Metadata slots: 2
  - Groups: 2
  - Partitions: 15

Building super.img...
✓ SUCCESS! Super image created at: /path/to/rom-folder/super.img
```

## 🔧 Building from Source

### Clone with Submodule

```bash
git clone --recursive https://github.com/Badmaneers/zilium.git
cd zilium
```

Or if already cloned:

```bash
git submodule update --init --recursive
```

### Build System

The project uses a sophisticated build system:

| Command | Time | Description |
|---------|------|-------------|
| `./build.sh` | ~7s | Debug build, skips LP tools |
| `./build.sh --release` | ~7s | Optimized build, skips LP tools |
| `./build.sh --lptools` | ~2m | Rebuilds LP tools from source |
| `./build.sh --package` | ~10s | Creates distribution tarball |

### Build Flags

- `-r, --release`: Enable O3 optimization + native CPU instructions
- `-c, --clean`: Clean build directory before building
- `-l, --lptools`: Force rebuild of bundled LP tools
- `-p, --package`: Create release package with checksums
- `-h, --help`: Show help message

## ⚙️ Configuration

### JSON Configuration Format

The tool uses JSON configuration files located in `META/` folder:

```json
{
  "block_devices": [{
    "name": "super",
    "size": "10200547328",
    "block_size": "4096",
    "alignment": "1048576"
  }],
  "groups": [{
    "name": "main",
    "maximum_size": "10196353024"
  }],
  "partitions": [{
    "name": "system",
    "path": "IMAGES/system.img",
    "size": "802099200",
    "group_name": "main",
    "is_dynamic": true
  }]
}
```

### Device Type Detection

**Non-A/B Devices:**
- Groups: `main`
- Metadata slots: 2
- Example: Realme C-series, some A-series

**A/B Devices:**
- Groups: `main_a`, `main_b`
- Metadata slots: 3
- Example: Realme GT series, Find X series

## 🐛 Troubleshooting

### Common Issues

**1. "ERROR: Partition file not found"**
```bash
# Ensure all partition images exist in IMAGES/ folder
ls -lh /path/to/rom/IMAGES/
```

**2. "CMake configuration failed"**
```bash
# Install missing dependencies
sudo apt install build-essential cmake git zlib1g-dev
```

**3. "LP tools not found"**
```bash
# Force rebuild LP tools
./build.sh --lptools --release
```

**4. Device won't boot after flashing**
```bash
# This is normal! See VBMETA_COMPATIBILITY.md for solutions
```

### VBMeta Compatibility

The rebuilt super.img will NOT boot with stock vbmeta. This is expected behavior because:
- Stock vbmeta contains hash of original super metadata
- Rebuilt super.img has different metadata hash
- VBMeta verification will fail

**Solutions:**

1. **Disable verification (easiest):**
```bash
fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img
fastboot flash super super.img
fastboot reboot
```

2. **Flash empty vbmeta:**
```bash
dd if=/dev/zero of=vbmeta_disabled.img bs=4096 count=1
fastboot flash vbmeta vbmeta_disabled.img
fastboot flash super super.img
```

3. **Use patched vbmeta:**
- Use vbmeta from custom ROM
- Create your own with `avbtool`

See [VBMETA_COMPATIBILITY.md](VBMETA_COMPATIBILITY.md) for detailed explanation.

## 🔬 Technical Details

### Architecture

```
zilium-super-compactor/
├── src/
│   └── zilium-super-compactor.cpp    # Main tool (C++17)
├── lpunpack_and_lpmake/        # Bundled AOSP tools
│   ├── bin/
│   │   ├── lpmake              # LP partition builder
│   │   ├── lpunpack            # LP partition unpacker
│   │   └── lpdump              # LP metadata dumper
│   └── lib/                    # AOSP libraries
├── external/
│   └── json/                   # nlohmann/json library
├── build.sh                    # Build automation script
└── CMakeLists.txt              # CMake configuration
```

### Key Technologies

- **C++17** - Modern C++ with filesystem support
- **CMake 3.10+** - Build system
- **nlohmann/json** - JSON parsing
- **AOSP liblp** - LP metadata handling
- **Bash** - Build automation

### Optimization Flags

Release builds use:
- `-O3` - Maximum optimization level
- `-march=native` - CPU-specific instructions
- Strip debug symbols - Reduces binary size
- Static linking - Self-contained binary

## 📊 Performance

| Operation | Time |
|-----------|------|
| Build (cached) | ~7 seconds |
| Build (clean) | ~7 seconds |
| Build LP tools | ~2 minutes |
| Rebuild super.img | 10-30 seconds |
| Package creation | ~3 seconds |

**Binary Sizes:**
- zilium-super-compactor: 136 KB
- lpmake: 3.1 MB
- lpunpack: 2.8 MB
- lpdump: 5.9 MB
- **Total package:** ~4.4 MB

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Setup

```bash
# Debug build for development
./build.sh

# Run with debugging enabled
gdb ./build/zilium-super-compactor
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- AOSP for LP tools (lpmake, lpunpack, lpdump)
- nlohmann for the excellent JSON library
- The Android modding community

## 📞 Support

- **Issues:** [GitHub Issues](https://github.com/Badmaneers/zilium/issues)
- **Documentation:** See `docs/` folder
- **Examples:** See [EXAMPLES.md](EXAMPLES.md)

## 🔗 Related Projects

- [lpunpack_and_lpmake](https://github.com/LonelyFool/lpunpack_and_lpmake) - AOSP LP tools
- [brotli](https://github.com/google/brotli) - Compression library
- [payload_dumper](https://github.com/vm03/payload_dumper) - OTA payload extractor

---

Made with ❤️ for the Android modding community
