#!/bin/bash
# ================================================================
# BrainVault Elite - Custom Module Example
# This is a template for creating your own custom modules
# ================================================================

# STEP 1: Source the logging utilities (REQUIRED)
source "$(dirname "${BASH_SOURCE[0]}")/../scripts/utils/logging.sh"

# STEP 2: Define module metadata
readonly MODULE_NAME="custom_example"
readonly MODULE_VERSION="1.0.0"
readonly MODULE_AUTHOR="Your Name"

# ================================================================
# FUNCTION: setup_custom_feature
# Description: Main setup function for your custom feature
# Returns: 0 on success, 1 on failure
# ================================================================

setup_custom_feature() {
    log_section "Setting Up Custom Feature"
    
    # STEP 3: Handle dry-run mode (REQUIRED)
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Custom" "Install custom packages"
        add_to_summary "Custom" "Configure custom service"
        return 0
    fi
    
    # STEP 4: Check dependencies
    log_info "Checking dependencies..."
    if ! check_command curl; then
        log_error "curl is required but not installed"
        return 1
    fi
    
    # STEP 5: Install packages
    log_info "Installing custom packages..."
    local packages=(
        "package1"
        "package2"
        "package3"
    )
    
    if ! install_pkg "${packages[@]}"; then
        log_error "Failed to install packages"
        return 1
    fi
    
    # STEP 6: Perform configuration
    log_info "Configuring custom feature..."
    configure_custom_feature
    
    # STEP 7: Verify installation
    if verify_custom_feature; then
        log_success "Custom feature installed and configured successfully"
        return 0
    else
        log_error "Custom feature verification failed"
        return 1
    fi
}

# ================================================================
# FUNCTION: configure_custom_feature
# Description: Configuration logic for your feature
# Returns: 0 on success, 1 on failure
# ================================================================

configure_custom_feature() {
    local config_file="/etc/brainvault/custom.conf"
    
    log_info "Creating configuration file: $config_file"
    
    # Create directory
    mkdir -p "$(dirname "$config_file")"
    
    # Write configuration
    cat > "$config_file" <<'EOF'
# BrainVault Elite - Custom Feature Configuration
enabled = true
log_level = info
custom_option = value
EOF
    
    chmod 644 "$config_file"
    log_success "Configuration created"
    
    return 0
}

# ================================================================
# FUNCTION: verify_custom_feature
# Description: Verify that the feature is working
# Returns: 0 if verified, 1 otherwise
# ================================================================

verify_custom_feature() {
    log_info "Verifying custom feature..."
    
    # Check if configuration exists
    if [[ ! -f "/etc/brainvault/custom.conf" ]]; then
        log_error "Configuration file not found"
        return 1
    fi
    
    # Check if service is running (example)
    # if ! systemctl is-active --quiet custom-service; then
    #     log_warn "Custom service not running"
    #     return 1
    # fi
    
    log_success "Verification passed"
    return 0
}

# ================================================================
# FUNCTION: show_custom_status
# Description: Display status of the custom feature
# ================================================================

show_custom_status() {
    log_section "Custom Feature Status"
    
    if [[ -f "/etc/brainvault/custom.conf" ]]; then
        log_success "Configuration: Installed"
    else
        log_info "Configuration: Not found"
    fi
    
    # Add more status checks here
}

# ================================================================
# FUNCTION: cleanup_custom_feature
# Description: Clean up and remove the custom feature
# ================================================================

cleanup_custom_feature() {
    log_section "Cleaning Up Custom Feature"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        add_to_summary "Cleanup" "Remove custom feature"
        return 0
    fi
    
    log_warn "Removing custom feature..."
    
    # Remove configuration
    if [[ -f "/etc/brainvault/custom.conf" ]]; then
        rm -f "/etc/brainvault/custom.conf"
        log_info "Configuration removed"
    fi
    
    # Stop and disable service (if applicable)
    # systemctl stop custom-service 2>/dev/null
    # systemctl disable custom-service 2>/dev/null
    
    log_success "Custom feature cleaned up"
}

# ================================================================
# EXPORT FUNCTIONS
# Make functions available to other scripts
# ================================================================

export -f setup_custom_feature
export -f configure_custom_feature
export -f verify_custom_feature
export -f show_custom_status
export -f cleanup_custom_feature

# ================================================================
# USAGE NOTES
# ================================================================
#
# To use this module:
#
# 1. Copy this file to scripts/custom/
#    cp examples/custom_module_example.sh scripts/custom/my_module.sh
#
# 2. Customize the functions for your needs
#
# 3. Make it executable:
#    chmod +x scripts/custom/my_module.sh
#
# 4. The module will be auto-loaded on next run
#
# 5. Call your function from brainvault_elite.sh:
#    Add to appropriate phase: setup_custom_feature
#
# 6. Test with dry-run:
#    sudo ./brainvault_elite.sh --dry-run
#
# ================================================================
