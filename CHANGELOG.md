# Changelog

All notable changes to Zilium Super Compactor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Windows and macOS support
- Multi-language support (i18n)
- Partition image preview in GUI
- Drag-and-drop file support
- VBMeta patching integration
- AppImage and Flatpak packages

---

## [1.0.0] - 2025-01-XX

### Added
- 🎉 Initial public release
- ✨ Qt6-based graphical user interface
  - Modern Material Design interface
  - Dark and light theme support
  - Real-time progress tracking
  - Interactive partition table
  - Configuration validation
  - Built-in user guide and license viewer
- 🖥️ Command-line interface (CLI)
  - Full-featured CLI for automation
  - Verbose logging mode
  - Dry-run validation
  - Flexible partition exclusion
- 🔧 Core functionality
  - Smart super partition size optimization
  - Stock VBMeta compatibility
  - A/B and non-A/B device support
  - Multi-partition handling
  - Automatic metadata generation
- 📚 Comprehensive documentation
  - User guide
  - Installation guide
  - CLI reference
  - FAQ
  - Contributing guidelines
- 🛠️ Build system
  - CMake build configuration
  - Separate CLI and GUI builds
  - Build scripts for easy compilation
- 🎨 Resources
  - Custom Zilium logo (SVG)
  - Telegram and GitHub icons
  - Material Design color scheme
- ✅ Validation and error handling
  - Configuration file validation
  - Partition size verification
  - File existence checks
  - Clear error messages

### Technical Details
- **Languages**: C++17, QML
- **GUI Framework**: Qt 6.2+
- **JSON Parsing**: nlohmann/json 3.11.2
- **AOSP Tools**: lpmake, lpunpack, lpdump (included)
- **Platform**: Linux (Ubuntu 20.04+, Arch, Fedora)
- **License**: MIT

### Known Issues
- GUI only available on Linux
- No automatic updates (manual git pull required)
- Large super partitions (>8GB) may be slow on HDD

---

## Development Milestones

### Pre-release Development

#### v0.5.0 - GUI Development
- Implemented Qt6 GUI framework
- Created QML-based user interface
- Added partition table view
- Integrated console log display

#### v0.4.0 - CLI Refinement
- Improved command-line argument parsing
- Added verbose logging
- Implemented dry-run mode
- Enhanced error messages

#### v0.3.0 - Core Features
- Implemented super partition building
- Added size optimization algorithm
- Integrated AOSP lpmake tool
- Configuration parsing with nlohmann/json

#### v0.2.0 - Prototype
- Basic functionality proof of concept
- JSON config loading
- Simple partition handling

#### v0.1.0 - Initial Commit
- Project structure setup
- Basic CMake configuration
- README and license

---

## Version Naming

Zilium follows Semantic Versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Incompatible API changes
- **MINOR**: New features (backwards-compatible)
- **PATCH**: Bug fixes (backwards-compatible)

---

## Release Schedule

- **Major releases** (X.0.0): 6-12 months
- **Minor releases** (X.Y.0): 1-3 months
- **Patch releases** (X.Y.Z): As needed for critical bugs

---

## How to Upgrade

### From Source

```bash
cd zilium
git pull origin main
git submodule update --init --recursive
./build.sh
./build-gui.sh
```

### Binary Releases (Future)

```bash
# Download latest release
wget https://github.com/Badmaneers/zilium/releases/latest/download/zilium-linux-x86_64.tar.gz

# Extract and install
tar -xzf zilium-linux-x86_64.tar.gz
sudo cp zilium-linux-x86_64/bin/* /usr/local/bin/
```

---

## Migration Guides

### Migrating to 1.0.0 from Pre-release

If you were using development versions:

1. **Backup your configs**: Configuration format is stable
2. **Clean rebuild**: Delete old build directory
3. **Update paths**: Check if binary paths changed
4. **Review docs**: Some CLI flags may have changed

No breaking changes expected for configuration files.

---

## Deprecation Policy

- Deprecated features will be marked in documentation
- Maintained for at least one major version
- Warnings shown in console output
- Removal announced in advance

---

## Security Updates

Security issues will be patched immediately:
- Critical: Within 24-48 hours
- High: Within 1 week
- Medium/Low: Next minor release

Report security issues to: [GitHub Security](https://github.com/Badmaneers/zilium/security)

---

## Contributors

### v1.0.0
- **Badmaneers** - Initial development and release

Special thanks to:
- AOSP team for LP tools
- Qt Project for the framework
- Niels Lohmann for JSON library
- KDE team for design inspiration
- All testers and early adopters

---

## Links

- **Homepage**: https://github.com/Badmaneers/zilium
- **Releases**: https://github.com/Badmaneers/zilium/releases
- **Issues**: https://github.com/Badmaneers/zilium/issues
- **Telegram**: https://t.me/DumbDragon

---

[Unreleased]: https://github.com/Badmaneers/zilium/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Badmaneers/zilium/releases/tag/v1.0.0
