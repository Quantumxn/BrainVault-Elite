# 📚 BrainVault Elite - Module Development Guide

This guide explains how to create, maintain, and extend BrainVault Elite modules.

---

## 📋 Module Structure

### Standard Module Template

```bash
#!/bin/bash
# ================================================================
# BrainVault Elite - Module Name
# Brief description of what this module does
# ================================================================

# Source the logging utilities (required)
source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# ============= Function Section =============

my_function() {
    log_section "Descriptive Section Title"
    
    # Handle dry-run mode
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Category" "Description of action"
        return 0
    fi
    
    # Pre-checks
    if ! check_command required_command package_name; then
        log_warn "Required command not found"
        return 1
    fi
    
    # Main implementation
    log_info "Starting operation..."
    run_cmd "command_to_execute" "Description of operation"
    
    # Error handling
    if [[ $? -ne 0 ]]; then
        log_error "Operation failed"
        return 1
    fi
    
    log_success "Operation completed successfully"
}

# ============= Export Section =============

# Export all public functions
export -f my_function another_function
```

---

## 🎯 Module Guidelines

### 1. **Naming Conventions**

```bash
# File names: lowercase with underscores
security/firewall.sh           # ✓ Good
security/Firewall.sh           # ✗ Bad
security/firewall-config.sh    # ✗ Bad (use underscores)

# Function names: lowercase with underscores
setup_firewall()               # ✓ Good
setupFirewall()                # ✗ Bad (camelCase)
Setup_Firewall()               # ✗ Bad (PascalCase)

# Constants: UPPERCASE with underscores
readonly MAX_RETRIES=3         # ✓ Good
readonly maxRetries=3          # ✗ Bad
```

### 2. **Required Components**

Every module must include:

```bash
# 1. Shebang
#!/bin/bash

# 2. Header comment
# ================================================================
# BrainVault Elite - Module Name
# Description
# ================================================================

# 3. Source logging utilities
source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# 4. Functions with proper structure

# 5. Export statement
export -f function_name
```

### 3. **Logging Best Practices**

```bash
# Use appropriate log levels
log_debug "Variable value: $var"           # Debugging
log_info "Starting process..."             # General info
log_warn "Deprecated feature used"         # Warnings
log_error "Connection failed"              # Errors
log_success "Installation completed"       # Success

# Use log_section for major steps
log_section "Installing Dependencies"

# Use run_cmd for command execution
run_cmd "apt-get update" "Updating package lists"

# Use show_progress for long operations
show_progress 50 100 "Processing files"
```

### 4. **Dry-Run Support**

All modules must support dry-run mode:

```bash
my_function() {
    log_section "My Function"
    
    # ALWAYS check dry-run mode first
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Category" "Action description"
        # Add all planned actions to summary
        add_to_summary "Category" "Another action"
        return 0  # Exit without execution
    fi
    
    # Normal execution continues here
    run_cmd "command" "Description"
}
```

### 5. **Error Handling**

```bash
# Always use set -euo pipefail in main script
# (already set in brainvault_elite.sh)

# Check command availability
if ! check_command docker; then
    log_error "Docker not installed"
    return 1
fi

# Validate paths
if ! validate_path "/etc/config.conf" "file"; then
    log_error "Config file not found"
    return 1
fi

# Handle command failures
if ! run_cmd "risky_command" "Description"; then
    log_error "Command failed"
    # Decide: return 1 or continue?
    return 1
fi

# Use error_exit for fatal errors
if [[ ! -d "/critical/path" ]]; then
    error_exit "Critical directory missing" 1
fi
```

### 6. **Dependencies**

Declare dependencies clearly:

```bash
# At the top of the module
# Dependencies:
#   - utils/logging.sh (required)
#   - core/system.sh (for install_pkg function)
#   - docker (runtime)

# Check runtime dependencies
check_dependencies() {
    local deps=("docker" "curl" "jq")
    local missing=()
    
    for dep in "${deps[@]}"; do
        if ! check_command "$dep"; then
            missing+=("$dep")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing[*]}"
        return 1
    fi
}
```

---

## 🔧 Available Utility Functions

### From `utils/logging.sh`

```bash
# Logging
log()                    # General log with timestamp
log_info()               # Info message (blue)
log_success()            # Success message (green)
log_warn()               # Warning message (yellow)
log_error()              # Error message (red)
log_debug()              # Debug message (magenta)
log_section()            # Section header (bold cyan)

# Error handling
error_exit()             # Log error and exit with code
check_root()             # Verify root privileges
check_command()          # Check if command exists
validate_path()          # Validate file/directory path

# Command execution
run_cmd()                # Execute command with logging
run_cmd_silent()         # Execute command silently
install_pkg()            # Install packages with apt

# Progress tracking
show_progress()          # Show progress indicator
add_to_summary()         # Add action to dry-run summary
print_dry_run_summary()  # Print complete dry-run summary
```

### From `core/system.sh`

```bash
create_snapshot()        # Create Timeshift snapshot
backup_configs()         # Backup /etc directory
update_system()          # Update and upgrade packages
install_essential_tools() # Install common utilities
show_system_info()       # Display system information
cleanup_system()         # Clean up packages and cache
final_steps()            # Final cleanup and messages
```

---

## 🎨 Module Categories

### Core Modules (`scripts/core/`)

System-level operations:
- System updates
- Package management
- Snapshots and backups
- Basic utilities

### Security Modules (`scripts/security/`)

Security hardening:
- Firewall configuration
- Intrusion detection
- Kernel hardening
- Audit systems

### AI Modules (`scripts/ai/`)

AI and development tools:
- Python ML stack
- Container platforms
- Development tools
- GPU support

### Backup Modules (`scripts/backup/`)

Backup and recovery:
- Backup automation
- Encryption
- Remote sync
- Restore procedures

### Monitoring Modules (`scripts/monitoring/`)

Monitoring and auditing:
- System monitoring
- Log analysis
- Security audits
- Performance tracking

### Utility Modules (`scripts/utils/`)

Helper functions:
- Logging
- Validation
- Common utilities

---

## 📝 Creating a New Module

### Step-by-Step Guide

#### 1. Choose Category

Decide which directory your module belongs to:
```bash
scripts/
├── core/          # System operations
├── security/      # Security features
├── ai/            # AI/ML tools
├── backup/        # Backup systems
├── monitoring/    # Monitoring tools
└── utils/         # Utilities
```

#### 2. Create Module File

```bash
# Create file
touch scripts/category/my_module.sh
chmod +x scripts/category/my_module.sh
```

#### 3. Write Module Code

```bash
#!/bin/bash
# ================================================================
# BrainVault Elite - My Module
# This module does X, Y, and Z
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# ============= Main Function =============

setup_my_feature() {
    log_section "Setting Up My Feature"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "My Category" "Install my feature"
        return 0
    fi
    
    # Check dependencies
    if ! check_command required_tool; then
        install_pkg required_tool
    fi
    
    # Main implementation
    log_info "Configuring feature..."
    run_cmd "configuration_command" "Configuring my feature"
    
    log_success "My feature configured successfully"
}

# ============= Helper Functions =============

my_helper_function() {
    # Helper functions don't need to be exported
    # unless used by other modules
    log_debug "Helper function called"
}

# ============= Export Functions =============

export -f setup_my_feature
```

#### 4. Integrate with Main Script

The module is automatically loaded! Just add a call in the appropriate phase:

```bash
# In brainvault_elite.sh, add to appropriate phase:

phase_custom() {
    log_section "Phase X: Custom Features"
    
    # Your module function is already available
    setup_my_feature
    
    log_success "Custom features installed"
}

# Call from main()
main() {
    # ...
    phase_custom
    # ...
}
```

#### 5. Test Your Module

```bash
# Syntax validation
bash -n scripts/category/my_module.sh

# Dry-run test
sudo ./brainvault_elite.sh --dry-run | grep "My Feature"

# Full test in VM
sudo ./brainvault_elite.sh --verbose
```

---

## 🧪 Testing Modules

### 1. Syntax Validation

```bash
# Validate all scripts
bash scripts/utils/validation.sh

# Validate specific module
bash -n scripts/security/my_module.sh
```

### 2. Dry-Run Testing

```bash
# Test without making changes
sudo DRY_RUN=true bash -c "
    source scripts/utils/logging.sh
    source scripts/security/my_module.sh
    setup_my_feature
"
```

### 3. Isolated Testing

```bash
# Test module independently
#!/bin/bash
set -euo pipefail

# Set up test environment
export DRY_RUN=false
export LOGFILE="/tmp/test.log"

# Source dependencies
source scripts/utils/logging.sh
source scripts/security/my_module.sh

# Run function
setup_my_feature

# Verify results
if [[ $? -eq 0 ]]; then
    echo "✓ Test passed"
else
    echo "✗ Test failed"
    exit 1
fi
```

### 4. Integration Testing

```bash
# Full integration test
sudo ./brainvault_elite.sh --dry-run
sudo ./brainvault_elite.sh --verbose > test_output.log 2>&1

# Verify
grep -q "My Feature" test_output.log && echo "✓ Module integrated"
```

---

## 📦 Example: Complete Module

Here's a complete example module:

```bash
#!/bin/bash
# ================================================================
# BrainVault Elite - Example Module
# Demonstrates best practices for module development
# ================================================================

source "$(dirname "${BASH_SOURCE[0]}")/../utils/logging.sh"

# Module configuration
readonly MODULE_NAME="example"
readonly MODULE_VERSION="1.0"
readonly CONFIG_FILE="/etc/brainvault/example.conf"

# ============= Pre-checks =============

check_example_dependencies() {
    log_debug "Checking dependencies for $MODULE_NAME module"
    
    local required_commands=("curl" "jq")
    local missing=()
    
    for cmd in "${required_commands[@]}"; do
        if ! check_command "$cmd"; then
            missing+=("$cmd")
        fi
    done
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required commands: ${missing[*]}"
        return 1
    fi
    
    log_success "All dependencies available"
    return 0
}

# ============= Main Functions =============

setup_example_feature() {
    log_section "Setting Up Example Feature"
    
    # Dry-run support
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Example" "Install example packages"
        add_to_summary "Example" "Configure example feature"
        add_to_summary "Example" "Enable example service"
        return 0
    fi
    
    # Pre-checks
    if ! check_example_dependencies; then
        log_error "Dependency check failed"
        return 1
    fi
    
    # Installation
    log_info "Installing example packages..."
    install_pkg example-package
    
    # Configuration
    log_info "Creating configuration file..."
    create_example_config
    
    # Service setup
    log_info "Enabling example service..."
    run_cmd "systemctl enable example" "Enable example service"
    run_cmd "systemctl start example" "Start example service"
    
    # Verification
    if systemctl is-active --quiet example; then
        log_success "Example feature configured and running"
    else
        log_warn "Example service not running"
        return 1
    fi
}

create_example_config() {
    if [[ "$DRY_RUN" == "true" ]]; then
        return 0
    fi
    
    log_debug "Creating config: $CONFIG_FILE"
    
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    cat > "$CONFIG_FILE" <<'EOF'
# BrainVault Elite - Example Configuration
enabled = true
log_level = info
feature_x = enabled
EOF
    
    chmod 644 "$CONFIG_FILE"
    log_success "Configuration created: $CONFIG_FILE"
}

show_example_status() {
    log_section "Example Feature Status"
    
    if systemctl is-active --quiet example 2>/dev/null; then
        log_success "Service: Running"
    else
        log_info "Service: Not running"
    fi
    
    if [[ -f "$CONFIG_FILE" ]]; then
        log_success "Config: $CONFIG_FILE"
    else
        log_warn "Config: Not found"
    fi
}

# ============= Cleanup Functions =============

cleanup_example() {
    log_info "Cleaning up example feature..."
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Cleanup" "Stop and remove example feature"
        return 0
    fi
    
    run_cmd "systemctl stop example" "Stop example service" false
    run_cmd "systemctl disable example" "Disable example service" false
    
    if [[ -f "$CONFIG_FILE" ]]; then
        rm -f "$CONFIG_FILE"
        log_info "Removed config file"
    fi
    
    log_success "Example feature cleaned up"
}

# ============= Export Functions =============

export -f setup_example_feature show_example_status cleanup_example
```

---

## 🐛 Debugging Modules

### Enable Debug Output

```bash
# Set log level to debug
export LOG_LEVEL=0

# Run with verbose mode
sudo ./brainvault_elite.sh --verbose
```

### Common Issues

#### Module Not Loading

```bash
# Check syntax
bash -n scripts/path/to/module.sh

# Check if file is executable
ls -l scripts/path/to/module.sh
chmod +x scripts/path/to/module.sh

# Check module path in source_modules()
```

#### Function Not Found

```bash
# Ensure function is exported
export -f my_function

# Check if module was sourced
declare -F | grep my_function
```

#### Dry-Run Not Working

```bash
# Always check DRY_RUN at function start
if [[ "$DRY_RUN" == "true" ]]; then
    add_to_summary "Category" "Action"
    return 0
fi
```

---

## 📚 Additional Resources

- **Main README**: [../README.md](../README.md)
- **Advanced Features**: [../ADVANCED_FEATURES.md](../ADVANCED_FEATURES.md)
- **Bash Best Practices**: [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- **ShellCheck**: [shellcheck.net](https://www.shellcheck.net/)

---

## 🤝 Contributing Modules

Want to contribute your module?

1. Follow this guide
2. Test thoroughly
3. Document your module
4. Submit a pull request

---

**Happy Module Development! 🚀**
