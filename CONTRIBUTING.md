# Contributing to BrainVault Elite

First off, thank you for considering contributing to BrainVault Elite! It's people like you that make this project such a great tool.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Coding Standards](#coding-standards)
- [Commit Guidelines](#commit-guidelines)
- [Pull Request Process](#pull-request-process)
- [Module Development](#module-development)

---

## 📜 Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code:

- **Be respectful** - Different viewpoints and experiences are valuable
- **Be collaborative** - Work together and help others
- **Be professional** - Keep discussions focused and constructive
- **Be inclusive** - Welcome contributors of all backgrounds

---

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title and description**
- **Exact steps to reproduce**
- **Expected vs actual behavior**
- **System information** (OS, version, etc.)
- **Log files** (if applicable)
- **Screenshots** (if relevant)

**Template:**
```markdown
**Environment:**
- OS: Ubuntu 22.04
- Bash version: 5.1
- BrainVault Elite version: 2.0

**Steps to Reproduce:**
1. Run `sudo ./brainvault_elite.sh --dry-run`
2. Observe error at line X

**Expected Behavior:**
Should complete dry-run without errors

**Actual Behavior:**
Error: [paste error message]

**Logs:**
[attach /var/log/brainvault_elite_*.log]
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. Include:

- **Clear description** of the enhancement
- **Use case** - Why is this useful?
- **Proposed implementation** (if you have ideas)
- **Alternatives considered**

### Contributing Code

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

---

## 🛠️ Development Setup

### Prerequisites

- Ubuntu 22.04+ or Debian 11+
- Bash 4.0+
- Git
- Text editor (vim, VSCode, etc.)

### Clone and Setup

```bash
# Fork the repo on GitHub first, then:
git clone https://github.com/YOUR_USERNAME/brainvault-elite.git
cd brainvault-elite

# Make main script executable
chmod +x brainvault_elite.sh

# Validate all scripts
bash scripts/utils/validation.sh

# Run tests
bash test_brainvault.sh
```

### Testing Your Changes

```bash
# 1. Syntax validation
find . -name "*.sh" -exec bash -n {} \;

# 2. Dry-run test (safe, no changes)
sudo ./brainvault_elite.sh --dry-run

# 3. Full test suite
bash test_brainvault.sh

# 4. Test in VM (recommended)
# Use VirtualBox, VMware, or cloud sandbox
```

---

## 📝 Coding Standards

### Bash Style Guide

Follow these conventions for consistency:

#### 1. Indentation and Formatting

```bash
# Use 4 spaces (no tabs)
my_function() {
    local var="value"
    if [[ condition ]]; then
        do_something
    fi
}
```

#### 2. Naming Conventions

```bash
# Functions: lowercase_with_underscores
setup_firewall() { ... }

# Variables: lowercase_with_underscores
local backup_dir="/opt/backups"

# Constants: UPPERCASE_WITH_UNDERSCORES
readonly MAX_RETRIES=3

# Private functions: prefix with underscore
_internal_helper() { ... }
```

#### 3. Error Handling

```bash
# Always use set -euo pipefail in scripts
set -euo pipefail

# Check command availability
if ! check_command docker; then
    log_error "Docker not found"
    return 1
fi

# Use proper return codes
function_name() {
    if [[ condition ]]; then
        return 0  # Success
    else
        return 1  # Failure
    fi
}
```

#### 4. Logging

```bash
# Use appropriate log levels
log_debug "Variable: $var"      # Debug info
log_info "Starting process"     # General info
log_warn "Deprecated feature"   # Warnings
log_error "Operation failed"    # Errors
log_success "Completed"         # Success

# Use log_section for major steps
log_section "Installing Dependencies"
```

#### 5. Documentation

```bash
# Every function needs a header
# ============= Function Description =============

setup_feature() {
    # Brief description of what this function does
    # Args: None
    # Returns: 0 on success, 1 on failure
    
    log_section "Setting Up Feature"
    # Implementation
}
```

#### 6. Dry-Run Support

```bash
# ALL functions must support dry-run
my_function() {
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Category" "Action description"
        return 0
    fi
    
    # Normal execution
}
```

---

## 🔖 Commit Guidelines

### Commit Message Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation changes
- **style**: Code style changes (formatting)
- **refactor**: Code refactoring
- **test**: Adding or updating tests
- **chore**: Maintenance tasks

### Examples

```bash
feat(security): add IPv6 firewall rules

- Implement IPv6 support in firewall module
- Add tests for IPv6 rules
- Update documentation

Closes #123
```

```bash
fix(backup): correct encryption password handling

The backup script was not properly escaping passwords
with special characters. This fix adds proper quoting.

Fixes #456
```

```bash
docs(readme): update installation instructions

- Add troubleshooting section
- Clarify prerequisites
- Add screenshots
```

---

## 🔄 Pull Request Process

### Before Submitting

1. **Update documentation** - Reflect your changes in relevant docs
2. **Add tests** - Include tests for new features
3. **Run validation** - `bash scripts/utils/validation.sh`
4. **Test thoroughly** - Especially in a VM
5. **Update CHANGELOG** - Add entry for your changes

### PR Checklist

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added/updated
- [ ] All tests pass
- [ ] Dry-run mode works
- [ ] No syntax errors
- [ ] Backward compatible (if applicable)

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## Testing
Describe testing performed:
- [ ] Syntax validation passed
- [ ] Dry-run test passed
- [ ] Full installation test passed
- [ ] Tested in VM

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests added/pass
- [ ] No new warnings

## Related Issues
Closes #123
```

### Review Process

1. Maintainers will review within 1-2 weeks
2. Feedback will be provided via comments
3. Make requested changes
4. Once approved, PR will be merged

---

## 🔧 Module Development

### Creating a New Module

1. **Choose the right directory:**
   - `scripts/core/` - System operations
   - `scripts/security/` - Security features
   - `scripts/ai/` - AI/ML tools
   - `scripts/backup/` - Backup systems
   - `scripts/monitoring/` - Monitoring tools
   - `scripts/utils/` - Utilities

2. **Use the module template:**

```bash
#!/bin/bash
# ================================================================
# BrainVault Elite - Module Name
# Brief description
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# ============= Main Function =============

setup_my_feature() {
    log_section "Setting Up My Feature"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Category" "Install my feature"
        return 0
    fi
    
    # Check dependencies
    if ! check_command required_tool; then
        log_error "Required tool not found"
        return 1
    fi
    
    # Implementation
    run_cmd "command" "Description"
    
    log_success "Feature setup complete"
}

# ============= Export Functions =============

export -f setup_my_feature
```

3. **Test the module:**

```bash
# Validate syntax
bash -n scripts/path/to/module.sh

# Test in isolation
DRY_RUN=true bash -c "
    source scripts/utils/logging.sh
    source scripts/path/to/module.sh
    setup_my_feature
"

# Test integration
sudo ./brainvault_elite.sh --dry-run
```

4. **Document the module:**
   - Add function descriptions
   - Update README.md
   - Add usage examples

### Module Dependencies

**Dependency Hierarchy:**
```
utils/logging.sh (required by all)
    ↓
core/system.sh (basic operations)
    ↓
security/*, ai/*, backup/*, monitoring/* (feature modules)
```

**Managing Dependencies:**
```bash
# Source dependencies explicitly
source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# Check runtime dependencies
if ! check_command docker; then
    log_error "Docker required"
    return 1
fi
```

---

## 🧪 Testing Guidelines

### Test Coverage

Aim for:
- **Unit tests**: Individual functions
- **Integration tests**: Module interactions
- **End-to-end tests**: Full installation
- **Dry-run tests**: No system changes

### Writing Tests

Add tests to `test_brainvault.sh`:

```bash
test_my_feature() {
    print_header "My Feature Tests"
    
    # Test 1: Function exists
    if declare -F setup_my_feature &>/dev/null; then
        test_pass "Function exists"
    else
        test_fail "Function missing"
    fi
    
    # Test 2: Dry-run works
    if DRY_RUN=true setup_my_feature &>/dev/null; then
        test_pass "Dry-run works"
    else
        test_fail "Dry-run failed"
    fi
}
```

---

## 📚 Additional Resources

- **Module Development**: See `scripts/README.md`
- **Advanced Features**: See `ADVANCED_FEATURES.md`
- **Style Guide**: [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **ShellCheck**: [shellcheck.net](https://www.shellcheck.net/)

---

## 🎓 Learning Path

### For Beginners

1. Read `README.md` and `QUICK_START.md`
2. Run the script with `--dry-run`
3. Study existing modules
4. Start with documentation improvements
5. Progress to small bug fixes

### For Advanced Contributors

1. Review `ADVANCED_FEATURES.md`
2. Study the module architecture
3. Implement new features
4. Optimize performance
5. Review other PRs

---

## 💬 Communication

- **GitHub Issues**: Bug reports and feature requests
- **Pull Requests**: Code contributions
- **Discussions**: General questions and ideas

---

## 🏆 Recognition

Contributors will be:
- Listed in CONTRIBUTORS.md
- Mentioned in release notes
- Credited in relevant documentation

---

## ❓ Questions?

- Check existing issues and documentation
- Open a new issue with the "question" label
- Be clear and provide context

---

**Thank you for contributing to BrainVault Elite!** 🎉

Every contribution, no matter how small, makes a difference.

---

**Happy Coding!** 🚀
