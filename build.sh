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
REBUILD_LPTOOLS=false

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
  -l, --lptools       Force rebuild of LP tools (lpmake, lpunpack)
  -p, --package       Create release package (tar.gz)
  
Build Modes:
  Debug (default)     Build with debug symbols
  Release (-r)        Build optimized for distribution
  
Examples:
  $0                          # Debug build
  $0 --release                # Release build
  $0 --release --package      # Release build + create package
  $0 --clean --release        # Clean + Release build
  $0 --lptools                # Force rebuild LP tools + zilium_super_compactor

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
            -l|--lptools)
                REBUILD_LPTOOLS=true
                shift
                ;;
            -p|--package)
                CREATE_RELEASE=true
                BUILD_MODE="Release"  # Force release mode for packaging
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
    cp lpunpack_and_lpmake/bin/lpmake "dist/${RELEASE_DIR}/bin/" 2>/dev/null || true
    cp lpunpack_and_lpmake/bin/lpunpack "dist/${RELEASE_DIR}/bin/" 2>/dev/null || true
    cp lpunpack_and_lpmake/bin/lpdump "dist/${RELEASE_DIR}/bin/" 2>/dev/null || true
    
    # Strip binaries for smaller size
    print_step "Stripping debug symbols..."
    strip "dist/${RELEASE_DIR}/bin/"* 2>/dev/null || true
    
    # Note: No documentation files copied (as per user request)
    
    # Create README for package
    cat > "dist/${RELEASE_DIR}/README.txt" << README_EOF
Zilium Super Compactor v${VERSION}
================================

Combines split super partition images into a single super.img
for Realme/OPPO/OnePlus devices with stock vbmeta compatibility.

Contents:
  bin/zilium_super_compactor  - Main tool (self-contained)
  bin/lpmake          - LP partition tool (bundled)
  bin/lpunpack        - LP unpacker (bundled)
  bin/lpdump          - LP metadata dumper (bundled)
  
Usage:
  ./bin/zilium_super_compactor <rom-folder>
  
The tool automatically:
  - Detects bundled lpmake in same directory
  - Reads original OEM metadata parameters
  - Rebuilds super.img with identical structure
  - Ensures compatibility with stock vbmeta

Build: ${BUILD_MODE}
Date: $(date)
System: $(uname -s) $(uname -m)
README_EOF
    
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
    
    print_success "Release package created: dist/${PACKAGE_NAME}"
    print_info "Package size: $(du -h dist/${PACKAGE_NAME} | cut -f1)"
    echo ""
    echo -e "${CYAN}Checksums:${NC}"
    cat "dist/${PACKAGE_NAME}.sha256"
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
    
    # PHASE 3: Build LP Tools
    print_section "Phase 2: Build LP Tools"
    
    cd lpunpack_and_lpmake
    
    # Check if LP tools already exist
    LPTOOLS_EXIST=false
    if [ -f "bin/lpmake" ] && [ -f "bin/lpunpack" ] && [ -f "bin/lpdump" ]; then
        LPTOOLS_EXIST=true
    fi
    
    # Determine if we need to build LP tools
    BUILD_LPTOOLS=false
    
    if [ "$LPTOOLS_EXIST" = true ]; then
        if [ "$REBUILD_LPTOOLS" = true ]; then
            print_info "LP tools exist but rebuild forced via --lptools flag"
            BUILD_LPTOOLS=true
        else
            print_success "LP tools already built (lpmake, lpunpack, lpdump)"
            print_info "Skipping LP tools rebuild (use --lptools to force rebuild)"
        fi
    else
        print_info "LP tools not found, building from source..."
        BUILD_LPTOOLS=true
    fi
    
    if [ "$BUILD_LPTOOLS" = true ]; then
        print_step "Applying compilation fixes..."
        
        # Fix utility.cpp - add missing algorithm header
        if [ -f "lib/liblp/utility.cpp" ]; then
            if ! grep -q "#include <algorithm>" "lib/liblp/utility.cpp"; then
                sed -i '17i#include <algorithm>' "lib/liblp/utility.cpp"
                print_success "Fixed utility.cpp"
            else
                print_info "utility.cpp already fixed"
            fi
        fi
        
        print_step "Building lpmake and lpunpack..."
        bash make.sh > /dev/null 2>&1
        print_success "LP tools built successfully"
    fi
    
    cd ..
    
    # Verify binaries
    if [ -f "lpunpack_and_lpmake/bin/lpmake" ] && [ -f "lpunpack_and_lpmake/bin/lpunpack" ]; then
        print_success "LP tools verified"
    else
        print_error "Failed to build LP tools"
        exit 1
    fi

    # PHASE 4: Build Zilium Super Compactor
    print_section "Phase 4: Build Zilium Super Compactor"

    print_step "Creating build directory..."
    mkdir -p build
    
    print_step "Configuring CMake (${BUILD_MODE} mode)..."
    cd build
    
    if [ "$BUILD_MODE" = "Release" ]; then
        print_info "Enabling compiler optimizations (-O3, -march=native)"
        if ! cmake -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_CXX_FLAGS_RELEASE="-O3 -march=native -DNDEBUG" \
              .. ; then
            print_error "CMake configuration failed"
            cd ..
            exit 1
        fi
    else
        if ! cmake -DCMAKE_BUILD_TYPE=Debug .. ; then
            print_error "CMake configuration failed"
            cd ..
            exit 1
        fi
    fi
    print_success "CMake configured"
    
    print_step "Compiling zilium_super_compactor..."
    CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 4)
    print_info "Using ${CORES} CPU cores"
    if ! make -j$CORES ; then
        print_error "Compilation failed"
        cd ..
        exit 1
    fi
    print_success "zilium-super-compactor compiled"
    
    cd ..
    
    # Verify binary
    if [ -f "build/zilium-super-compactor" ]; then
        BINARY_SIZE=$(du -h build/zilium-super-compactor | cut -f1)
        print_success "zilium-super-compactor binary created (${BINARY_SIZE})"
    else
        print_error "Failed to build zilium-super-compactor"
        exit 1
    fi
    
    # Strip binary in release mode
    if [ "$BUILD_MODE" = "Release" ]; then
        print_step "Stripping debug symbols for smaller binary..."
        strip build/zilium-super-compactor
        STRIPPED_SIZE=$(du -h build/zilium-super-compactor | cut -f1)
        print_success "Binary stripped (${STRIPPED_SIZE})"
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
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./build/zilium-super-compactor <path-to-rom-folder>"
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
        echo -e "${CYAN}Additional Options:${NC}"
        echo "  Create release package:  $0 --package"
    fi
    
    echo ""
}

# Run main function
main "$@"
    
