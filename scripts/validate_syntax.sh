#!/bin/bash
# Syntax validation script for all BrainVault Elite scripts

# Source utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/utils/logging.sh"

validate_syntax() {
    log_section "Validating Script Syntax"
    
    local errors=0
    local total=0
    local failed_files=()
    
    # Find all shell scripts
    local scripts=$(find "$SCRIPT_DIR" -type f -name "*.sh" | sort)
    
    log_info "Found $(echo "$scripts" | wc -l) scripts to validate"
    
    while IFS= read -r script; do
        ((total++))
        log_step "Validating: $script"
        
        # Use bash -n to check syntax
        if bash -n "$script" 2>&1; then
            log_success "✓ $script"
        else
            log_error "✗ $script"
            ((errors++))
            failed_files+=("$script")
        fi
    done <<< "$scripts"
    
    echo ""
    log_section "Validation Summary"
    log_info "Total scripts: $total"
    
    if [[ $errors -eq 0 ]]; then
        log_success "All scripts passed syntax validation!"
        return 0
    else
        log_error "$errors script(s) failed validation:"
        for file in "${failed_files[@]}"; do
            log_error "  - $file"
        done
        return 1
    fi
}

# Run validation if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    validate_syntax
    exit $?
fi
