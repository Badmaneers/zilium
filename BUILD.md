# Build Documentation

Complete guide for building `zilium-super-compactor` from source, including development setup and advanced build options.

## Table of Contents

- [Quick Build](#quick-build)
- [Build Requirements](#build-requirements)
- [Build System Overview](#build-system-overview)
- [Build Modes](#build-modes)
- [Build Options](#build-options)
- [Development Setup](#development-setup)
- [Debugging](#debugging)
- [Testing](#testing)
- [Release Process](#release-process)
- [Troubleshooting](#troubleshooting)

---

## Quick Build

```bash
# Clone repository
git clone https://github.com/yourusername/zilium.git
cd zilium

# Build (debug mode)
./build.sh

# Or build release version
./build.sh --release

# Binary location
./build/zilium-super-compactor
```

**Build time:**
- First build: ~2 minutes (includes LP tools compilation)
- Incremental: ~7.5 seconds

---

## Build Requirements

### Minimum Requirements

| Component | Version | Purpose |
|-----------|---------|---------|
| **GCC/G++** | 7.0+ | C++17 support |
| **CMake** | 3.10+ | Build system |
| **Make** | 4.0+ | Build automation |
| **Git** | 2.0+ | Source control |

### System Libraries

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install -y \
    build-essential \
    cmake \
    git \
    zlib1g-dev \
    liblz4-dev \
    libssl-dev \
    python3
```

**Arch Linux:**
```bash
sudo pacman -Syu --needed \
    base-devel \
    cmake \
    git \
    zlib \
    lz4 \
    openssl \
    python
```

**Fedora/RHEL:**
```bash
sudo dnf groupinstall "Development Tools"
sudo dnf install -y \
    cmake \
    git \
    zlib-devel \
    lz4-devel \
    openssl-devel \
    python3
```

**macOS:**
```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install cmake git openssl lz4
```

### Optional Tools

```bash
# For development
sudo apt install -y \
    clang-format \
    clang-tidy \
    valgrind \
    gdb

# For documentation
sudo apt install -y \
    doxygen \
    graphviz
```

---

## Build System Overview

### Directory Structure

```
zilium/
├── build.sh              # Main build script
├── CMakeLists.txt        # CMake configuration
├── src/
│   └── zilium-super-compactor.cpp
├── include/
│   └── liblp/            # LP library headers
├── external/
│   └── include/
│       └── json.hpp      # nlohmann::json
├── lpunpack_and_lpmake/  # AOSP LP tools source
│   ├── make.sh           # LP tools build script
│   └── bin/              # Compiled binaries
└── build/                # Build output (created)
    └── zilium-super-compactor
```

### Build Flow

```
./build.sh
    ↓
1. Check LP Tools
    ├─→ If exist: Skip compilation
    └─→ If missing: Run lpunpack_and_lpmake/make.sh
    ↓
2. CMake Configuration
    ├─→ Generate Makefiles
    ├─→ Configure compiler flags
    └─→ Set include paths
    ↓
3. Compilation
    ├─→ Compile zilium-super-compactor.cpp
    └─→ Link dependencies
    ↓
4. Post-build (Release mode)
    ├─→ Strip symbols
    ├─→ Create release package
    └─→ Copy dependencies
```

---

## Build Modes

### Debug Mode (Default)

**Purpose:** Development and debugging

```bash
./build.sh
# or
./build.sh --debug
```

**Characteristics:**
- Debug symbols included
- No optimization (-O0)
- AddressSanitizer enabled (detects memory errors)
- Larger binary size (~168KB)
- Slower execution

**Use when:**
- Developing new features
- Debugging issues
- Running under debugger (GDB/LLDB)
- Profiling performance

### Release Mode

**Purpose:** Production use

```bash
./build.sh --release
```

**Characteristics:**
- Debug symbols stripped
- Maximum optimization (-O3 -march=native)
- No sanitizers
- Smaller binary size (~136KB)
- Faster execution

**Use when:**
- Building for end users
- Creating distributable packages
- Performance is critical

### Build Mode Comparison

| Feature | Debug | Release |
|---------|-------|---------|
| Binary Size | ~168KB | ~136KB |
| Optimization | None (-O0) | Maximum (-O3) |
| Debug Symbols | Yes | Stripped |
| Sanitizers | AddressSanitizer | None |
| Build Time | ~7.5s | ~7.5s |
| Runtime Speed | Slower | Faster |

---

## Build Options

### Command-Line Flags

```bash
# Build release version
./build.sh --release

# Clean build (remove old files)
./build.sh --clean

# Rebuild LP tools (force recompilation)
./build.sh --lptools

# Combine flags
./build.sh --release --clean --lptools
```

### Detailed Options

#### `--release` / `-r`
```bash
./build.sh --release
```
- Enables optimization (-O3 -march=native)
- Strips debug symbols
- Creates release package in `release/` directory
- Package includes: binary + LP tools + README

#### `--clean` / `-c`
```bash
./build.sh --clean
```
- Removes `build/` directory
- Removes `release/` directory
- Forces complete rebuild
- Use when switching build modes or after major changes

#### `--lptools` / `-l`
```bash
./build.sh --lptools
```
- Forces recompilation of LP tools (lpmake, lpunpack, lpdump)
- Normally LP tools are cached (built once)
- Use when updating AOSP sources
- Adds ~2 minutes to build time

### Environment Variables

```bash
# Custom compiler
export CC=clang
export CXX=clang++
./build.sh

# Custom build directory
export BUILD_DIR=/tmp/my_build
./build.sh

# Custom flags
export CXXFLAGS="-O2 -g"
./build.sh
```

### CMake Variables

```bash
# Manual CMake build with custom options
mkdir build && cd build

# Debug build
cmake -DCMAKE_BUILD_TYPE=Debug ..
make

# Release build with custom prefix
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=/usr/local \
      ..
make

# With custom compiler
cmake -DCMAKE_C_COMPILER=clang \
      -DCMAKE_CXX_COMPILER=clang++ \
      ..
make
```

---

## Development Setup

### IDE Configuration

#### Visual Studio Code

**.vscode/c_cpp_properties.json:**
```json
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "${workspaceFolder}/include",
                "${workspaceFolder}/external/include",
                "${workspaceFolder}/lpunpack_and_lpmake/lib/include"
            ],
            "defines": [],
            "compilerPath": "/usr/bin/g++",
            "cStandard": "c17",
            "cppStandard": "c++17",
            "intelliSenseMode": "gcc-x64"
        }
    ]
}
```

**.vscode/tasks.json:**
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Build Debug",
            "type": "shell",
            "command": "./build.sh --debug",
            "group": {
                "kind": "build",
                "isDefault": true
            }
        },
        {
            "label": "Build Release",
            "type": "shell",
            "command": "./build.sh --release"
        }
    ]
}
```

#### CLion

**CMakeLists.txt is already configured** - just open project in CLion.

**Build Configurations:**
- Debug: CMAKE_BUILD_TYPE=Debug
- Release: CMAKE_BUILD_TYPE=Release

### Code Style

**C++ Style Guide:**
```cpp
// Use modern C++17 features
auto result = parse_config(filename);

// Prefer const and references
const std::string& get_name() const;

// Use RAII for resource management
std::ifstream file(path);

// Descriptive names
bool parse_super_config(const std::string& config_path);
```

**Formatting:**
```bash
# Format all source files
clang-format -i src/*.cpp include/**/*.h
```

**.clang-format:**
```yaml
BasedOnStyle: Google
IndentWidth: 4
ColumnLimit: 100
```

---

## Debugging

### GDB Debugging

```bash
# Build with debug symbols
./build.sh --debug

# Run in GDB
gdb ./build/zilium-super-compactor

# GDB commands
(gdb) break main                    # Set breakpoint
(gdb) run config.json output.img    # Run with arguments
(gdb) backtrace                     # Show call stack
(gdb) print variable                # Inspect variable
(gdb) continue                      # Continue execution
```

### Valgrind Memory Check

```bash
# Build debug version
./build.sh --debug

# Check for memory leaks
valgrind --leak-check=full \
         --show-leak-kinds=all \
         --track-origins=yes \
         ./build/zilium-super-compactor config.json output.img
```

### AddressSanitizer

```bash
# Already enabled in debug builds
./build.sh --debug

# Run program - ASan will detect memory errors
./build/zilium-super-compactor config.json output.img

# If error detected, ASan prints detailed report:
# =================================================================
# ==12345==ERROR: AddressSanitizer: heap-use-after-free on address...
```

### Logging and Verbosity

```cpp
// Add verbose logging in code
#ifdef DEBUG
    std::cerr << "DEBUG: Processing partition " << name << std::endl;
#endif
```

```bash
# Compile with DEBUG flag
cmake -DCMAKE_BUILD_TYPE=Debug -DDEBUG=1 ..
make
```

---

## Testing

### Unit Testing Setup

**Install Google Test:**
```bash
sudo apt install libgtest-dev
cd /usr/src/gtest
sudo cmake .
sudo make
sudo cp lib/*.a /usr/lib
```

**Example Test (tests/test_config.cpp):**
```cpp
#include <gtest/gtest.h>
#include "config_parser.h"

TEST(ConfigParser, ValidConfig) {
    auto config = parse_config("test_data/valid_config.json");
    ASSERT_TRUE(config.has_value());
    EXPECT_EQ(config->metadata_slots, 2);
}

TEST(ConfigParser, InvalidConfig) {
    auto config = parse_config("test_data/invalid.json");
    EXPECT_FALSE(config.has_value());
}
```

### Integration Testing

```bash
#!/bin/bash
# test/integration_test.sh

set -e

echo "Running integration tests..."

# Test 1: Build with sample config
./build/zilium-super-compactor test_data/config.json /tmp/test_super.img

# Test 2: Verify output
lpdump /tmp/test_super.img > /dev/null
echo "✓ Test 1: Build successful"

# Test 3: Check partition count
PARTITIONS=$(lpdump /tmp/test_super.img | grep "Name:" | wc -l)
if [ $PARTITIONS -eq 4 ]; then
    echo "✓ Test 2: Correct partition count"
else
    echo "✗ Test 2: Expected 4 partitions, got $PARTITIONS"
    exit 1
fi

echo "✓ All integration tests passed"
```

### Automated Testing

**GitHub Actions (.github/workflows/build-test.yml):**
```yaml
name: Build and Test

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install dependencies
        run: |
          sudo apt update
          sudo apt install -y build-essential cmake zlib1g-dev
      
      - name: Build
        run: ./build.sh --release
      
      - name: Test
        run: |
          ./build/zilium-super-compactor --version
          ./test/integration_test.sh
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        with:
          name: zilium-super-compactor
          path: release/zilium-v*.tar.gz
```

---

## Release Process

### Version Numbering

Follow [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

Example: `v1.2.3`

### Creating a Release

```bash
# 1. Update version in source
vim src/zilium-super-compactor.cpp
# Change: const char* VERSION = "1.2.3";

# 2. Build release
./build.sh --release --clean

# 3. Test release package
cd release/zilium-v1.2.3/
./zilium-super-compactor config.json test.img

# 4. Create git tag
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3

# 5. Create GitHub release
# Upload release/zilium-v1.2.3.tar.gz to GitHub releases
```

### Release Checklist

- [ ] Update version number in code
- [ ] Update CHANGELOG.md
- [ ] Run all tests
- [ ] Build clean release (`--clean --release`)
- [ ] Test on target platform
- [ ] Create git tag
- [ ] Push tag to GitHub
- [ ] Create GitHub release
- [ ] Upload release tarball
- [ ] Update documentation

---

## Troubleshooting

### Build Failures

#### Problem: "CMake not found"

```bash
# Ubuntu/Debian
sudo apt install cmake

# Or install from source
wget https://github.com/Kitware/CMake/releases/download/v3.27.0/cmake-3.27.0.tar.gz
tar xf cmake-3.27.0.tar.gz
cd cmake-3.27.0
./bootstrap && make && sudo make install
```

#### Problem: "C++ compiler too old"

```bash
# Check version
g++ --version

# Ubuntu: Install newer GCC
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt update
sudo apt install g++-11

# Use specific version
export CXX=g++-11
./build.sh
```

#### Problem: "json.hpp not found"

```bash
# Download nlohmann/json
mkdir -p external/include
wget https://github.com/nlohmann/json/releases/download/v3.11.2/json.hpp \
     -O external/include/json.hpp

# Or clone full repository
cd external
git clone https://github.com/nlohmann/json.git
```

#### Problem: "LP tools build fails"

```bash
# Clean and rebuild LP tools
rm -rf lpunpack_and_lpmake/bin
./build.sh --lptools

# Check make.sh for errors
cd lpunpack_and_lpmake
bash -x make.sh  # Debug mode
```

### Runtime Issues

#### Problem: "lpmake not found"

```bash
# Ensure LP tools are built
ls -la lpunpack_and_lpmake/bin/

# If missing, rebuild
./build.sh --lptools

# Or manually build
cd lpunpack_and_lpmake
./make.sh
```

#### Problem: "Segmentation fault"

```bash
# Build with debug symbols and run in GDB
./build.sh --debug
gdb --args ./build/zilium-super-compactor config.json output.img
(gdb) run
(gdb) backtrace

# Or use Valgrind
valgrind ./build/zilium-super-compactor config.json output.img
```

### Performance Issues

#### Problem: "Build is very slow"

```bash
# Use parallel compilation
make -j$(nproc)

# Or with build.sh
cd build
cmake --build . -j$(nproc)
```

#### Problem: "LP tools always rebuild"

```bash
# LP tools should be cached
# If they rebuild every time, check:

# 1. LP tools binaries exist?
ls -la lpunpack_and_lpmake/bin/

# 2. Use --lptools only when needed
./build.sh          # LP tools cached ✓
./build.sh --lptools  # LP tools rebuilt
```

---

## Advanced Topics

### Cross-Compilation

**For ARM64 (Android devices):**
```bash
# Install cross-compiler
sudo apt install gcc-aarch64-linux-gnu g++-aarch64-linux-gnu

# Configure CMake
mkdir build-arm64
cd build-arm64
cmake -DCMAKE_SYSTEM_NAME=Linux \
      -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
      -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
      -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
      ..
make
```

### Static Linking

**Build fully static binary:**
```bash
# Edit CMakeLists.txt
target_link_libraries(zilium-super-compactor
    PRIVATE
    -static
    -static-libgcc
    -static-libstdc++
)

# Build
./build.sh --release

# Verify
ldd build/zilium-super-compactor
# Should show: "not a dynamic executable"
```

### Custom Optimization Flags

```bash
# Edit build.sh or set environment variable
export CXXFLAGS="-O3 -march=native -mtune=native -flto"
./build.sh --release

# Profile-guided optimization (advanced)
# 1. Build with instrumentation
cmake -DCMAKE_CXX_FLAGS="-fprofile-generate" ..
make

# 2. Run typical workload
./zilium-super-compactor config.json output.img

# 3. Rebuild with profile data
cmake -DCMAKE_CXX_FLAGS="-fprofile-use" ..
make
```

---

## Build Time Optimization

### Comparison

| Scenario | Time | Description |
|----------|------|-------------|
| First build | ~2m 0s | Includes LP tools compilation |
| Incremental (cached) | ~7.5s | Only rebuilds zilium-super-compactor |
| With --lptools | ~2m 0s | Forces LP tools rebuild |
| With --clean | ~7.5s | Clean build (LP tools cached) |
| With --clean --lptools | ~2m 0s | Complete rebuild |

### Tips for Faster Builds

1. **Don't use `--lptools`** unless necessary
2. **Use parallel builds**: `make -j$(nproc)`
3. **Use ccache**: `sudo apt install ccache`
4. **Use Ninja**: `cmake -G Ninja ..`
5. **Disable sanitizers** in release mode (already done)

---

## Contributing to Build System

### Adding New Source Files

**Edit CMakeLists.txt:**
```cmake
add_executable(zilium-super-compactor
    src/zilium-super-compactor.cpp
    src/new_file.cpp          # Add here
)
```

### Adding Dependencies

**External library:**
```cmake
# Find package
find_package(SomeLib REQUIRED)

# Link library
target_link_libraries(zilium-super-compactor
    PRIVATE
    SomeLib::SomeLib
)
```

### Modifying Compiler Flags

**Edit CMakeLists.txt:**
```cmake
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    target_compile_options(zilium-super-compactor PRIVATE
        -Wall -Wextra -Wpedantic
        -O0 -g
        -fsanitize=address
    )
else()
    target_compile_options(zilium-super-compactor PRIVATE
        -O3 -march=native
        -DNDEBUG
    )
endif()
```

---

## References

- [CMake Documentation](https://cmake.org/documentation/)
- [GCC Optimization Options](https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html)
- [AddressSanitizer](https://github.com/google/sanitizers/wiki/AddressSanitizer)
- [Valgrind User Manual](https://valgrind.org/docs/manual/manual.html)

---

For build issues not covered here, please [open an issue](https://github.com/yourusername/zilium/issues) on GitHub.
