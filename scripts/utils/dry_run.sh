#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Dry-Run Summary & Validation
# ================================================================

# Dry-run operation tracking
declare -A DRY_RUN_OPS
DRY_RUN_COUNT=0
DRY_RUN_ERRORS=0

# Track dry-run operation
track_dry_run_op() {
    local category="$1"
    local operation="$2"
    local description="$3"
    
    ((DRY_RUN_COUNT++))
    DRY_RUN_OPS["$DRY_RUN_COUNT"]="$category|$operation|$description"
}

# Generate unified dry-run summary
generate_dry_run_summary() {
    if [ "${DRY_RUN:-false}" != "true" ]; then
        return 0
    fi
    
    log_info "═══════════════════════════════════════════════════════════"
    log_info "📋 DRY-RUN SUMMARY"
    log_info "═══════════════════════════════════════════════════════════"
    
    local category_count=()
    local categories=()
    
    # Count operations by category
    for op in "${DRY_RUN_OPS[@]}"; do
        IFS='|' read -r category operation desc <<< "$op"
        
        if [[ ! " ${categories[@]} " =~ " ${category} " ]]; then
            categories+=("$category")
            category_count["$category"]=0
        fi
        
        ((category_count["$category"]++))
    done
    
    # Display summary by category
    for category in "${categories[@]}"; do
        log_info ""
        log_info "━━━ $category ━━━"
        
        for op in "${DRY_RUN_OPS[@]}"; do
            IFS='|' read -r op_category operation desc <<< "$op"
            
            if [ "$op_category" = "$category" ]; then
                log_info "  • $desc"
                log_debug "    Command: $operation"
            fi
        done
        
        log_info "  Total: ${category_count[$category]} operations"
    done
    
    log_info ""
    log_info "═══════════════════════════════════════════════════════════"
    log_info "Total operations planned: $DRY_RUN_COUNT"
    log_info "═══════════════════════════════════════════════════════════"
    
    if [ $DRY_RUN_ERRORS -gt 0 ]; then
        log_warn "Warnings/Errors detected: $DRY_RUN_ERRORS"
    fi
}

# Validate bash syntax for all scripts
validate_bash_syntax() {
    local script_dir="${1:-/workspace/scripts}"
    local errors=0
    local warnings=0
    
    log_info "Validating bash syntax for all scripts in $script_dir..."
    
    while IFS= read -r -d '' script; do
        log_debug "Checking: $script"
        
        if ! bash -n "$script" 2>&1 | tee -a "$LOGFILE"; then
            log_error "Syntax error in: $script"
            ((errors++))
        else
            log_debug "✓ Syntax OK: $script"
        fi
        
        # Check for common issues with shellcheck if available
        if command_exists shellcheck; then
            if shellcheck -x "$script" >>"$LOGFILE" 2>&1; then
                log_debug "✓ ShellCheck passed: $script"
            else
                log_warn "ShellCheck warnings in: $script"
                ((warnings++))
            fi
        fi
    done < <(find "$script_dir" -type f -name "*.sh" -print0)
    
    log_info "Syntax validation complete: $errors errors, $warnings warnings"
    
    if [ $errors -gt 0 ]; then
        log_error "Bash syntax validation failed with $errors errors"
        return 1
    fi
    
    log_success "All scripts passed syntax validation"
    return 0
}
