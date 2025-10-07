#!/bin/bash

# Zilium Super Compactor - Complete Setup & Build Script
# This script handles: setup, build, and release packaging

set -e  # Exit on error

# Script version
VERSION="1.0.0"

# Build mode
BUILD_MODE="Debug"
CREATE_RELEASE=false
CLEAN_BUILD=false
BUILD_GUI=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Print functions
print_header() {
    echo -e "${BLUE}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  Zilium Super Compactor v${VERSION}         ║${NC}"
    echo -e "${BLUE}║  Build Mode: ${BUILD_MODE}                    ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════╝${NC}"
    echo ""
}

print_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Options:
  -h, --help          Show this help message
  -r, --release       Build in release mode with optimizations
  -c, --clean         Clean build directory before building
  -p, --package       Create release package (tar.gz)
  -g, --gui           Build Qt6 GUI application (requires Qt6)
  
Build Modes:
  Debug (default)     Build with debug symbols
  Release (-r)        Build optimized for distribution
  
Examples:
  $0                          # Debug build
  $0 --release                # Release build
  $0 --release --package      # Release build + create package
  $0 --clean --release        # Clean + Release build
  $0 --gui                    # Build CLI + GUI
  $0 --release --gui --package  # Build everything and package

EOF
    exit 0
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

print_step() {
    echo -e "${BLUE}→${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_usage
                ;;
            -r|--release)
                BUILD_MODE="Release"
                shift
                ;;
            -c|--clean)
                CLEAN_BUILD=true
                shift
                ;;
            -p|--package)
                CREATE_RELEASE=true
                BUILD_MODE="Release"  # Force release mode for packaging
                shift
                ;;
            -g|--gui)
                BUILD_GUI=true
                shift
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                print_usage
                ;;
        esac
    done
}

# Create release package
create_release_package() {
    print_section "Creating Release Package"
    
    local RELEASE_DIR="zilium-super-compactor-v${VERSION}_$(uname -s)_$(uname -m)"
    local PACKAGE_NAME="${RELEASE_DIR}.tar.gz"
    
    print_step "Preparing release directory..."
    rm -rf "dist/${RELEASE_DIR}"
    mkdir -p "dist/${RELEASE_DIR}/bin"
    
    # Copy binaries
    print_step "Copying binaries..."
    cp build/zilium-super-compactor "dist/${RELEASE_DIR}/bin/"
    cp lptools-prebuilt/linux/lpmake "dist/${RELEASE_DIR}/bin/" 2>/dev/null || true
    cp lptools-prebuilt/linux/lpunpack "dist/${RELEASE_DIR}/bin/" 2>/dev/null || true
    cp lptools-prebuilt/linux/lpdump "dist/${RELEASE_DIR}/bin/" 2>/dev/null || true
    
    # Copy GUI binary if it exists
    local HAS_GUI=false
    if [ -f "build/gui/zilium-gui" ]; then
        print_step "Copying GUI binary..."
        cp build/gui/zilium-gui "dist/${RELEASE_DIR}/bin/"
        HAS_GUI=true
        print_success "GUI binary included in package"
    fi
    
    # Strip binaries for smaller size
    print_step "Stripping debug symbols..."
    strip "dist/${RELEASE_DIR}/bin/"* 2>/dev/null || true
    
    # Copy license
    if [ -f "LICENSE" ]; then
        print_step "Copying license..."
        cp LICENSE "dist/${RELEASE_DIR}/"
        print_success "License file included"
    fi
    
    # Create run.sh script for GUI
    if [ "$HAS_GUI" = true ]; then
        print_step "Creating run.sh launcher..."
        cat > "dist/${RELEASE_DIR}/run.sh" << 'RUN_SCRIPT_EOF'
#!/bin/bash

# Zilium GUI Launcher Script
# This script ensures the GUI runs with the correct library paths

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUI_BINARY="${SCRIPT_DIR}/bin/zilium-gui"

# Check if GUI binary exists
if [ ! -f "$GUI_BINARY" ]; then
    echo "Error: zilium-gui not found at $GUI_BINARY"
    echo "This package may not include the GUI component."
    echo ""
    echo "To use the CLI tool instead:"
    echo "  ./bin/zilium-super-compactor <rom-folder>"
    exit 1
fi

# Check if binary is executable
if [ ! -x "$GUI_BINARY" ]; then
    echo "Making GUI binary executable..."
    chmod +x "$GUI_BINARY"
fi

# Add bin directory to PATH for LP tools
export PATH="${SCRIPT_DIR}/bin:${PATH}"

# Launch GUI
echo "Starting Zilium Super Compactor GUI..."
cd "$SCRIPT_DIR"
exec "$GUI_BINARY" "$@"
RUN_SCRIPT_EOF
        chmod +x "dist/${RELEASE_DIR}/run.sh"
        print_success "run.sh launcher created"
    fi
    
    # Create comprehensive README.txt for package
    print_step "Creating README.txt..."
    cat > "dist/${RELEASE_DIR}/README.txt" << README_EOF
╔═══════════════════════════════════════════════════════════╗
║         Zilium Super Compactor v${VERSION}                    ║
║    Advanced Super Partition Image Rebuilder              ║
╚═══════════════════════════════════════════════════════════╝

ABOUT
-----
Zilium Super Compactor is a powerful tool that combines split 
super partition images into a single, optimized super.img file
for Realme, OPPO, and OnePlus devices while maintaining full
compatibility with stock vbmeta verification.

KEY FEATURES
------------
✓ Stock VBMeta Compatible   - Works with locked bootloaders
✓ A/B & Non-A/B Support     - Handles both slot configurations  
✓ Self-Contained            - All tools bundled, no dependencies
✓ Fast & Efficient          - Optimized C++ implementation
✓ Auto-Detection            - Reads original OEM parameters
✓ GUI & CLI Modes           - Choose your preferred interface

PACKAGE CONTENTS
----------------
$(if [ "$HAS_GUI" = true ]; then echo "  run.sh                      - Quick launcher for GUI"; fi)
  bin/zilium-super-compactor  - Main CLI tool
$(if [ "$HAS_GUI" = true ]; then echo "  bin/zilium-gui              - Qt6 GUI application"; fi)
  bin/lpmake                  - LP partition tool (bundled)
  bin/lpunpack                - LP unpacker (bundled)
  bin/lpdump                  - LP metadata dumper (bundled)
  README.txt                  - This file
  LICENSE                     - MIT License

QUICK START
-----------
$(if [ "$HAS_GUI" = true ]; then 
echo "GUI Mode (Recommended for Beginners):
  1. Make the launcher executable:
     chmod +x run.sh
  
  2. Run the GUI:
     ./run.sh
  
  3. Use the graphical interface to:
     - Select your ROM folder
     - Choose output location
     - Monitor real-time progress
     - Validate and verify output

"; fi)CLI Mode (Advanced Users):
  1. Make the binary executable:
     chmod +x bin/zilium-super-compactor
  
  2. Run the tool:
     ./bin/zilium-super-compactor /path/to/rom/folder
  
  Example:
     ./bin/zilium-super-compactor ~/Downloads/ColorOS_A.15/

USAGE EXAMPLES
--------------
# Extract firmware first (if needed)
unzip RMX3500_11_F.29_*.ofp

# Run Zilium$(if [ "$HAS_GUI" = true ]; then echo " GUI"; fi)
$(if [ "$HAS_GUI" = true ]; then echo "./run.sh"; else echo "./bin/zilium-super-compactor RMX3500_11_F.29/"; fi)

# Or use CLI directly
./bin/zilium-super-compactor RMX3500_11_F.29/

# Output will be in RMX3500_11_F.29/super_new.img

SYSTEM REQUIREMENTS
-------------------
• Linux (Ubuntu 20.04+, Arch, Fedora, etc.)
• 64-bit x86_64 architecture
$(if [ "$HAS_GUI" = true ]; then echo "• Qt6 libraries (for GUI)
  Ubuntu/Debian: sudo apt install qt6-base-dev
  Arch Linux: sudo pacman -S qt6-base
  Fedora: sudo dnf install qt6-qtbase"; fi)
• Sufficient disk space (2-3x super partition size)

WORKFLOW
--------
1. Extract your device's ROM/OTA package
2. Run Zilium on the extracted folder
3. Wait for processing to complete
4. Find output at: <rom-folder>/super_new.img
5. Flash using fastboot or recovery tools

TROUBLESHOOTING
---------------
Q: Permission denied when running scripts
A: Make them executable: chmod +x run.sh bin/*

Q: GUI won't start
A: Install Qt6 libraries (see System Requirements)
   Or use CLI mode: ./bin/zilium-super-compactor <folder>

Q: "lpmake not found" error
A: Ensure you run from package directory, not bin/
   The tool auto-detects bundled lpmake

Q: Output image verification failed
A: Check that all partition .img files exist
   Verify sufficient disk space available

$(if [ "$HAS_GUI" = true ]; then echo "Q: GUI shows 'Loading license...' forever
A: This is a known visual bug, doesn't affect functionality
   Click outside the dialog to dismiss it
"; fi)
SUPPORT & LINKS
---------------
• GitHub:   https://github.com/Badmaneers/zilium
• Issues:   https://github.com/Badmaneers/zilium/issues
• Telegram: @DumbDragon

LICENSE
-------
MIT License - See LICENSE file for full text
Copyright (c) 2025 Badmaneers

BUILD INFORMATION
-----------------
Version:      ${VERSION}
Build Mode:   ${BUILD_MODE}
Build Date:   $(date '+%Y-%m-%d %H:%M:%S')
System:       $(uname -s) $(uname -m)
Compiler:     $(g++ --version | head -n1 2>/dev/null || echo "Unknown")
$(if [ "$HAS_GUI" = true ]; then echo "GUI:          Qt6 (Included)"; fi)

CREDITS
-------
• LP Tools:      Android Open Source Project (AOSP)
• nlohmann/json: Niels Lohmann
• Qt Framework:  The Qt Company Ltd.
• Developer:     Badmaneers

═══════════════════════════════════════════════════════════
Thank you for using Zilium Super Compactor!
═══════════════════════════════════════════════════════════
README_EOF
    print_success "README.txt created"
    
    # Make all scripts executable
    print_step "Setting executable permissions..."
    chmod +x "dist/${RELEASE_DIR}/bin/"* 2>/dev/null || true
    if [ -f "dist/${RELEASE_DIR}/run.sh" ]; then
        chmod +x "dist/${RELEASE_DIR}/run.sh"
    fi
    print_success "Permissions set"
    
    # Create tarball
    print_step "Creating tarball..."
    cd dist
    tar -czf "${PACKAGE_NAME}" "${RELEASE_DIR}"
    cd ..
    
    # Calculate checksums
    print_step "Generating checksums..."
    cd dist
    sha256sum "${PACKAGE_NAME}" > "${PACKAGE_NAME}.sha256"
    md5sum "${PACKAGE_NAME}" > "${PACKAGE_NAME}.md5"
    cd ..
    
    # Create distribution info file
    print_step "Creating distribution info..."
    cat > "dist/${RELEASE_DIR}.info" << INFO_EOF
Package: zilium-super-compactor
Version: ${VERSION}
Architecture: $(uname -m)
Platform: $(uname -s)
Build-Date: $(date -u +%Y-%m-%dT%H:%M:%SZ)
Build-Mode: ${BUILD_MODE}
GUI-Included: ${HAS_GUI}
Package-File: ${PACKAGE_NAME}
Package-Size: $(du -h "dist/${PACKAGE_NAME}" | cut -f1)
SHA256: $(cat "dist/${PACKAGE_NAME}.sha256" | cut -d' ' -f1)
MD5: $(cat "dist/${PACKAGE_NAME}.md5" | cut -d' ' -f1)
INFO_EOF
    
    print_success "Release package created: dist/${PACKAGE_NAME}"
    print_info "Package size: $(du -h dist/${PACKAGE_NAME} | cut -f1)"
    echo ""
    echo -e "${CYAN}Package Contents:${NC}"
    echo "  • CLI tool: zilium-super-compactor"
    echo "  • LP tools: lpmake, lpunpack, lpdump"
    if [ "$HAS_GUI" = true ]; then
        echo "  • GUI application: zilium-gui"
        echo "  • Quick launcher: run.sh"
    fi
    echo "  • Documentation: README.txt"
    echo "  • License: LICENSE"
    echo ""
    echo -e "${CYAN}Checksums:${NC}"
    cat "dist/${PACKAGE_NAME}.sha256"
    echo ""
    if [ "$HAS_GUI" = true ]; then
        echo -e "${GREEN}To run after extraction:${NC}"
        echo "  tar -xzf ${PACKAGE_NAME}"
        echo "  cd ${RELEASE_DIR}"
        echo "  ./run.sh"
    else
        echo -e "${GREEN}To run after extraction:${NC}"
        echo "  tar -xzf ${PACKAGE_NAME}"
        echo "  cd ${RELEASE_DIR}"
        echo "  ./bin/zilium-super-compactor <rom-folder>"
    fi
    echo ""
}

# Main setup function
main() {
    # Parse arguments first
    parse_args "$@"
    
    print_header
    
    # Clean build if requested
    if [ "$CLEAN_BUILD" = true ]; then
        print_section "Cleaning Build Directory"
        print_step "Removing build directory..."
        rm -rf build
        print_success "Build directory cleaned"
    fi
    
    # PHASE 1: Check System Requirements
    print_section "Phase 1: System Requirements"
    
    print_step "Checking for required tools..."
    
    MISSING_DEPS=()
    
    if ! command_exists git; then
        MISSING_DEPS+=("git")
    fi
    
    if ! command_exists cmake; then
        MISSING_DEPS+=("cmake")
    fi
    
    if ! command_exists g++; then
        MISSING_DEPS+=("g++")
    fi
    
    if ! command_exists make; then
        MISSING_DEPS+=("make")
    fi
    
    if [ ${#MISSING_DEPS[@]} -ne 0 ]; then
        print_error "Missing required dependencies: ${MISSING_DEPS[*]}"
        echo ""
        print_info "Please install them first:"
        echo ""
        echo "  Ubuntu/Debian:"
        echo "    sudo apt update"
        echo "    sudo apt install build-essential cmake git zlib1g-dev"
        echo ""
        echo "  Arch Linux:"
        echo "    sudo pacman -S base-devel cmake git zlib"
        echo ""
        echo "  Fedora:"
        echo "    sudo dnf install gcc-c++ cmake git zlib-devel"
        echo ""
        exit 1
    fi
    
    print_success "All system requirements met"
    print_info "Build mode: ${BUILD_MODE}"
    
    # PHASE 2: Verify Prebuilt LP Tools
    print_section "Phase 2: Verify Prebuilt LP Tools"
    
    LPTOOLS_DIR="lptools-prebuilt/linux"
    
    # Check if prebuilt LP tools exist
    if [ -d "$LPTOOLS_DIR" ]; then
        if [ -f "$LPTOOLS_DIR/lpmake" ] && [ -f "$LPTOOLS_DIR/lpunpack" ] && [ -f "$LPTOOLS_DIR/lpdump" ]; then
            print_success "Prebuilt LP tools found:"
            print_info "  ✓ lpmake:   $LPTOOLS_DIR/lpmake"
            print_info "  ✓ lpunpack: $LPTOOLS_DIR/lpunpack"
            print_info "  ✓ lpdump:   $LPTOOLS_DIR/lpdump"
            
            # Make sure they're executable
            chmod +x "$LPTOOLS_DIR/lpmake" "$LPTOOLS_DIR/lpunpack" "$LPTOOLS_DIR/lpdump" 2>/dev/null || true
        else
            print_error "Some prebuilt LP tools are missing in $LPTOOLS_DIR"
            [ ! -f "$LPTOOLS_DIR/lpmake" ] && print_error "  ✗ Missing: lpmake"
            [ ! -f "$LPTOOLS_DIR/lpunpack" ] && print_error "  ✗ Missing: lpunpack"
            [ ! -f "$LPTOOLS_DIR/lpdump" ] && print_error "  ✗ Missing: lpdump"
            echo ""
            print_info "Please ensure all LP tools are in $LPTOOLS_DIR/"
            exit 1
        fi
    else
        print_error "Prebuilt LP tools directory not found: $LPTOOLS_DIR"
        echo ""
        print_info "Expected directory structure:"
        print_info "  lptools-prebuilt/"
        print_info "  ├── linux/"
        print_info "  │   ├── lpmake"
        print_info "  │   ├── lpunpack"
        print_info "  │   └── lpdump"
        print_info "  └── win/"
        print_info "      ├── lpmake.exe"
        print_info "      ├── lpunpack.exe"
        print_info "      └── lpdump.exe"
        exit 1
    fi

    # PHASE 3: Build Zilium Super Compactor
    print_section "Phase 3: Build Zilium Super Compactor"

    print_step "Creating build directory..."
    mkdir -p build
    
    print_step "Configuring CMake (${BUILD_MODE} mode)..."
    cd build
    
    # Determine GUI build flag for CMake
    if [ "$BUILD_GUI" = true ]; then
        CMAKE_GUI_FLAG="-DBUILD_GUI=ON"
        print_info "GUI build enabled"
    else
        CMAKE_GUI_FLAG="-DBUILD_GUI=OFF"
    fi
    
    if [ "$BUILD_MODE" = "Release" ]; then
        print_info "Enabling compiler optimizations (-O3, -march=native)"
        if ! cmake -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_CXX_FLAGS_RELEASE="-O3 -march=native -DNDEBUG" \
              ${CMAKE_GUI_FLAG} \
              .. ; then
            print_error "CMake configuration failed"
            cd ..
            exit 1
        fi
    else
        if ! cmake -DCMAKE_BUILD_TYPE=Debug ${CMAKE_GUI_FLAG} .. ; then
            print_error "CMake configuration failed"
            cd ..
            exit 1
        fi
    fi
    print_success "CMake configured"
    
    print_step "Compiling zilium_super_compactor..."
    CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    print_info "Using ${CORES} CPU cores"
    if ! make -j$CORES 2>&1 | tee make.log ; then
        print_error "Compilation failed"
        echo ""
        print_info "Check make.log for details"
        cd ..
        exit 1
    fi
    print_success "Compilation complete"
    
    cd ..
    
    # Verify CLI binary
    if [ -f "build/zilium-super-compactor" ]; then
        BINARY_SIZE=$(du -h build/zilium-super-compactor | cut -f1)
        print_success "zilium-super-compactor binary created (${BINARY_SIZE})"
    else
        print_error "Failed to build zilium-super-compactor"
        exit 1
    fi
    
    # Verify GUI binary if requested
    if [ "$BUILD_GUI" = true ]; then
        if [ -f "build/gui/zilium-gui" ]; then
            GUI_SIZE=$(du -h build/gui/zilium-gui | cut -f1)
            print_success "zilium-gui binary created (${GUI_SIZE})"
        else
            print_error "Failed to build zilium-gui"
            print_info "Qt6 might not be installed or there was a compilation error"
            print_info "Install Qt6: sudo apt install qt6-base-dev qt6-declarative-dev"
            print_info "Check build/make.log for details"
        fi
    fi
    
    # Strip binary in release mode
    if [ "$BUILD_MODE" = "Release" ]; then
        print_step "Stripping debug symbols for smaller binary..."
        strip build/zilium-super-compactor
        STRIPPED_SIZE=$(du -h build/zilium-super-compactor | cut -f1)
        print_success "Binary stripped (${STRIPPED_SIZE})"
        
        if [ "$BUILD_GUI" = true ]; then
            if [ -f "build/gui/zilium-gui" ]; then
                strip build/gui/zilium-gui 2>/dev/null || true
                print_success "GUI binary stripped"
            fi
        fi
    fi
    
    # Create release package if requested
    if [ "$CREATE_RELEASE" = true ]; then
        create_release_package
    fi
    
    # FINAL: Success Message
    print_section "Build Complete!"
    
    echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          All Done! Ready to Use!         ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Build Information:${NC}"
    echo "  Mode:     ${BUILD_MODE}"
    echo "  Binary:   $(pwd)/build/zilium-super-compactor"
    echo "  Size:     $(du -h build/zilium-super-compactor | cut -f1)"
    
    if [ "$BUILD_GUI" = true ]; then
        if [ -f "build/gui/zilium-gui" ]; then
            echo "  GUI:      $(pwd)/build/gui/zilium-gui"
            echo "  Size:     $(du -h build/gui/zilium-gui | cut -f1)"
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}Quick Start:${NC}"
    
    if [ "$BUILD_GUI" = true ] && [ -f "build/gui/zilium-gui" ]; then
        echo "  GUI: ./build/gui/zilium-gui"
        echo "  CLI: ./build/zilium-super-compactor <path-to-rom-folder>"
    else
        echo "  ./build/zilium-super-compactor <path-to-rom-folder>"
    fi
    
    echo ""
    echo -e "${YELLOW}Example:${NC}"
    echo "  ./build/zilium-super-compactor ~/Downloads/ColorOS_ROM/"
    echo ""
    
    if [ "$BUILD_MODE" = "Release" ]; then
        echo -e "${MAGENTA}Release Build Features:${NC}"
        echo "  ✓ Optimized for performance (-O3)"
        echo "  ✓ Native CPU instructions (-march=native)"
        echo "  ✓ Debug symbols removed"
        echo "  ✓ Ready for distribution"
        echo ""
    fi
    
    if [ "$CREATE_RELEASE" = false ]; then
        echo -e "${CYAN}Create Distribution Package:${NC}"
        if [ "$BUILD_GUI" = true ]; then
            echo "  $0 --release --gui --package"
        else
            echo "  $0 --release --package"
        fi
        echo ""
        echo "  This will create:"
        echo "  • Optimized binaries"
        echo "  • run.sh launcher script (if GUI)"
        echo "  • README.txt with documentation"
        echo "  • Compressed .tar.gz archive"
        echo "  • SHA256 and MD5 checksums"
    else
        echo -e "${GREEN}Distribution package created!${NC}"
        echo "  Ready to ship and deploy"
    fi
    
    echo ""
}

# Run main function
main "$@"
    
