# Contributing to Zilium

Thank you for your interest in contributing to Zilium Super Compactor! This document provides guidelines and instructions for contributing.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Guidelines](#coding-guidelines)
- [Submitting Changes](#submitting-changes)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Features](#suggesting-features)

---

## Code of Conduct

### Our Pledge

We are committed to providing a welcoming and inspiring community for all. Please be respectful and constructive in all interactions.

### Expected Behavior

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Give and receive constructive feedback gracefully
- Focus on what is best for the community
- Show empathy towards other community members

### Unacceptable Behavior

- Harassment, trolling, or discriminatory behavior
- Publishing others' private information
- Spam or excessive self-promotion
- Other conduct inappropriate in a professional setting

---

## How Can I Contribute?

### 1. Reporting Bugs

Found a bug? Help us fix it!

**Before submitting:**
- Check if the issue already exists in [GitHub Issues](https://github.com/Badmaneers/zilium/issues)
- Try to reproduce with the latest version
- Gather relevant information (OS, version, error messages)

**Submit a bug report:**
1. Use the bug report template
2. Provide a clear, descriptive title
3. Include steps to reproduce
4. Describe expected vs actual behavior
5. Add screenshots if applicable
6. Include system information

### 2. Suggesting Features

Have an idea? We'd love to hear it!

**Before suggesting:**
- Check existing feature requests
- Consider if it fits the project scope
- Think about how it would benefit users

**Submit a feature request:**
1. Use the feature request template
2. Describe the problem it solves
3. Explain your proposed solution
4. Provide examples or mockups if possible

### 3. Contributing Code

Ready to code? Here's how!

**Good first issues:**
- Look for issues labeled `good first issue`
- Documentation improvements
- Adding tests
- Fixing typos or formatting

**Larger contributions:**
- Discuss in an issue first
- Break down into smaller PRs if possible
- Update documentation accordingly

### 4. Improving Documentation

Documentation is crucial! You can help by:
- Fixing typos or unclear explanations
- Adding examples
- Translating to other languages (future)
- Creating tutorials or guides

---

## Development Setup

### Prerequisites

```bash
# Ubuntu/Debian
sudo apt install build-essential cmake git \
    qt6-base-dev qt6-declarative-dev \
    qml6-module-qtquick-controls

# Arch Linux
sudo pacman -S base-devel cmake git \
    qt6-base qt6-declarative

# Fedora
sudo dnf install gcc-c++ cmake git \
    qt6-qtbase-devel qt6-qtdeclarative-devel
```

### Fork and Clone

```bash
# Fork the repository on GitHub first, then:

# Clone your fork
git clone https://github.com/YOUR_USERNAME/zilium.git
cd zilium

# Add upstream remote
git remote add upstream https://github.com/Badmaneers/zilium.git

# Fetch upstream changes
git fetch upstream
```

### Build for Development

```bash
# Build in debug mode
mkdir build-dev
cd build-dev
cmake -DCMAKE_BUILD_TYPE=Debug -DBUILD_GUI=ON ..
make -j$(nproc)

# Run tests (if available)
ctest

# Run with debugger
gdb ./zilium-super-compactor
gdb ./gui/zilium-gui
```

### Project Structure

```
zilium/
├── src/                      # Core C++ code
│   ├── zilium_core.h        # Main header
│   └── zilium_super_compactor.cpp  # CLI application
├── gui/                      # Qt6 GUI
│   ├── src/                 # GUI C++ code
│   └── qml/                 # QML UI files
├── lpunpack_and_lpmake/     # AOSP tools
├── external/                # Third-party libraries
├── docs/                    # Documentation
├── tests/                   # Test files
└── CMakeLists.txt           # Build configuration
```

---

## Coding Guidelines

### C++ Style

**Naming Conventions:**
```cpp
// Classes: PascalCase
class PartitionModel { };

// Functions: camelCase
void loadConfiguration();

// Variables: camelCase
int partitionCount;

// Constants: UPPER_CASE
const int MAX_PARTITIONS = 64;

// Member variables: m_ prefix
class Example {
    int m_value;
};
```

**Formatting:**
```cpp
// Indentation: 4 spaces
if (condition) {
    doSomething();
}

// Braces: Same line for control structures
void function() {
    if (check) {
        // code
    }
}

// Class declarations: Opening brace on new line
class MyClass
{
public:
    MyClass();
};
```

**Best Practices:**
```cpp
// Use const references for parameters
void processData(const std::string& data);

// Use auto for complex types
auto result = calculateComplexValue();

// Prefer nullptr over NULL
int* ptr = nullptr;

// Use modern C++ features (C++17)
if (auto value = getValue(); value > 0) {
    // use value
}
```

### QML Style

**Naming:**
```qml
// Component files: PascalCase
// File: MyCustomButton.qml

// IDs: camelCase
Rectangle {
    id: mainContainer
}

// Properties: camelCase
property int itemCount: 0
property string displayText: ""
```

**Structure:**
```qml
Rectangle {
    // 1. ID
    id: root
    
    // 2. Properties
    width: 400
    height: 300
    color: "white"
    
    // 3. Custom properties
    property int customValue: 42
    
    // 4. Signals
    signal clicked()
    
    // 5. Functions
    function doSomething() {
        // code
    }
    
    // 6. Child items
    Text {
        id: label
        anchors.centerIn: parent
        text: "Hello"
    }
}
```

### Git Commit Messages

**Format:**
```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat: Add partition filtering in GUI

- Add checkbox to enable/disable partitions
- Update partition model to support filtering
- Add UI controls in partition table

Closes #42

---

fix: Resolve crash on invalid config file

The application would crash when loading a malformed JSON file.
Added proper error handling and validation.

Fixes #38

---

docs: Update installation guide for Ubuntu 22.04

- Add Qt6 installation steps
- Include troubleshooting section
- Fix typos in commands
```

### Code Comments

```cpp
// Good comments explain WHY, not WHAT

// Bad: Increment counter
counter++;

// Good: Skip first iteration as it's initialization
counter++;

// Use documentation comments for public APIs
/**
 * @brief Builds super partition image
 * @param config Configuration file path
 * @param output Output directory path
 * @return true if successful, false otherwise
 */
bool buildSuperImage(const std::string& config, const std::string& output);
```

---

## Submitting Changes

### 1. Create a Branch

```bash
# Sync with upstream
git fetch upstream
git checkout main
git merge upstream/main

# Create feature branch
git checkout -b feature/my-awesome-feature

# Or for bug fixes
git checkout -b fix/issue-123
```

### 2. Make Changes

```bash
# Make your changes
# Test thoroughly
# Write tests if applicable
# Update documentation

# Check what changed
git status
git diff

# Stage changes
git add src/myfile.cpp
git add docs/GUIDE.md

# Commit with descriptive message
git commit -m "feat: Add new feature X

- Implement feature logic
- Add unit tests
- Update user guide"
```

### 3. Test Your Changes

```bash
# Build in release mode
mkdir build-test
cd build-test
cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_GUI=ON ..
make -j$(nproc)

# Test CLI
./zilium-super-compactor -c test/config.json -o test/output/

# Test GUI
./gui/zilium-gui

# Run tests
ctest --verbose

# Check for memory leaks
valgrind ./zilium-super-compactor -c test.json -o out/
```

### 4. Push and Create PR

```bash
# Push to your fork
git push origin feature/my-awesome-feature

# Go to GitHub and create Pull Request
# Fill out the PR template
# Link related issues
```

### Pull Request Checklist

Before submitting, ensure:

- [ ] Code follows style guidelines
- [ ] All tests pass
- [ ] New features have tests
- [ ] Documentation updated
- [ ] Commit messages are clear
- [ ] PR description explains changes
- [ ] No merge conflicts with main
- [ ] Builds successfully

### PR Review Process

1. **Automated checks** run (build, tests, linting)
2. **Maintainer review** - may request changes
3. **Make requested changes** - push to same branch
4. **Approval** - PR is approved
5. **Merge** - Changes are merged to main

---

## Reporting Bugs

### Bug Report Template

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

**Environment:**
 - OS: [e.g. Ubuntu 22.04]
 - Zilium Version: [e.g. 1.0.0]
 - Qt Version: [e.g. 6.2.4]
 - Build type: [CLI/GUI]

**Configuration file:**
If relevant, attach or paste your configuration JSON.

**Error output:**
Paste any error messages or logs.

**Additional context**
Add any other context about the problem here.
```

---

## Suggesting Features

### Feature Request Template

```markdown
**Is your feature request related to a problem?**
A clear and concise description of what the problem is. Ex. I'm always frustrated when [...]

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Would this feature benefit others?**
Explain how this would be useful to other users.

**Additional context**
Add any other context, screenshots, or mockups about the feature request here.

**Are you willing to implement this?**
Let us know if you'd like to work on this feature yourself.
```

---

## Code Review Guidelines

### For Contributors

When your PR is being reviewed:
- Respond to feedback constructively
- Ask questions if unclear
- Make requested changes promptly
- Don't take criticism personally
- Learn from the review process

### For Reviewers

When reviewing PRs:
- Be constructive and kind
- Explain why changes are needed
- Praise good solutions
- Test the changes locally
- Consider the user impact

---

## Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **GitHub Discussions**: General questions and ideas
- **Telegram**: [@DumbDragon](https://t.me/DumbDragon) - Quick questions

### Getting Help

Stuck on something? Here's how to get help:

1. Check existing documentation
2. Search closed issues for similar problems
3. Ask in GitHub Discussions
4. Reach out on Telegram

### Recognition

Contributors are recognized through:
- Credits in release notes
- Mention in AUTHORS file
- GitHub contributor badge
- Our eternal gratitude! 🙏

---

## License

By contributing to Zilium, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to Zilium!** 🚀

Every contribution, no matter how small, helps make this project better for everyone.
