#!/bin/bash
# BrainVault Elite - Main Orchestrator Script
# Modular DevSecOps + AI Bootstrap System

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Global configuration flags
DRY_RUN=0
SKIP_AI=0
SKIP_SECURITY=0
SECURE_MODE=0
DISABLE_TELEMETRY=0
PARALLEL=0
DEBUG=0

# Source all utility modules first
for util in "$SCRIPT_DIR/scripts/utils"/*.sh; do
    [[ -f "$util" ]] && source "$util"
done

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=1
                export DRY_RUN
                log_info "Dry-run mode enabled"
                shift
                ;;
            --skip-ai)
                SKIP_AI=1
                log_info "Skipping AI stack installation"
                shift
                ;;
            --skip-security)
                SKIP_SECURITY=1
                log_info "Skipping security stack installation"
                shift
                ;;
            --secure)
                SECURE_MODE=1
                export SECURE_MODE
                log_info "Secure mode enabled (additional hardening)"
                shift
                ;;
            --disable-telemetry)
                DISABLE_TELEMETRY=1
                export DISABLE_TELEMETRY
                log_info "Telemetry blocking enabled"
                shift
                ;;
            --parallel)
                PARALLEL=1
                log_info "Parallel installation enabled"
                shift
                ;;
            --debug)
                DEBUG=1
                export DEBUG
                log_info "Debug mode enabled"
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

show_help() {
    cat << EOF
BrainVault Elite - Modular DevSecOps + AI Bootstrap System

Usage: sudo ./brainvault_elite.sh [OPTIONS]

Options:
    --dry-run          Simulation mode (no changes will be made)
    --skip-ai          Skip AI/ML stack installation
    --skip-security    Skip security stack installation
    --secure           Enable additional kernel/network hardening
    --disable-telemetry Block telemetry endpoints
    --parallel         Run installations in parallel (faster)
    --debug            Enable detailed debug logging
    -h, --help         Show this help message

Examples:
    sudo ./brainvault_elite.sh
    sudo ./brainvault_elite.sh --dry-run
    sudo ./brainvault_elite.sh --skip-ai --secure
    sudo ./brainvault_elite.sh --skip-security --parallel
EOF
}

# Auto-source all modules
load_modules() {
    log_section "Loading BrainVault Elite Modules"
    
    # Source all scripts in order (utils already sourced)
    local modules=(
        "scripts/security/*.sh"
        "scripts/dev/*.sh"
        "scripts/monitoring/*.sh"
    )
    
    for pattern in "${modules[@]}"; do
        for module in $pattern; do
            if [[ -f "$module" ]]; then
                source "$module"
                log_debug "Loaded: $module"
            fi
        done
    done
    
    log_success "All modules loaded"
}

# Validate syntax before execution
validate_before_run() {
    log_section "Pre-flight Validation"
    
    if [[ -f "$SCRIPT_DIR/scripts/validate_syntax.sh" ]]; then
        log_step "Running syntax validation..."
        if bash "$SCRIPT_DIR/scripts/validate_syntax.sh"; then
            log_success "Syntax validation passed"
        else
            log_error "Syntax validation failed. Aborting."
            exit 1
        fi
    else
        log_warn "validate_syntax.sh not found, skipping validation"
    fi
}

# Main installation function
main_install() {
    log_section "BrainVault Elite Installation"
    
    # Check root privileges
    check_root
    
    # Update package lists
    if [[ "$DRY_RUN" != "1" ]]; then
        log_step "Updating package lists..."
        apt-get update -qq
    else
        log_warn "[DRY-RUN] Would update package lists"
    fi
    
    # Install security stack
    if [[ "$SKIP_SECURITY" == "0" ]]; then
        if [[ "$PARALLEL" == "1" ]]; then
            install_security_stack &
        else
            install_security_stack
        fi
    fi
    
    # Install dev/AI stack
    if [[ "$SKIP_AI" == "0" ]]; then
        if [[ "$PARALLEL" == "1" ]]; then
            install_dev_stack &
        else
            install_dev_stack
        fi
    fi
    
    # Wait for parallel jobs
    if [[ "$PARALLEL" == "1" ]]; then
        log_step "Waiting for parallel installations..."
        wait
    fi
    
    # Install monitoring stack
    install_monitoring_stack
    
    log_success "Installation phase completed"
}

# Main setup function
main_setup() {
    log_section "BrainVault Elite Configuration"
    
    # Setup security stack
    if [[ "$SKIP_SECURITY" == "0" ]]; then
        setup_security_stack
    fi
    
    # Setup dev/AI stack
    if [[ "$SKIP_AI" == "0" ]]; then
        setup_dev_stack
    fi
    
    # Setup monitoring stack
    setup_monitoring_stack
    
    log_success "Configuration phase completed"
}

# Status check function
main_status() {
    log_section "BrainVault Elite Status Check"
    
    if [[ "$SKIP_SECURITY" == "0" ]]; then
        check_security_status
    fi
    
    if [[ "$SKIP_AI" == "0" ]]; then
        check_dev_status
    fi
    
    check_monitoring_stack_status
    
    log_success "Status check completed"
}

# Main execution
main() {
    # Parse arguments
    parse_arguments "$@"
    
    # Show banner
    log_section "🧠 BrainVault Elite - Modular DevSecOps + AI Bootstrap"
    
    # Validate syntax
    validate_before_run
    
    # Load all modules
    load_modules
    
    # Run installation and setup
    main_install
    main_setup
    
    # Show status
    main_status
    
    # Print dry-run summary if applicable
    print_dryrun_summary
    
    log_section "✅ BrainVault Elite Setup Complete"
    log_info "System is now hardened and ready for AI/ML development"
    
    if [[ "$DRY_RUN" == "1" ]]; then
        log_warn "This was a dry-run. No changes were made."
        log_info "Run without --dry-run to apply changes."
    fi
}

# Run main if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
