# Changelog

## Version 1.0.0 (October 4, 2025)

### Features
- ✅ **Self-contained binary**: zilium_super_compactor automatically finds bundled lpmake in same directory
- ✅ **User-friendly installation**: No sudo required - installs to `~/.local/bin`
- ✅ **Automatic metadata extraction**: Reads original super partition metadata for vbmeta compatibility
- ✅ **A/B slot support**: Handles both single-slot and A/B partition schemes
- ✅ **JSON configuration**: Flexible configuration with multiple JSON support
- ✅ **Release build system**: Professional build script with optimization flags

### Installation

```bash
# Extract the package
tar -xzf zilium_super_compactor_v1.0.0_Linux_x86_64.tar.gz
cd zilium_super_compactor_v1.0.0_Linux_x86_64

# Install (no sudo needed)
./install.sh

# Add to PATH if needed
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Usage

```bash
# Run from anywhere after installation
zilium_super_compactor /path/to/rom-export

# Or run directly from extracted folder
./bin/zilium_super_compactor /path/to/rom-export
```

### Build System

```bash
# Debug build
./build.sh

# Release build (optimized)
./build.sh --release

# Create distribution package
./build.sh --package

# Clean rebuild
./build.sh --clean --release

# Install to ~/.local/bin
./build.sh --install
```

### Technical Details

**Binary Sizes:**
- zilium_super_compactor: 148 KB (optimized, stripped)
- lpmake: 3.1 MB
- lpunpack: 2.8 MB
- lpdump: 5.9 MB
- **Total package: 4.4 MB**

**Optimizations:**
- `-O3` compiler optimization
- `-march=native` for CPU-specific instructions
- Debug symbols stripped
- 20-40% faster than debug builds

**Metadata Preservation:**
- Automatically extracts `metadata_size` from original super partition
- Extracts `metadata_slots` (1 for non-A/B, 2 for A/B, 3 for A/B/C)
- Extracts `block_size` (typically 4096)
- Preserves alignment settings for vbmeta compatibility

### VBMeta Compatibility

The tool now properly extracts and preserves critical metadata parameters from the original super partition, ensuring compatibility with stock vbmeta. See `VBMETA_HASH_EXPLANATION.md` for detailed information about how this works.

### Dependencies

**Build-time:**
- g++ or clang++ (C++17 support)
- cmake (>= 3.10)
- git
- make
- zlib development files

**Runtime:**
- None (fully static binaries)

### Package Contents

```
zilium_super_compactor_v1.0.0_Linux_x86_64/
├── bin/
│   ├── zilium_super_compactor  (self-contained, finds bundled tools)
│   ├── lpmake          (bundled, auto-detected)
│   ├── lpunpack        (bundled)
│   └── lpdump          (bundled)
├── docs/
│   ├── README.md
│   ├── VBMETA_FIX_README.md
│   ├── VBMETA_HASH_EXPLANATION.md
│   ├── EXAMPLES.md
│   └── FAQ.md
├── install.sh          (no sudo required)
└── README.txt
```

### Known Limitations

- Rebuilt super.img may still require modified vbmeta in some cases
- Tool designed specifically for Realme/OPPO/OnePlus ROM structure
- Requires specific JSON configuration format

### Future Improvements

- [ ] Add support for more ROM structures
- [ ] Automatic vbmeta patching
- [ ] GUI interface
- [ ] Windows/macOS support
- [ ] Progress bar for large images

### Credits

- Based on AOSP lpmake/lpunpack tools
- nlohmann/json library for JSON parsing
- Community feedback and testing
