# Windows Support Documentation

Complete guide for using Zilium Super Compactor on Windows, including platform-specific features and UI optimizations.

## Table of Contents

- [Overview](#overview)
- [Windows Installation](#windows-installation)
- [Building on Windows](#building-on-windows)
- [Windows-Specific Features](#windows-specific-features)
- [Platform Differences](#platform-differences)
- [Troubleshooting Windows Issues](#troubleshooting-windows-issues)
- [Deployment](#deployment)

---

## Overview

Zilium Super Compactor now supports Windows with a dedicated, optimized GUI experience. The Windows build includes:

- **Windows-specific UI optimizations** for proper layout rendering
- **Native Windows theming** with Material Design
- **Prebuilt AOSP LP tools** (no Linux dependency)
- **MSI installer** for easy deployment
- **Qt 6.9.3** integration with MSVC 2022

### Platform Detection

The application automatically detects the platform at runtime:

```cpp
#ifdef Q_OS_WIN
    // Load Windows-optimized QML
    const QUrl url(u"qrc:/ZiliumGUI/qml/main_windows.qml"_qs);
#else
    // Load standard QML for Linux/macOS
    const QUrl url(u"qrc:/ZiliumGUI/qml/main.qml"_qs);
#endif
```

This ensures the best experience on each platform without code duplication.

---

## Windows Installation

### System Requirements

**Minimum:**
- **OS**: Windows 10 (Build 1809 or later) or Windows 11
- **RAM**: 4 GB
- **Storage**: 10 GB free space
- **Display**: 1280x720 resolution

**Recommended:**
- **OS**: Windows 11
- **RAM**: 8 GB or more
- **Storage**: SSD with 20 GB+ free space
- **Display**: 1920x1080 resolution
- **GPU**: DirectX 11 compatible graphics

### Pre-built Installer (Recommended)

1. **Download the latest release:**
   ```
   https://github.com/Badmaneers/zilium/releases/latest
   ```

2. **Run the installer:**
   - Download `Zilium-Setup-x64.exe`
   - Double-click to run
   - Follow installation wizard
   - Choose installation directory
   - Create desktop shortcut (optional)

3. **Launch application:**
   - Start Menu → Zilium Super Compactor
   - Or double-click desktop shortcut
   - Or run from installation directory

### Portable Version

1. **Download portable package:**
   ```
   https://github.com/Badmaneers/zilium/releases/latest
   ```

2. **Extract to desired location:**
   - Download `Zilium-Portable-x64.zip`
   - Extract to `C:\Tools\Zilium\` or any location
   - No installation required

3. **Run directly:**
   ```powershell
   cd C:\Tools\Zilium
   .\zilium-gui.exe
   ```

### Silent Installation (for IT Deployment)

```powershell
# Silent install to default location
.\Zilium-Setup-x64.exe /S

# Silent install to custom location
.\Zilium-Setup-x64.exe /S /D=C:\Program Files\Zilium
```

---

## Building on Windows

### Prerequisites

1. **Visual Studio 2022**
   - Community edition (free) or Professional/Enterprise
   - Install "Desktop development with C++" workload
   - Include MSVC v143 compiler
   - Include Windows 10/11 SDK

2. **CMake 3.20+**
   ```powershell
   # Using winget (Windows 11)
   winget install Kitware.CMake
   
   # Or download from https://cmake.org/download/
   ```

3. **Qt 6.9.3 for MSVC 2022**
   - Download Qt Online Installer: https://www.qt.io/download-open-source
   - Install Qt 6.9.3
   - Select components:
     - MSVC 2022 64-bit
     - Qt Quick Controls 2
     - Qt SVG
     - Qt 5 Compatibility Module

4. **Git for Windows**
   ```powershell
   winget install Git.Git
   ```

### Build Steps

#### Option 1: Using build-windows.bat (Recommended)

```batch
REM Clone repository
git clone https://github.com/Badmaneers/zilium.git
cd zilium

REM Edit build-windows.bat to set Qt path
REM Set QTDIR to your Qt installation, e.g.:
REM set QTDIR=C:\Qt\6.9.3\msvc2022_64

REM Build everything
build-windows.bat
```

The script will:
1. Configure CMake with Visual Studio generator
2. Build CLI tool
3. Build GUI application
4. Copy Qt dependencies
5. Create deployment package

Output location: `build\Release\`

#### Option 2: Manual CMake Build

```powershell
# Set Qt path
$env:CMAKE_PREFIX_PATH = "C:\Qt\6.9.3\msvc2022_64"

# Create build directory
mkdir build
cd build

# Configure with Visual Studio 2022
cmake .. -G "Visual Studio 17 2022" -A x64

# Build Release configuration
cmake --build . --config Release --target zilium-gui

# Deploy Qt dependencies
C:\Qt\6.9.3\msvc2022_64\bin\windeployqt.exe `
  --qmldir ..\gui\qml `
  Release\gui\zilium-gui.exe
```

#### Option 3: Using PowerShell Script

```powershell
# Run automated build script
.\deploy-windows.ps1 -QtPath "C:\Qt\6.9.3\msvc2022_64"
```

### Build Options

```batch
REM Build only CLI
cmake --build build --config Release --target zilium-super-compactor

REM Build only GUI
cmake --build build --config Release --target zilium-gui

REM Build with verbose output
cmake --build build --config Release --target zilium-gui --verbose

REM Build Debug version (for development)
cmake --build build --config Debug --target zilium-gui
```

---

## Windows-Specific Features

### 1. Optimized UI Layout

The Windows GUI uses a specially designed layout (`main_windows.qml`) with:

#### Compact Design
- **Smaller font sizes**: Labels 11px, Fields 10px (vs 12px/11px on Linux)
- **Reduced spacing**: 4-6px between elements (vs 8-12px on Linux)
- **Tighter margins**: 8px window margins (vs 12px on Linux)
- **Shorter fields**: 28px height text fields (vs 32px on Linux)

#### Explicit Height Management
```qml
// Windows-specific layout
RowLayout {
    Layout.fillWidth: true
    Layout.preferredHeight: Math.max(200, Math.min(250, window.height * 0.32))
    Layout.minimumHeight: 180
    Layout.alignment: Qt.AlignTop  // Critical for Windows
}
```

Linux uses `Layout.fillHeight: true`, but Windows Qt layout engine calculates available space differently, requiring explicit heights.

#### Responsive Sizing

All UI elements scale with window size:

```qml
// Button dimensions adapt to window size
Column {
    Layout.preferredWidth: Math.max(95, Math.min(110, window.width * 0.09))
    Layout.minimumWidth: 90
    spacing: 8
    
    Button {
        Layout.preferredHeight: Math.max(45, Math.min(50, window.height * 0.07))
        font.pixelSize: Math.max(9, Math.min(11, window.width * 0.008))
        text: "💾 Save"  // Single-line format with emoji
    }
}
```

**Responsive ranges:**
- Button width: 95-110px (9% of window width)
- Button height: 45-50px (7% of window height)
- Font size: 9-11px (0.8% of window width)
- Validation section: 200-250px (32% of window height)

This ensures proper layout at:
- Minimum window size: 1000x600
- Standard HD: 1920x1080
- 4K displays: 3840x2160

### 2. Fixed Dialog Windows

Windows has stricter window rendering requirements:

```qml
// Guide Dialog - Windows compatibility
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15  // Required for Windows

Window {
    id: guideWindow
    // ... window properties ...
    
    ScrollView {
        ScrollBar.vertical.policy: ScrollBar.AlwaysOn  // Force visible on Windows
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        
        Text {
            width: guideWindow.width - 100  // Extra margin for scrollbar
            wrapMode: Text.Wrap
        }
    }
}
```

**Changes from Linux version:**
- Explicit Qt Quick 2.15 imports (Windows requires specific versions)
- `ScrollBar.AlwaysOn` policy (Windows scrollbar auto-hide causes issues)
- Wider text margins (100px vs 80px) for scrollbar space
- Screen-centered positioning with `Screen.width / 2`

### 3. Material Theme Integration

Windows uses Material Design theme by default:

```cpp
// C++ initialization
#ifdef Q_OS_WIN
    QQuickStyle::setStyle("Material");
#endif
```

Provides native-like appearance with:
- Accent colors matching Windows theme
- Smooth animations
- Touch-friendly controls (for tablets)
- Dark/Light theme support

### 4. High DPI Support

Automatic scaling for high-resolution displays:

```cpp
// Enabled in main.cpp
QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
QGuiApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
```

Works correctly on:
- 1080p displays (100% scaling)
- 1440p displays (125% scaling)
- 4K displays (150-200% scaling)

### 5. Windows-Specific File Paths

The application handles Windows path formats:

```cpp
// Automatic path conversion
QString path = QDir::toNativeSeparators(filePath);
// Linux: /home/user/config.json
// Windows: C:\Users\User\config.json
```

---

## Platform Differences

### UI Layout

| Feature | Linux | Windows |
|---------|-------|---------|
| Super Info Labels | 12px | 11px |
| Text Field Font | 11px | 10px |
| Text Field Height | 32px | 28px |
| Row Spacing | 8px | 4px |
| Column Spacing | 16px | 12px |
| Button Width | Fixed 100px | Responsive 95-110px |
| Button Height | Fixed 50px | Responsive 45-50px |
| Validation Layout | `fillHeight: true` | Explicit height + responsive |
| Button Text Format | Multi-line possible | Single-line required |

### File Dialogs

**Linux:**
```qml
FileDialog {
    folder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    // Opens at: /home/username/
}
```

**Windows:**
```qml
FileDialog {
    folder: StandardPaths.writableLocation(StandardPaths.HomeLocation)
    // Opens at: C:\Users\Username\
}
```

Native dialogs are used on both platforms.

### Path Separators

**Linux:** Forward slash `/`
```
/home/user/rom/system.img
```

**Windows:** Backslash `\` (automatically converted)
```
C:\Users\User\ROM\system.img
```

Qt handles conversion automatically with `QDir::toNativeSeparators()`.

### LP Tools Location

**Linux:**
```bash
zilium/lpunpack_and_lpmake/bin/lpmake
zilium/lpunpack_and_lpmake/bin/lpunpack
```

**Windows:**
```batch
zilium\lpunpack_and_lpmake\bin\lpmake.exe
zilium\lpunpack_and_lpmake\bin\lpunpack.exe
```

Built using MinGW-w64 cross-compilation from Linux sources.

---

## Troubleshooting Windows Issues

### Issue 1: GUI Window Too Small / Cut Off

**Symptom:** Validation section or buttons cut off at bottom of window.

**Cause:** Windows Qt layout engine calculates `Layout.fillHeight` differently than Linux.

**Solution:** Already fixed in `main_windows.qml` with explicit heights:
```qml
Layout.preferredHeight: Math.max(200, Math.min(250, window.height * 0.32))
Layout.minimumHeight: 180
```

**Workaround if you see this:** Maximize the window or resize to at least 1000x600.

### Issue 2: Button Text Shows "..."

**Symptom:** Buttons display truncated text like "💾..." instead of "💾 Save".

**Cause:** Multi-line button text (`"💾\nSave"`) too wide for button on Windows.

**Solution:** Already fixed in `main_windows.qml`:
```qml
text: "💾 Save"  // Single-line format
Layout.preferredWidth: Math.max(95, Math.min(110, window.width * 0.09))
```

**Manual Fix:** Edit `main_windows.qml`, change button text from `"💾\nSave"` to `"💾 Save"`.

### Issue 3: Scrollbars Not Appearing in Dialogs

**Symptom:** License or Guide window content extends beyond visible area, no scrollbar.

**Cause:** Windows auto-hides scrollbars by default in Qt Quick.

**Solution:** Already fixed in `LicenseWindow.qml` and `GuideDialog.qml`:
```qml
ScrollBar.vertical.policy: ScrollBar.AlwaysOn
ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
```

### Issue 4: Qt6 DLLs Not Found

**Symptom:** "Cannot start program, missing Qt6Core.dll" or similar error.

**Cause:** Qt runtime libraries not deployed with executable.

**Solution:**
```powershell
# Run windeployqt to copy dependencies
cd build\Release\gui
C:\Qt\6.9.3\msvc2022_64\bin\windeployqt.exe zilium-gui.exe --qmldir ..\..\..\gui\qml
```

Or use `build-windows.bat` which does this automatically.

### Issue 5: MSVCP140.dll Missing

**Symptom:** "MSVCP140.dll was not found" error on startup.

**Cause:** Visual C++ Redistributable not installed.

**Solution:**
```powershell
# Download and install VC++ Redistributable
# https://aka.ms/vs/17/release/vc_redist.x64.exe
```

Or include redistributable in installer (recommended for distribution).

### Issue 6: Application Crashes on Startup

**Symptom:** Application crashes immediately without error message.

**Cause:** Missing QML modules or incompatible Qt version.

**Solution:**
1. Verify Qt 6.2+ is installed:
   ```powershell
   qmake --version
   ```

2. Check QML import paths:
   ```powershell
   $env:QML2_IMPORT_PATH = "C:\Qt\6.9.3\msvc2022_64\qml"
   .\zilium-gui.exe
   ```

3. Run with debug output:
   ```powershell
   $env:QT_LOGGING_RULES = "*.debug=true"
   .\zilium-gui.exe
   ```

### Issue 7: UI Elements Misaligned When Window Minimized

**Symptom:** Buttons and validation section misaligned at minimum window size (1000x600).

**Cause:** Fixed pixel sizes don't scale with window resize.

**Solution:** Already fixed with responsive sizing in `main_windows.qml`:
```qml
// Elements scale proportionally with window dimensions
Layout.preferredWidth: Math.max(95, Math.min(110, window.width * 0.09))
Layout.preferredHeight: Math.max(45, Math.min(50, window.height * 0.07))
font.pixelSize: Math.max(9, Math.min(11, window.width * 0.008))
```

### Issue 8: High DPI Scaling Issues

**Symptom:** UI elements too small or too large on high-resolution displays.

**Cause:** Windows DPI scaling not properly detected.

**Solution:** Add to `main.cpp` (already included):
```cpp
QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
QGuiApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
```

**Manual Fix:** Right-click `zilium-gui.exe` → Properties → Compatibility → Change high DPI settings → Override → System (Enhanced).

### Issue 9: LP Tools Fail to Execute

**Symptom:** "lpmake.exe is not recognized" or permission denied errors.

**Cause:** LP tools not in system PATH or blocked by antivirus.

**Solution:**
1. Check LP tools location:
   ```powershell
   Test-Path .\lpunpack_and_lpmake\bin\lpmake.exe
   ```

2. Add to PATH temporarily:
   ```powershell
   $env:PATH += ";$(Get-Location)\lpunpack_and_lpmake\bin"
   ```

3. Whitelist directory in antivirus (Windows Defender):
   ```powershell
   Add-MpPreference -ExclusionPath "C:\Path\To\Zilium"
   ```

### Issue 10: Build Fails with MSVC Errors

**Symptom:** Compilation errors mentioning C++ standard or missing headers.

**Cause:** Wrong Visual Studio version or missing components.

**Solution:**
1. Verify Visual Studio 2022 installed:
   ```powershell
   & "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
   cl
   ```

2. Install C++ workload:
   - Open Visual Studio Installer
   - Modify VS 2022
   - Check "Desktop development with C++"
   - Install

3. Use correct CMake generator:
   ```powershell
   cmake .. -G "Visual Studio 17 2022" -A x64
   ```

---

## Deployment

### Creating Installer with NSIS

The project includes an NSIS installer script (`windows/installer.nsi`):

```batch
REM Build the project first
build-windows.bat

REM Install NSIS
winget install NSIS.NSIS

REM Create installer
cd windows
makensis installer.nsi

REM Output: Zilium-Setup-x64.exe
```

Installer features:
- Custom installation directory selection
- Start Menu shortcuts
- Desktop shortcut option
- Uninstaller
- Registry keys for Control Panel
- File associations (optional)

### Creating Portable Package

```powershell
# After building, create portable package
cd build\Release\gui

# Copy LP tools
Copy-Item -Recurse ..\..\..\lpunpack_and_lpmake .\

# Create zip
Compress-Archive -Path * -DestinationPath Zilium-Portable-x64.zip
```

### Distribution Checklist

Before distributing your Windows build:

- [ ] Run `windeployqt` to include Qt dependencies
- [ ] Include Visual C++ Redistributable (or installer)
- [ ] Copy LP tools (`lpunpack_and_lpmake/bin/`)
- [ ] Test on clean Windows installation
- [ ] Test on Windows 10 and Windows 11
- [ ] Test with Windows Defender enabled
- [ ] Verify high DPI displays (125%, 150%, 200%)
- [ ] Test minimum window size (1000x600)
- [ ] Validate responsive layout at various sizes
- [ ] Check all dialogs (License, Guide)
- [ ] Test theme switching
- [ ] Verify file dialogs work correctly
- [ ] Test with long file paths (260+ characters)
- [ ] Include README.txt with system requirements
- [ ] Create installer or portable package

---

## Windows vs Linux Feature Parity

| Feature | Windows | Linux | Notes |
|---------|---------|-------|-------|
| CLI Tool | ✅ | ✅ | Identical functionality |
| GUI Application | ✅ | ✅ | Windows-optimized UI |
| Qt6 Support | ✅ | ✅ | Version 6.2+ required |
| Dark Theme | ✅ | ✅ | Material theme on Windows |
| Light Theme | ✅ | ✅ | Material theme on Windows |
| LP Tools Integration | ✅ | ✅ | Prebuilt for Windows |
| File Dialogs | ✅ Native | ✅ Native | Platform-specific |
| Config JSON Support | ✅ | ✅ | Identical |
| Partition Management | ✅ | ✅ | Identical |
| Validation | ✅ | ✅ | Identical |
| Progress Tracking | ✅ | ✅ | Identical |
| Console Output | ✅ | ✅ | Identical |
| High DPI Support | ✅ | ✅ | Windows DPI aware |
| Responsive UI | ✅ | ⚠️ Partial | Windows has adaptive sizing |
| Single Binary | ❌ | ✅ | Windows needs Qt DLLs |
| Installer | ✅ NSIS | ❌ | Windows-specific |
| Package Manager | ❌ | ✅ Various | Future: winget, chocolatey |

Legend:
- ✅ Full support
- ⚠️ Partial support or different implementation
- ❌ Not available / Not applicable

---

## Technical Implementation Details

### Platform-Specific Code Paths

#### main.cpp - Platform Detection
```cpp
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>

#ifdef Q_OS_WIN
    #include <windows.h>  // Windows-specific includes
#endif

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    
    // Windows-specific initialization
    #ifdef Q_OS_WIN
        QQuickStyle::setStyle("Material");
        QGuiApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
        QGuiApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
    #endif
    
    // Platform-specific QML loading
    #ifdef Q_OS_WIN
        const QUrl url(u"qrc:/ZiliumGUI/qml/main_windows.qml"_qs);
    #else
        const QUrl url(u"qrc:/ZiliumGUI/qml/main.qml"_qs);
    #endif
    
    // ... rest of initialization
}
```

#### CMakeLists.txt - Windows Resources
```cmake
if(WIN32)
    # Add Windows resources
    target_sources(zilium-gui PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/windows/zilium.rc
        ${CMAKE_CURRENT_SOURCE_DIR}/windows/zilium.manifest
    )
    
    # Link Windows-specific libraries
    target_link_libraries(zilium-gui PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Svg
    )
    
    # Set Windows executable properties
    set_target_properties(zilium-gui PROPERTIES
        WIN32_EXECUTABLE TRUE
        LINK_FLAGS "/MANIFESTUAC:\"level='asInvoker' uiAccess='false'\""
    )
endif()
```

#### Resource File - Windows QML
```xml
<!-- qml.qrc -->
<RCC>
    <qresource prefix="/ZiliumGUI">
        <file>qml/main.qml</file>
        <file>qml/main_windows.qml</file>  <!-- Windows-specific -->
        <file>qml/GuideDialog.qml</file>
        <file>qml/LicenseWindow.qml</file>
        <file>qml/PartitionDelegate.qml</file>
        <file>qml/ThemeManager.qml</file>
    </qresource>
</RCC>
```

### QML Responsive Sizing Implementation

The Windows QML uses mathematical formulas for adaptive sizing:

```qml
// Pattern: Math.max(minimum, Math.min(maximum, window.dimension * ratio))

// Button width scales between 95-110px based on window width
Layout.preferredWidth: Math.max(95, Math.min(110, window.width * 0.09))

// Breakdown:
// 1. window.width * 0.09 = 9% of window width
// 2. Math.min(110, ...) = cap at 110px maximum
// 3. Math.max(95, ...) = floor at 95px minimum
// Result: Button width stays between 95-110px, scaling proportionally

// Button height scales between 45-50px based on window height
Layout.preferredHeight: Math.max(45, Math.min(50, window.height * 0.07))
// 7% of window height, capped between 45-50px

// Font size scales between 9-11px based on window width
font.pixelSize: Math.max(9, Math.min(11, window.width * 0.008))
// 0.8% of window width, capped between 9-11px for readability

// Validation section scales between 200-250px based on window height
Layout.preferredHeight: Math.max(200, Math.min(250, window.height * 0.32))
// 32% of window height, between 200-250px
```

This ensures proper rendering at all window sizes:
- **Minimum (1000x600)**: All elements at minimum sizes, still readable
- **HD (1920x1080)**: Comfortable sizes for standard displays
- **4K (3840x2160)**: Scaled up for high-res displays

### Why Windows Needs Special Treatment

**Layout Engine Differences:**

Linux Qt:
```qml
RowLayout {
    Layout.fillHeight: true  // Works correctly
    // Layout engine calculates remaining space accurately
}
```

Windows Qt:
```qml
RowLayout {
    Layout.fillHeight: true  // Results in zero height!
    // Layout engine misalculates with nested layouts
}
```

**Solution:** Explicit height constraints
```qml
RowLayout {
    Layout.preferredHeight: 230
    Layout.minimumHeight: 180
    Layout.maximumHeight: 300
    // Gives Windows layout engine concrete values to work with
}
```

**Responsive Evolution:**
```qml
// v1.0: Fixed height
Layout.preferredHeight: 230

// v1.1: Responsive height
Layout.preferredHeight: Math.max(200, Math.min(250, window.height * 0.32))
// Scales with window but stays within bounds
```

---

## Future Windows Enhancements

### Planned for Version 1.1
- [ ] Windows Store (MSIX) package
- [ ] Winget package manager support
- [ ] Chocolatey package
- [ ] Improved installer with auto-updates
- [ ] Windows 11 right-click context menu integration
- [ ] File association for .json config files
- [ ] Drag-and-drop file support in GUI

### Planned for Version 1.2
- [ ] PowerShell module for automation
- [ ] Windows Task Scheduler integration
- [ ] Cloud storage integration (OneDrive, Google Drive)
- [ ] Multi-language support (starting with Windows languages)

### Under Consideration
- [ ] Windows ARM64 build (for Surface devices)
- [ ] UWP (Universal Windows Platform) version
- [ ] Integration with WSL2 for Linux tools
- [ ] Windows Terminal integration

---

## Contributing to Windows Support

Want to improve Windows support? Here's how:

### Testing
- Test on different Windows versions (10, 11)
- Test with different display scaling (100%, 125%, 150%, 200%)
- Test on different screen resolutions
- Test with high-contrast themes
- Test with accessibility features enabled

### Development
- Improve responsive sizing algorithms
- Optimize performance on Windows
- Reduce installer size
- Improve error messages for Windows users
- Add Windows-specific features

### Documentation
- Add screenshots of Windows GUI
- Create video tutorials for Windows users
- Translate documentation to more languages
- Write troubleshooting guides

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## Additional Resources

### Official Documentation
- [Qt for Windows](https://doc.qt.io/qt-6/windows.html)
- [CMake on Windows](https://cmake.org/cmake/help/latest/manual/cmake-generators.7.html#visual-studio-generators)
- [MSVC Compiler Documentation](https://docs.microsoft.com/en-us/cpp/)
- [NSIS Documentation](https://nsis.sourceforge.io/Docs/)

### Community Resources
- [Qt Forum - Windows Development](https://forum.qt.io/category/23/windows)
- [Stack Overflow - Qt Windows](https://stackoverflow.com/questions/tagged/qt+windows)
- [GitHub Discussions](https://github.com/Badmaneers/zilium/discussions)

### Build Tools
- [Visual Studio 2022 Download](https://visualstudio.microsoft.com/downloads/)
- [Qt Online Installer](https://www.qt.io/download-open-source)
- [CMake Download](https://cmake.org/download/)
- [Git for Windows](https://gitforwindows.org/)

---

## Changelog

### Version 1.0.0 (October 2025)
- ✨ Initial Windows support
- ✨ Windows-optimized GUI layout (`main_windows.qml`)
- ✨ Platform-specific QML loading
- ✨ Responsive sizing for window resize
- ✨ Fixed dialog scrolling issues on Windows
- ✨ Material theme integration
- ✨ High DPI support
- ✨ NSIS installer script
- ✨ Portable package support
- 📖 Comprehensive Windows documentation

---

## Support

Need help with Windows-specific issues?

1. **Check this documentation first**
2. **Search [GitHub Issues](https://github.com/Badmaneers/zilium/issues)** for similar problems
3. **Check [FAQ](FAQ.md)** for common questions
4. **Ask on [Telegram](https://t.me/DumbDragon)**
5. **Create a new issue** with Windows-specific label

When reporting Windows issues, include:
- Windows version (Win10/Win11 and build number)
- Qt version used
- Visual Studio version
- Complete error message
- Steps to reproduce
- Screenshots if GUI-related

---

**Last Updated**: October 2025
**Documentation Version**: 1.0.0
**Applies to**: Zilium v1.0.0+

---

<p align="center">
  <b>Windows support made with ❤️ for the ROM community</b>
</p>
