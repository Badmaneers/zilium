# Installation Guide

This guide provides detailed instructions for installing Zilium Super Compactor on Linux distributions.

**For Windows installation**, see **[Windows Support Guide](WINDOWS_SUPPORT.md)**.

## Table of Contents

- [System Requirements](#system-requirements)
- [Ubuntu/Debian](#ubuntudebian)
- [Arch Linux](#arch-linux)
- [Fedora](#fedora)
- [OpenSUSE](#opensuse)
- [Other Distributions](#other-distributions)
- [Verifying Installation](#verifying-installation)
- [Troubleshooting](#troubleshooting)

## System Requirements

### Linux

#### Minimum
- **OS**: Linux (kernel 4.15+)
- **Architecture**: x86_64 (AMD64)
- **RAM**: 4 GB
- **Storage**: 10 GB free space
- **Compiler**: GCC 9+ or Clang 10+
- **CMake**: 3.20 or higher

#### Recommended
- **RAM**: 8 GB or more
- **Storage**: SSD with 20 GB+ free space
- **Display**: 1920x1080 for GUI

#### For GUI
- **Qt**: 6.2 or higher
- **OpenGL**: 2.0+ support
- **Desktop Environment**: Any (GNOME, KDE, XFCE, etc.)

### Windows

See **[Windows Support Guide](WINDOWS_SUPPORT.md)** for Windows-specific requirements and installation.

---

## Ubuntu/Debian

### Ubuntu 22.04 LTS / Debian 12+

```bash
# Update package list
sudo apt update

# Install build dependencies
sudo apt install -y \
    build-essential \
    cmake \
    git \
    pkg-config

# Install Qt6 for GUI (optional)
sudo apt install -y \
    qt6-base-dev \
    qt6-declarative-dev \
    qml6-module-qtquick-controls \
    qml6-module-qtquick-layouts \
    libqt6svg6

# Clone the repository
git clone https://github.com/Badmaneers/zilium.git
cd zilium

# Build CLI
./build.sh

# Build GUI (if Qt6 installed)
./build-gui.sh

# Install system-wide (optional)
sudo cp build/zilium-super-compactor /usr/local/bin/
sudo cp build/gui/zilium-gui /usr/local/bin/  # If GUI built
```

### Ubuntu 20.04 LTS

Qt6 is not available in Ubuntu 20.04 repositories. You have two options:

#### Option 1: CLI Only
```bash
sudo apt update
sudo apt install -y build-essential cmake git
git clone https://github.com/Badmaneers/zilium.git
cd zilium
./build.sh --cli-only
```

#### Option 2: Install Qt6 from PPA
```bash
# Add Qt6 PPA (unofficial)
sudo add-apt-repository ppa:okirby/qt6-backports
sudo apt update

# Install Qt6
sudo apt install -y qt6-base-dev qt6-declarative-dev

# Build everything
./build.sh
./build-gui.sh
```

---

## Arch Linux

### Using Official Repositories

```bash
# Install dependencies
sudo pacman -Syu
sudo pacman -S --needed \
    base-devel \
    cmake \
    git \
    qt6-base \
    qt6-declarative \
    qt6-svg

# Clone and build
git clone https://github.com/Badmaneers/zilium.git
cd zilium
./build.sh
./build-gui.sh

# Install (optional)
sudo cp build/zilium-super-compactor /usr/local/bin/
sudo cp build/gui/zilium-gui /usr/local/bin/
```

### Using AUR (Future)

```bash
# Using yay
yay -S zilium-git

# Using paru
paru -S zilium-git
```

---

## Fedora

### Fedora 36+

```bash
# Install dependencies
sudo dnf install -y \
    gcc-c++ \
    cmake \
    git \
    qt6-qtbase-devel \
    qt6-qtdeclarative-devel \
    qt6-qtsvg-devel

# Clone and build
git clone https://github.com/Badmaneers/zilium.git
cd zilium
./build.sh
./build-gui.sh

# Install (optional)
sudo cp build/zilium-super-compactor /usr/local/bin/
sudo cp build/gui/zilium-gui /usr/local/bin/
```

---

## OpenSUSE

### Tumbleweed

```bash
# Install dependencies
sudo zypper install -y \
    gcc-c++ \
    cmake \
    git \
    qt6-base-devel \
    qt6-declarative-devel \
    qt6-svg-devel

# Clone and build
git clone https://github.com/Badmaneers/zilium.git
cd zilium
./build.sh
./build-gui.sh
```

### Leap 15.4+

```bash
# Add Qt6 repository
sudo zypper addrepo https://download.opensuse.org/repositories/KDE:/Qt6/openSUSE_Leap_15.4/ qt6

# Install dependencies
sudo zypper install -y gcc-c++ cmake git qt6-base-devel qt6-declarative-devel

# Clone and build
git clone https://github.com/Badmaneers/zilium.git
cd zilium
./build.sh
./build-gui.sh
```

---

## Other Distributions

### Generic Linux

If your distribution isn't listed above, follow these general steps:

1. **Install build tools**: gcc/g++ or clang, cmake, make, git
2. **Install Qt6** (for GUI): qt6-base, qt6-declarative, qt6-quickcontrols
3. **Clone and build**:
   ```bash
   git clone https://github.com/Badmaneers/zilium.git
   cd zilium
   ./build.sh
   ./build-gui.sh  # If Qt6 available
   ```

### Using Flatpak (Future)

```bash
# Add Flathub
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install Zilium (when available)
flatpak install flathub io.github.badmaneers.zilium
```

### Using AppImage (Future)

```bash
# Download AppImage
wget https://github.com/Badmaneers/zilium/releases/latest/download/Zilium-x86_64.AppImage

# Make executable
chmod +x Zilium-x86_64.AppImage

# Run
./Zilium-x86_64.AppImage
```

---

## Verifying Installation

### Check CLI Installation

```bash
# Check if binary exists
which zilium-super-compactor

# Check version
./build/zilium-super-compactor --version

# Expected output:
# Zilium Super Compactor v1.0.0
# Built: [date]
```

### Check GUI Installation

```bash
# Check if GUI binary exists
which zilium-gui

# Run GUI
./build/gui/zilium-gui

# GUI should launch without errors
```

### Test Build

```bash
# Navigate to test directory
cd zilium/tests

# Run test build (if test data available)
../build/zilium-super-compactor -c test_config.json -o test_output/

# Check output
ls -lh test_output/super.img
```

---

## Troubleshooting

### Qt6 Not Found

**Error**: `Could NOT find Qt6 (missing: Qt6_DIR)`

**Solution**:
```bash
# Find Qt6 installation
find /usr -name "Qt6Config.cmake" 2>/dev/null

# Set Qt6_DIR explicitly
export Qt6_DIR=/usr/lib/x86_64-linux-gnu/cmake/Qt6
cmake -DQt6_DIR=$Qt6_DIR ..
```

### CMake Version Too Old

**Error**: `CMake 3.20 or higher is required`

**Solution on Ubuntu 20.04**:
```bash
# Remove old CMake
sudo apt remove cmake

# Add Kitware repository
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
sudo apt-add-repository 'deb https://apt.kitware.com/ubuntu/ focal main'

# Install latest CMake
sudo apt update
sudo apt install cmake
```

### Missing Dependencies

**Error**: `fatal error: json.hpp: No such file or directory`

**Solution**:
```bash
# The json library is included in external/
# Make sure you cloned with submodules:
git submodule update --init --recursive

# Or clone again with --recursive
git clone --recursive https://github.com/Badmaneers/zilium.git
```

### Build Fails on Low Memory

**Error**: `g++: fatal error: Killed signal terminated program cc1plus`

**Solution**:
```bash
# Reduce parallel jobs
./build.sh -j2  # Use only 2 cores

# Or disable parallel builds entirely
./build.sh -j1
```

### GUI Doesn't Start

**Error**: `error while loading shared libraries: libQt6Core.so.6`

**Solution**:
```bash
# Add Qt6 libraries to path
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

# Make permanent (add to ~/.bashrc)
echo 'export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH' >> ~/.bashrc
```

---

## Post-Installation

### Create Desktop Entry (Linux GUI)

```bash
# Create desktop file
cat > ~/.local/share/applications/zilium.desktop << EOF
[Desktop Entry]
Name=Zilium Super Compactor
Comment=Build Android super partition images
Exec=/usr/local/bin/zilium-gui
Icon=zilium
Terminal=false
Type=Application
Categories=Development;Utility;
EOF

# Update desktop database
update-desktop-database ~/.local/share/applications/
```

### Add to PATH

```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'export PATH="$HOME/zilium/build:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Now you can run from anywhere
zilium-super-compactor --version
```

### Enable Shell Completion (Future Feature)

```bash
# Bash
zilium-super-compactor --completion bash > ~/.local/share/bash-completion/completions/zilium

# Zsh
zilium-super-compactor --completion zsh > ~/.local/share/zsh/site-functions/_zilium
```

---

## Uninstallation

### Remove Binaries

```bash
# If installed system-wide
sudo rm /usr/local/bin/zilium-super-compactor
sudo rm /usr/local/bin/zilium-gui

# If using local build
rm -rf ~/zilium
```

### Remove Desktop Entry

```bash
rm ~/.local/share/applications/zilium.desktop
update-desktop-database ~/.local/share/applications/
```

---

## Getting Help

If you encounter issues not covered here:

1. Check [Troubleshooting Guide](TROUBLESHOOTING.md)
2. Search [GitHub Issues](https://github.com/Badmaneers/zilium/issues)
3. Ask on [Telegram](https://t.me/DumbDragon)
4. Create a new issue with:
   - Your OS and version
   - Build output/error messages
   - Steps to reproduce

---

**Next**: Read the [User Guide](USER_GUIDE.md) to learn how to use Zilium.
