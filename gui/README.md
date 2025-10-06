# Zilium Super Compactor GUI

A modern Qt6-based graphical user interface for the Zilium Super Compactor tool.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Qt](https://img.shields.io/badge/Qt-6.2+-green)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey)

## Features

- 🎨 **Modern UI/UX** - Inspired by KDE Human Interface Guidelines
- 🌓 **Dark/Light Themes** - Toggle between dark and light themes
- 📊 **Real-time Progress** - Live compilation status and progress tracking
- 🔍 **Partition Viewer** - Visual table of all partitions with enable/disable
- 📝 **Console Log** - Real-time output from the compilation process
- ⚙️ **Configuration Info** - Display detailed super partition metadata
- 🚀 **Easy to Use** - Simple browse-and-compile workflow

## Screenshots

### Dark Theme (Default)
The default dark theme provides a comfortable viewing experience with KDE Breeze-inspired colors.

### Light Theme
Switch to light theme for daytime use with a single click.

## Building

### Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install qt6-base-dev qt6-declarative-dev qml6-module-qtquick-controls cmake build-essential
```

**Arch Linux:**
```bash
sudo pacman -S qt6-base qt6-declarative qt6-quickcontrols2 cmake base-devel
```

**Fedora:**
```bash
sudo dnf install qt6-qtbase-devel qt6-qtdeclarative-devel cmake gcc-c++
```

### Build Commands

```bash
# Quick build (GUI + CLI)
./build-gui.sh

# Or manually with CMake
mkdir build && cd build
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_GUI=ON ..
make -j$(nproc)

# The GUI binary will be at: build/gui/zilium-gui
```

### Build Options

| Option | Description | Default |
|--------|-------------|---------|
| `BUILD_GUI` | Build the Qt6 GUI application | ON |
| `CMAKE_BUILD_TYPE` | Build type (Debug/Release) | Release |

## Usage

### Launch the GUI

```bash
./build/gui/zilium-gui
```

### Workflow

1. **Select Configuration File**
   - Click "Browse..." next to "Select .json file"
   - Navigate to your ROM's META folder
   - Select the appropriate JSON configuration file
   - The GUI will automatically load and parse the config

2. **Select Output Directory**
   - Click "Browse..." next to "Select Output folder"
   - Choose where to save the compiled super.img

3. **Review Configuration**
   - Switch to "Super Info" tab to see metadata
   - Switch to "Partitions" tab to see partition list
   - Enable/disable specific partitions as needed

4. **Start Compilation**
   - Click the "Start Compiling" button
   - Monitor progress in the Console Log
   - Wait for completion notification

5. **Success!**
   - The compiled super.img will be in your output directory
   - Ready to flash to your device

## Interface Overview

### Left Panel (Workflow)

- **Configuration Section**
  - JSON file path selector
  - Output directory selector
  
- **Action Button**
  - Start/Stop compilation
  - Disabled until both paths are set
  
- **Console Log**
  - Real-time output from zilium-super-compactor
  - Clear log button for cleanup
  
- **Status Bar**
  - Current operation status
  - Progress bar showing completion percentage

### Right Panel (Information)

- **Super Info Tab**
  - Device Slot Type (A/B or Non-A/B)
  - Block Size
  - Super Partition Name
  - Total Size
  - Metadata Slots
  - Metadata Size

- **Partitions Tab**
  - Table view of all partitions
  - Enable/disable individual partitions
  - Shows name, size, and path
  
- **Settings Tab**
  - Future: Application preferences
  
- **Developer Info Tab**
  - Version information
  - Feature list
  - Credits

## Theme Customization

The GUI supports two built-in themes:

### Dark Theme
- Background: `#232629`
- Surface: `#31363b`
- Primary Text: `#eff0f1`
- Accent: `#3daee9`

### Light Theme
- Background: `#fcfcfc`
- Surface: `#ffffff`
- Primary Text: `#232629`
- Accent: `#3daee9`

Toggle between themes using the light bulb icon in the header.

## Architecture

### Components

```
gui/
├── src/
│   ├── main.cpp                  # Application entry point
│   ├── ziliumcontroller.{h,cpp}  # Main controller (process management)
│   ├── partitionmodel.{h,cpp}    # Partition table model
│   └── superconfigmodel.{h,cpp}  # Configuration metadata model
├── qml/
│   ├── main.qml                  # Main window
│   ├── PartitionDelegate.qml     # Partition row delegate
│   └── ThemeManager.qml          # Theme management
├── resources/
│   └── icons/                    # SVG icons
└── CMakeLists.txt                # Build configuration
```

### Key Classes

- **ZiliumController**: Manages the compilation process, file dialogs, and process execution
- **PartitionModel**: Qt table model for displaying partition list
- **SuperConfigModel**: Exposes configuration metadata as Qt properties

## Development

### Building for Development

```bash
# Debug build with symbols
mkdir build-debug && cd build-debug
cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_GUI=ON ..
make -j$(nproc)

# Run with GDB
gdb ./gui/zilium-gui
```

### Code Style

- C++17 standard
- Qt naming conventions
- QML Material Design style
- KDE HIG inspiration

### Adding Features

1. **Backend**: Add methods to `ziliumcontroller.h/cpp`
2. **UI**: Update `qml/main.qml`
3. **Models**: Extend existing models or create new ones

## Troubleshooting

### GUI doesn't start

**Problem**: `error while loading shared libraries: libQt6Core.so.6`

**Solution**:
```bash
# Find Qt6 libraries
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

# Or install Qt6 runtime
sudo apt install qt6-base-dev
```

### Compilation fails

**Problem**: `zilium-super-compactor: command not found`

**Solution**: The GUI looks for the CLI binary in these locations:
1. Same directory as GUI binary
2. `../build/zilium-super-compactor`
3. `/usr/local/bin/zilium-super-compactor`
4. `/usr/bin/zilium-super-compactor`

Ensure the CLI is built and in one of these locations.

### Theme not applying

**Problem**: Colors look wrong or default

**Solution**: Ensure Qt6 QuickControls2 Material style is installed:
```bash
sudo apt install qml6-module-qtquick-controls
```

## Packaging

### Create Release Package

```bash
# Build everything
./build.sh --release
./build-gui.sh

# Create package
./package-release.sh

# Output: dist/zilium-1.0.0-Linux_x86_64.tar.gz
```

The package includes:
- CLI binary (`zilium-super-compactor`)
- GUI binary (`zilium-gui`)
- LP tools (`lpmake`, `lpunpack`, `lpdump`)
- Documentation
- Launcher script with library paths

## Future Enhancements

- [ ] Drag-and-drop file support
- [ ] Partition image preview
- [ ] Multi-language support
- [ ] Custom theme editor
- [ ] Batch processing
- [ ] VBMeta patching integration
- [ ] macOS and Windows support

## License

MIT License - See LICENSE file for details

## Credits

- **GUI Framework**: Qt6
- **Design Inspiration**: KDE Breeze Theme & KDE HIG
- **Backend**: Zilium Super Compactor CLI
- **AOSP Tools**: lpmake, lpunpack, lpdump

## Support

- **Issues**: [GitHub Issues](https://github.com/Badmaneers/zilium/issues)
- **Documentation**: See `docs/` folder
- **CLI Documentation**: See main README.md

---

Made with ❤️ using Qt6
