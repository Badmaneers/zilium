# Contributing to Super Rebuilder

Thank you for your interest in contributing! This document provides guidelines and instructions for contributing to the project.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)
- [Documentation](#documentation)

---

## Code of Conduct

### Our Standards

- **Be respectful** - Treat all contributors with respect and courtesy
- **Be constructive** - Provide helpful feedback, not just criticism
- **Be collaborative** - Work together towards common goals
- **Be patient** - Remember that everyone was a beginner once
- **Be inclusive** - Welcome contributors of all backgrounds and skill levels

### Unacceptable Behavior

- Harassment or discriminatory language
- Personal attacks or trolling
- Publishing private information
- Spam or off-topic discussions

---

## Getting Started

### Prerequisites

Before contributing, ensure you have:

1. **Development Environment**
   ```bash
   # Ubuntu/Debian
   sudo apt install build-essential cmake git
   
   # Arch Linux
   sudo pacman -S base-devel cmake git
   ```

2. **Forked Repository**
   - Fork the repository on GitHub
   - Clone your fork locally:
     ```bash
     git clone https://github.com/Badmaneers/zilium.git
     cd zilium
     ```

3. **Upstream Remote**
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/zilium.git
   git fetch upstream
   ```

### First Time Setup

```bash
# Build the project
./build.sh

# Run tests (if available)
./test/run_tests.sh

# Create a new branch for your work
git checkout -b feature/my-awesome-feature
```

---

## Development Workflow

### 1. Find or Create an Issue

- Check [existing issues](https://github.com/OWNER/zilium/issues)
- Create new issue if needed
- Discuss approach before major changes

### 2. Create a Branch

**Branch naming convention:**
```bash
# Features
git checkout -b feature/add-partition-validation

# Bug fixes
git checkout -b fix/crash-on-empty-config

# Documentation
git checkout -b docs/update-examples

# Refactoring
git checkout -b refactor/simplify-config-parser
```

### 3. Make Changes

```bash
# Edit files
vim src/zilium-super-compactor.cpp

# Build and test
./build.sh --debug
./build/zilium-super-compactor test_config.json test_output.img

# Check for issues
./build.sh --clean --release
```

### 4. Commit Changes

```bash
# Stage changes
git add src/zilium-super-compactor.cpp

# Commit with descriptive message
git commit -m "feat: add partition size validation

- Validate partition sizes before building
- Show helpful error message if too large
- Update tests

Fixes #123"
```

### 5. Push and Create PR

```bash
# Push to your fork
git push origin feature/my-awesome-feature

# Create Pull Request on GitHub
```

---

## Coding Standards

### C++ Style Guide

#### Formatting

```cpp
// Use 4-space indentation
void my_function() {
    if (condition) {
        do_something();
    }
}

// Opening brace on same line
if (condition) {
    // ...
}

// Closing brace on new line
for (const auto& item : container) {
    process(item);
}
```

#### Naming Conventions

```cpp
// Functions: snake_case
void parse_config_file();
bool validate_partition_size();

// Variables: snake_case
int partition_count;
std::string config_path;

// Constants: UPPER_SNAKE_CASE
const int MAX_PARTITIONS = 64;
constexpr size_t BUFFER_SIZE = 4096;

// Classes/Structs: PascalCase
class ConfigParser {
    // Member variables: snake_case with trailing underscore
    std::string config_path_;
    int partition_count_;
    
public:
    // Methods: snake_case
    bool parse_file(const std::string& path);
    int get_partition_count() const;
};

// Enums: PascalCase
enum class DeviceType {
    NonAB,
    AB,
    Unknown
};
```

#### Modern C++ Features

```cpp
// Use auto when type is obvious
auto config = parse_config(path);  // Good
std::unique_ptr<Config> config = parse_config(path);  // Verbose

// Use const and references
const std::string& get_name() const;  // Good
std::string get_name();  // Bad (unnecessary copy)

// Use range-based for loops
for (const auto& partition : partitions) {  // Good
    process(partition);
}

// Use nullptr instead of NULL
Partition* ptr = nullptr;  // Good
Partition* ptr = NULL;     // Bad

// Use RAII for resource management
{
    std::ifstream file(path);  // Automatically closes
    // Use file...
}  // File closed here

// Use std::optional for optional values
std::optional<Config> parse_config(const std::string& path);

if (auto config = parse_config(path)) {
    // Use *config
}
```

#### Error Handling

```cpp
// Return std::optional for operations that may fail
std::optional<Partition> find_partition(const std::string& name) {
    // Search...
    if (found) {
        return partition;
    }
    return std::nullopt;
}

// Use exceptions for exceptional errors
if (!file.is_open()) {
    throw std::runtime_error("Failed to open file: " + path);
}

// Print user-friendly error messages
std::cerr << "❌ Error: Failed to parse configuration\n"
          << "   File: " << config_path << "\n"
          << "   Reason: Invalid JSON syntax\n";
```

#### Comments

```cpp
// Use comments to explain WHY, not WHAT
// Good: Explains reasoning
// Calculate metadata slots: 2 for non-A/B, 3 for A/B devices
int metadata_slots = is_ab_device ? 3 : 2;

// Bad: States the obvious
// Set metadata_slots to 3
int metadata_slots = 3;

// Document public functions
/**
 * Parse super partition configuration from JSON file.
 * 
 * @param config_path Path to JSON configuration file
 * @return Config object if successful, std::nullopt otherwise
 * 
 * @throws std::runtime_error if file cannot be read
 */
std::optional<Config> parse_config(const std::string& config_path);
```

### Bash Style Guide

```bash
#!/bin/bash
# Use strict mode
set -euo pipefail

# Constants in UPPER_CASE
readonly BUILD_DIR="build"
readonly RELEASE_DIR="release"

# Functions in snake_case
print_success() {
    echo "✓ $1"
}

print_error() {
    echo "❌ Error: $1" >&2
}

# Quote variables
local file_path="$1"
if [ -f "$file_path" ]; then
    echo "File exists: $file_path"
fi

# Use [[ ]] instead of [ ]
if [[ "$mode" == "release" ]]; then
    build_release
fi

# Use functions for repeated code
build_lptools() {
    print_info "Building LP tools..."
    cd lpunpack_and_lpmake
    ./make.sh
    cd ..
}
```

---

## Testing Guidelines

### Unit Tests

**Create test file: `tests/test_config_parser.cpp`**

```cpp
#include <gtest/gtest.h>
#include "config_parser.h"

class ConfigParserTest : public ::testing::Test {
protected:
    void SetUp() override {
        // Setup before each test
    }
    
    void TearDown() override {
        // Cleanup after each test
    }
};

TEST_F(ConfigParserTest, ParseValidConfig) {
    auto config = parse_config("test_data/valid_config.json");
    ASSERT_TRUE(config.has_value());
    EXPECT_EQ(config->metadata_slots, 2);
    EXPECT_EQ(config->partitions.size(), 4);
}

TEST_F(ConfigParserTest, ParseInvalidJSON) {
    auto config = parse_config("test_data/invalid.json");
    EXPECT_FALSE(config.has_value());
}

TEST_F(ConfigParserTest, HandleMissingFile) {
    auto config = parse_config("nonexistent.json");
    EXPECT_FALSE(config.has_value());
}
```

### Integration Tests

**Create test script: `tests/integration_test.sh`**

```bash
#!/bin/bash
set -euo pipefail

test_count=0
pass_count=0

run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((test_count++))
    echo -n "Test $test_count: $test_name... "
    
    if eval "$test_command" &>/dev/null; then
        echo "✓ PASS"
        ((pass_count++))
    else
        echo "✗ FAIL"
    fi
}

# Run tests
run_test "Build with valid config" \
    "./build/zilium-super-compactor test_data/valid_config.json /tmp/test.img"

run_test "Detect invalid config" \
    "! ./build/zilium-super-compactor test_data/invalid.json /tmp/test.img"

# Report results
echo ""
echo "Results: $pass_count/$test_count tests passed"
[ $pass_count -eq $test_count ]
```

### Test Requirements

Before submitting PR:

1. **All existing tests pass**
   ```bash
   ./test/run_all_tests.sh
   ```

2. **New features have tests**
   - Add unit tests for new functions
   - Add integration tests for new features

3. **No memory leaks**
   ```bash
   valgrind --leak-check=full ./build/zilium-super-compactor config.json output.img
   ```

4. **Code builds without warnings**
   ```bash
   ./build.sh --release
   # Check for warnings in output
   ```

---

## Commit Messages

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting, etc.)
- **refactor**: Code refactoring
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **build**: Build system changes
- **ci**: CI/CD changes
- **chore**: Other changes (dependencies, etc.)

### Examples

**Simple change:**
```
feat: add partition size validation

Validate that total partition size doesn't exceed group size
before building super partition.
```

**Bug fix:**
```
fix: crash when config file is empty

Handle empty JSON files gracefully instead of crashing.
Return error message to user.

Fixes #42
```

**Multiple changes:**
```
refactor: simplify config parsing

- Use std::optional instead of raw pointers
- Extract validation logic into separate function
- Add better error messages
- Update tests

Related to #15
```

**Breaking change:**
```
feat!: change config file format

BREAKING CHANGE: Config files now use different JSON structure.
See MIGRATION.md for upgrade instructions.

Old format:
{
  "partitions": ["system", "vendor"]
}

New format:
{
  "partitions": [
    {"name": "system", "image": "system.img"},
    {"name": "vendor", "image": "vendor.img"}
  ]
}

Closes #100
```

### Best Practices

- ✅ Use imperative mood: "add feature" not "added feature"
- ✅ First line ≤ 50 characters
- ✅ Body wrapped at 72 characters
- ✅ Separate subject from body with blank line
- ✅ Reference issues/PRs in footer
- ❌ Don't end subject with period
- ❌ Don't include implementation details in subject

---

## Pull Request Process

### Before Submitting

**Checklist:**
- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] New tests added for new features
- [ ] Documentation updated
- [ ] Commit messages follow convention
- [ ] Branch is up to date with main

```bash
# Update branch
git fetch upstream
git rebase upstream/main

# Run tests
./test/run_all_tests.sh

# Check style
clang-format -i src/*.cpp
```

### PR Template

When creating PR, include:

```markdown
## Description
Brief description of changes

## Related Issues
Fixes #123
Related to #456

## Changes Made
- Added X feature
- Fixed Y bug
- Updated Z documentation

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Screenshots (if applicable)
[Before/After screenshots or terminal output]

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] No breaking changes (or documented)
```

### Review Process

1. **Automated Checks**
   - CI builds project
   - Tests run automatically
   - Code style checked

2. **Code Review**
   - Maintainers review code
   - Provide feedback
   - Request changes if needed

3. **Address Feedback**
   ```bash
   # Make changes
   vim src/file.cpp
   
   # Commit
   git add src/file.cpp
   git commit -m "fix: address review feedback"
   
   # Push
   git push origin feature/my-feature
   ```

4. **Merge**
   - Once approved, PR will be merged
   - Branch can be deleted

---

## Reporting Issues

### Bug Reports

**Use this template:**

```markdown
**Description**
Clear description of the bug

**To Reproduce**
Steps to reproduce:
1. Run command '...'
2. With config file '...'
3. See error

**Expected Behavior**
What you expected to happen

**Actual Behavior**
What actually happened

**Environment**
- OS: Ubuntu 22.04
- Compiler: GCC 11.3
- Project version: v1.0.0
- Device: Realme C11 2021

**Config File**
```json
{
  "metadata_size": 65536,
  ...
}
```

**Error Output**
```
❌ Error: ...
```

**Additional Context**
Any other relevant information
```

### Feature Requests

```markdown
**Feature Description**
Clear description of the feature

**Use Case**
Why is this feature needed?
What problem does it solve?

**Proposed Solution**
How might this feature work?

**Alternatives Considered**
What other approaches did you consider?

**Additional Context**
Examples, mockups, related projects, etc.
```

---

## Documentation

### When to Update Documentation

Update docs when:
- Adding new features
- Changing existing behavior
- Fixing bugs that affect usage
- Adding new configuration options
- Changing build process

### Documentation Files

| File | Purpose |
|------|---------|
| `README.md` | Project overview, quick start |
| `EXAMPLES.md` | Usage examples, real scenarios |
| `BUILD.md` | Build instructions, development setup |
| `VBMETA_COMPATIBILITY.md` | VBMeta technical details |
| `CONTRIBUTING.md` | This file - contribution guidelines |

### Documentation Style

```markdown
# Use clear headings

## Section Header

Brief introduction to section.

### Subsection

- Use bullet points for lists
- Keep paragraphs short
- Include code examples

**Bold** for emphasis
`code` for commands/filenames

```bash
# Example command
./build.sh --release
```

**Note:** Important information

⚠️ **Warning:** Critical information
```

### Code Comments

```cpp
// Good: Explains non-obvious logic
// Use 3 slots for A/B devices because we need:
// - Slot 0: Current metadata
// - Slot 1: Backup metadata  
// - Slot 2: Update metadata during OTA
int slots = is_ab ? 3 : 2;

// Bad: States the obvious
// Set i to 0
int i = 0;
```

---

## Community

### Communication Channels

- **GitHub Issues** - Bug reports, feature requests
- **GitHub Discussions** - Questions, ideas, general discussion
- **Pull Requests** - Code contributions

### Getting Help

- Check [README.md](README.md) for basic usage
- Check [EXAMPLES.md](EXAMPLES.md) for common scenarios
- Search [existing issues](https://github.com/OWNER/zilium/issues)
- Ask in [GitHub Discussions](https://github.com/OWNER/zilium/discussions)

### Recognition

Contributors are recognized in:
- GitHub contributors list
- CHANGELOG.md for significant contributions
- Special thanks section in README.md

---

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

---

## Thank You!

Every contribution, no matter how small, is valuable and appreciated. Whether it's:
- 🐛 Reporting a bug
- 💡 Suggesting a feature
- 📝 Improving documentation
- 🔧 Fixing a typo
- ✨ Adding a feature

**Thank you for making this project better!** 🎉

---

## Quick Reference

```bash
# Setup
git clone https://github.com/YOUR_USERNAME/zilium.git
cd zilium
git remote add upstream https://github.com/ORIGINAL_OWNER/zilium.git

# Create branch
git checkout -b feature/my-feature

# Make changes and test
vim src/file.cpp
./build.sh --debug
./test/run_tests.sh

# Commit
git add src/file.cpp
git commit -m "feat: add my feature"

# Push
git push origin feature/my-feature

# Create PR on GitHub
```

---

Questions? [Open an issue](https://github.com/OWNER/zilium/issues/new) or start a [discussion](https://github.com/OWNER/zilium/discussions/new).
