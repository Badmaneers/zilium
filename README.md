# 🚀 Zilium Super Compactor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/Badmaneers/zilium/releases)
[![Platform](https://img.shields.io/badge/platform-Linux%20%7C%20Windows-lightgrey)](https://github.com/Badmaneers/zilium)
[![Qt](https://img.shields.io/badge/Qt-6.2+-green)](https://www.qt.io/)

A powerful cross-platform tool for rebuilding and compacting super partition images for Realme/OPPO/OnePlus devices with stock vbmeta compatibility. Now with Windows support!

![Zilium Banner](docs/images/banner.png)

## ✨ Features

### 🔧 Core Functionality
- **Smart Size Optimization** - Automatically reduces super partition size to minimum required
- **Stock VBMeta Compatible** - Works with unmodified stock VBMeta (no disable verification needed)
- **A/B and Non-A/B Support** - Compatible with both slot types
- **Multi-Partition Support** - Handles system, vendor, product, odm, and more
- **Fast Builds** - Optimized compilation process with progress tracking
- **Self-Contained** - Includes all necessary AOSP tools (lpmake, lpunpack, lpdump)

### 🎨 Graphical User Interface (GUI)
- **Modern Qt6 Interface** - Beautiful, native-looking application
- **Cross-Platform Support** - Optimized for Linux and Windows
- **Dark/Light Themes** - Toggle between themes for comfort
- **Platform-Specific UI** - Windows-optimized responsive layout
- **Real-time Progress** - Live console output and progress tracking
- **Partition Management** - Enable/disable partitions visually
- **Configuration Validation** - Automatic error checking and warnings
- **Interactive Guide** - Built-in user guide and documentation

### 🖥️ Command Line Interface (CLI)
- **Scriptable** - Perfect for automation and batch processing
- **Detailed Logging** - Verbose output for debugging
- **Flexible Options** - Customize behavior with command-line flags
- **Error Handling** - Clear error messages and validation

## 📸 Screenshots

### GUI - Dark Theme
![Dark Theme](docs/images/gui-dark.png)

### GUI - Light Theme
![Light Theme](docs/images/gui-light.png)

### CLI Output
```
╔═══════════════════════════════════════════╗
║   ZILIUM SUPER COMPACTOR v1.0.0          ║
║   Building Super Partition...             ║
╚═══════════════════════════════════════════╝

📂 Loading configuration...
✓ Configuration loaded: super_config.json
✓ Device type: A/B
✓ Block size: 4096 bytes
✓ Super partition: super

📊 Partition Summary:
  • system_a: 2.8 GB
  • vendor_a: 892 MB
  • product_a: 1.2 GB
  • odm_a: 124 MB

🔧 Building super partition...
[██████████████████████████████] 100%

✓ Build completed successfully!
✓ Output: output/super.img
✓ Size: 4.9 GB (optimized from 6.0 GB)
✓ Build time: 2m 34s
```

## 🚀 Quick Start

### Prerequisites

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install build-essential cmake qt6-base-dev qt6-declarative-dev qml6-module-qtquick-controls
```

**Linux (Arch):**
```bash
sudo pacman -S base-devel cmake qt6-base qt6-declarative qt6-quickcontrols2
```

**Linux (Fedora):**
```bash
sudo dnf install gcc-c++ cmake qt6-qtbase-devel qt6-qtdeclarative-devel
```

**Windows:**
```powershell
# Download and install:
# - Visual Studio 2022 (Community or higher)
# - Qt 6.9.3 for MSVC 2022 64-bit
# - CMake 3.20+
# See docs/WINDOWS_SUPPORT.md for detailed instructions
```

### Installation

**Linux:**
```bash
# Clone the repository
git clone https://github.com/Badmaneers/zilium.git
cd zilium

# Build everything (CLI + GUI)
./build.sh

# Or build separately
./build.sh --cli-only    # Build CLI only
./build-gui.sh           # Build GUI only
```

**Windows:**
```batch
REM Clone the repository
git clone https://github.com/Badmaneers/zilium.git
cd zilium

REM Edit build-windows.bat to set Qt path
REM Then build everything
build-windows.bat

REM Or download pre-built installer from releases
REM https://github.com/Badmaneers/zilium/releases/latest
```

### Usage

#### GUI Mode (Recommended for Beginners)

**Linux:**
```bash
# Launch the GUI
./build/gui/zilium-gui
```

**Windows:**
```batch
REM Launch from Start Menu, or run:
zilium-gui.exe
```

**Steps:**
1. Click "Browse..." to select your ROM's configuration JSON file
2. Click "Browse..." to select output directory
3. Review partitions in the "Partitions" tab
4. Click "▶ Start" to begin compilation
5. Monitor progress in the console log
6. Done! Your optimized super.img is ready

#### CLI Mode (For Advanced Users & Automation)

```bash
# Basic usage
./build/zilium-super-compactor -c /path/to/super_config.json -o /path/to/output/

# With custom super size
./build/zilium-super-compactor -c config.json -o output/ --super-size 6000000000

# Verbose mode
./build/zilium-super-compactor -c config.json -o output/ -v

# Dry run (validate without building)
./build/zilium-super-compactor -c config.json --dry-run
```

## 📖 Documentation

### For Users
- [Installation Guide](docs/INSTALLATION.md) - Linux installation instructions
- **[Windows Support Guide](docs/WINDOWS_SUPPORT.md)** - ⭐ Complete Windows guide (NEW)
- [User Guide](docs/USER_GUIDE.md) - Complete usage guide with examples
- [GUI Tutorial](docs/GUI_TUTORIAL.md) - Step-by-step GUI walkthrough
- [CLI Reference](docs/CLI_REFERENCE.md) - Command-line options and examples
- [Troubleshooting](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [FAQ](docs/FAQ.md) - Frequently asked questions

### For Developers
- [Building from Source](docs/BUILDING.md) - Detailed build instructions
- [Architecture](docs/ARCHITECTURE.md) - Code structure and design
- [Contributing](docs/CONTRIBUTING.md) - How to contribute to the project
- [API Documentation](docs/API.md) - Internal API reference

## 🔧 How It Works

### The Problem
Modern Android devices use **dynamic partitions** stored in a **super partition**. When you extract a ROM, the super partition is often oversized, containing unused space. Flashing this directly wastes storage and can cause issues.

### The Solution
Zilium analyzes your partition images and rebuilds the super partition with:
1. **Exact size calculation** - No wasted space
2. **Proper metadata generation** - Compatible with stock bootloader
3. **VBMeta compatibility** - Works with unmodified verification
4. **Optimized layout** - Efficient partition arrangement

## 🎯 Use Cases

### 1. **Custom ROM Development**
```bash
# Build optimized super.img for your custom ROM
./build/zilium-super-compactor -c ROM/META/super_config.json -o output/
```

### 2. **Stock ROM Modification**
```bash
# Modify and repack stock ROM
./build/zilium-super-compactor -c stock/config.json -o modified-rom/
```

### 3. **GSI Image Building**
```bash
# Create Generic System Image with custom vendor
./build/zilium-super-compactor -c gsi-config.json -o gsi-output/
```

### 4. **OTA Package Creation**
```bash
# Build super.img for OTA updates
./build/zilium-super-compactor -c ota/config.json -o ota-package/
```

## 🏗️ Project Structure

```
zilium/
├── src/
│   ├── zilium_core.h              # Core functionality
│   └── zilium_super_compactor.cpp # Main CLI application
├── gui/
│   ├── src/                       # GUI C++ sources
│   │   ├── main.cpp
│   │   ├── ziliumcontroller.*
│   │   ├── partitionmodel.*
│   │   └── superconfigmodel.*
│   ├── qml/                       # QML UI files
│   │   ├── main.qml
│   │   ├── GuideDialog.qml
│   │   ├── LicenseWindow.qml
│   │   └── PartitionDelegate.qml
│   └── resources/                 # Icons and assets
├── lpunpack_and_lpmake/          # AOSP LP tools
│   ├── bin/                       # Prebuilt binaries
│   └── partition_tools/           # Tool sources
├── external/
│   └── json/                      # nlohmann/json library
├── docs/                          # Documentation
├── build.sh                       # CLI build script
├── build-gui.sh                   # GUI build script
├── CMakeLists.txt                 # Main build configuration
└── LICENSE                        # MIT License
```

## 🔍 System Requirements

### Minimum Requirements

**Linux:**
- **OS**: Ubuntu 20.04+, Arch, Fedora 35+, or similar
- **RAM**: 4 GB
- **Disk**: 10 GB free space
- **Compiler**: GCC 9+ or Clang 10+
- **CMake**: 3.20+

**Windows:**
- **OS**: Windows 10 (Build 1809+) or Windows 11
- **RAM**: 4 GB
- **Disk**: 10 GB free space
- **Compiler**: Visual Studio 2022 with C++ workload
- **CMake**: 3.20+

### For GUI (Both Platforms)
- **Qt**: 6.2 or higher (6.9.3 recommended for Windows)
- **Graphics**: OpenGL 2.0+ / DirectX 11+
- **Display**: 1280x720 or higher (1920x1080 recommended)

### Recommended
- **CPU**: Quad-core or better
- **RAM**: 8 GB or more
- **Disk**: SSD for faster builds
- **Display**: 1920x1080 or higher resolution

## 🤝 Contributing

We welcome contributions! Here's how you can help:

### Ways to Contribute
- 🐛 Report bugs and issues
- 💡 Suggest new features
- 📖 Improve documentation
- 🔧 Submit pull requests
- ⭐ Star the repository
- 💬 Help others in discussions

### Development Setup

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/zilium.git
cd zilium

# Create feature branch
git checkout -b feature/amazing-feature

# Make changes and test
./build.sh
./build-gui.sh

# Commit and push
git commit -m "Add amazing feature"
git push origin feature/amazing-feature

# Open Pull Request on GitHub
```

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for detailed guidelines.

## 📜 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### Third-Party Components

- **Qt6 Framework** - The Qt Company Ltd. (LGPL v3 / GPL v3)
- **nlohmann/json** - Niels Lohmann (MIT License)
- **Android LP Tools** - AOSP (Apache 2.0 License)

## 👥 Authors

- **Badmaneers** - *Initial work and maintenance* - [@Badmaneers](https://github.com/Badmaneers)

## 🙏 Acknowledgments

- **AOSP Team** - For the LP tools (lpmake, lpunpack, lpdump)
- **Niels Lohmann** - For the excellent JSON library
- **Qt Project** - For the amazing GUI framework
- **KDE Team** - For design inspiration (Breeze theme, HIG)
- **Android ROM Community** - For feedback and testing

## 📞 Support & Contact

- 💬 **Telegram**: [@DumbDragon](https://t.me/DumbDragon)
- 🐙 **GitHub**: [github.com/Badmaneers/zilium](https://github.com/Badmaneers/zilium)
- 🐛 **Issues**: [GitHub Issues](https://github.com/Badmaneers/zilium/issues)
- 📧 **Email**: Open an issue for contact

## 🔮 Roadmap

### Version 1.1 (Current - October 2025)
- [x] **Windows support** ⭐ DONE
- [x] Windows-optimized responsive UI
- [x] Platform-specific QML layouts
- [x] NSIS installer for Windows
- [ ] macOS support
- [ ] Drag-and-drop support in GUI
- [ ] Multi-language support (i18n)

### Version 1.2 (Planned)
- [ ] Partition image preview
- [ ] VBMeta patching integration
- [ ] Windows Store (MSIX) package
- [ ] Winget package manager support


## ⚠️ Disclaimer

This tool is provided as-is without any warranty. Flashing modified system images can:
- Void your device warranty
- Brick your device if used incorrectly
- Cause data loss

**Always backup your data before flashing!**

## 📊 Stats

![GitHub stars](https://img.shields.io/github/stars/Badmaneers/zilium?style=social)
![GitHub forks](https://img.shields.io/github/forks/Badmaneers/zilium?style=social)
![GitHub watchers](https://img.shields.io/github/watchers/Badmaneers/zilium?style=social)

---

<p align="center">
  <b>Made with ❤️ for the Android ROM Community</b>
</p>

<p align="center">
  <sub>If this project helped you, consider starring ⭐ the repository!</sub>
</p>
