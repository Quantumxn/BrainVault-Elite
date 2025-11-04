#!/bin/bash
# brainvault_elite.sh - Main orchestrator for BrainVault Elite
# A modular DevSecOps + AI bootstrap system for Linux

set -e  # Exit on error
set -o pipefail  # Exit on pipe failure

# Script metadata
VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global flags
DRY_RUN=0
SKIP_AI=0
SKIP_SECURITY=0
SKIP_DEV=0
SKIP_MONITORING=0
SKIP_DOCKER=0
SECURE_MODE=0
DISABLE_TELEMETRY=0
PARALLEL_INSTALL=0
DEBUG_MODE=0
INSTALL_ALL_LANGS=0

# ============================================================================
# Auto-load all utility modules first (they're required by other modules)
# ============================================================================

echo "Loading modules..."

# Load utilities first (required by all other modules)
for util_module in "$SCRIPT_DIR"/scripts/utils/*.sh; do
    if [[ -f "$util_module" ]]; then
        source "$util_module"
        echo "  ✓ Loaded: $(basename "$util_module")"
    fi
done

# Load security modules
for security_module in "$SCRIPT_DIR"/scripts/security/*.sh; do
    if [[ -f "$security_module" ]]; then
        source "$security_module"
        echo "  ✓ Loaded: $(basename "$security_module")"
    fi
done

# Load dev modules
for dev_module in "$SCRIPT_DIR"/scripts/dev/*.sh; do
    if [[ -f "$dev_module" ]]; then
        source "$dev_module"
        echo "  ✓ Loaded: $(basename "$dev_module")"
    fi
done

# Load monitoring modules
for monitoring_module in "$SCRIPT_DIR"/scripts/monitoring/*.sh; do
    if [[ -f "$monitoring_module" ]]; then
        source "$monitoring_module"
        echo "  ✓ Loaded: $(basename "$monitoring_module")"
    fi
done

echo ""

# ============================================================================
# Help and Usage
# ============================================================================

show_banner() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                                                                  ║"
    echo "║              🧠 BRAINVAULT ELITE v${VERSION}                       ║"
    echo "║                                                                  ║"
    echo "║      Modular DevSecOps + AI Bootstrap System for Linux          ║"
    echo "║                                                                  ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
}

show_usage() {
    cat <<EOF
Usage: sudo ./brainvault_elite.sh [OPTIONS]

OPTIONS:
    --dry-run              Simulation mode (no actual changes)
    --skip-ai              Skip AI/ML stack installation
    --skip-security        Skip security hardening
    --skip-dev             Skip development tools
    --skip-monitoring      Skip monitoring setup
    --skip-docker          Skip Docker installation
    --secure               Enable enhanced security mode
    --disable-telemetry    Block telemetry and tracking
    --parallel             Enable parallel installation
    --debug                Enable debug logging
    --install-all-langs    Install all programming languages
    -h, --help             Show this help message
    -v, --version          Show version information

EXAMPLES:
    # Full installation
    sudo ./brainvault_elite.sh

    # Dry run (simulation only)
    sudo ./brainvault_elite.sh --dry-run

    # Security-only installation
    sudo ./brainvault_elite.sh --skip-ai --skip-dev

    # AI-focused installation
    sudo ./brainvault_elite.sh --skip-security

    # Enhanced security mode
    sudo ./brainvault_elite.sh --secure --disable-telemetry

COMPONENTS:
    🔐 Security:    UFW, Fail2Ban, AppArmor, Kernel Hardening
    🤖 AI/ML:       PyTorch, Transformers, Jupyter, Scientific Stack
    🛠️  Dev Tools:  Python, Node.js, Docker, Git, Rust, Go
    📊 Monitoring:  Netdata, Prometheus, Backups, Health Checks

For more information, visit: https://github.com/yourusername/brainvault-elite
EOF
}

# ============================================================================
# Argument Parsing
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                enable_dryrun
                shift
                ;;
            --skip-ai)
                SKIP_AI=1
                export SKIP_AI
                shift
                ;;
            --skip-security)
                SKIP_SECURITY=1
                export SKIP_SECURITY
                shift
                ;;
            --skip-dev)
                SKIP_DEV=1
                export SKIP_DEV
                shift
                ;;
            --skip-monitoring)
                SKIP_MONITORING=1
                export SKIP_MONITORING
                shift
                ;;
            --skip-docker)
                SKIP_DOCKER=1
                export SKIP_DOCKER
                shift
                ;;
            --secure)
                SECURE_MODE=1
                export SECURE_MODE
                shift
                ;;
            --disable-telemetry)
                DISABLE_TELEMETRY=1
                export DISABLE_TELEMETRY
                shift
                ;;
            --parallel)
                PARALLEL_INSTALL=1
                export PARALLEL_INSTALL
                shift
                ;;
            --debug)
                DEBUG_MODE=1
                export DEBUG_MODE
                shift
                ;;
            --install-all-langs)
                INSTALL_ALL_LANGS=1
                export INSTALL_ALL_LANGS
                shift
                ;;
            -h|--help)
                show_banner
                show_usage
                exit 0
                ;;
            -v|--version)
                echo "BrainVault Elite v${VERSION}"
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# ============================================================================
# Pre-flight Checks
# ============================================================================

preflight_checks() {
    log_section "🔍 PRE-FLIGHT CHECKS"
    
    # Check if running as root
    if ! check_root; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    
    # Check system requirements
    check_system_requirements || {
        log_warn "System requirements check failed, but continuing anyway"
    }
    
    # Check internet connectivity
    log_info "Checking internet connectivity..."
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "Internet connection available"
    else
        log_warn "No internet connection detected. Some installations may fail."
    fi
    
    log_success "Pre-flight checks completed"
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main_installation() {
    log_section "🚀 STARTING BRAINVAULT ELITE INSTALLATION"
    
    # Show configuration
    log_info "Installation Configuration:"
    echo "  Dry Run:              $DRY_RUN"
    echo "  Skip AI:              $SKIP_AI"
    echo "  Skip Security:        $SKIP_SECURITY"
    echo "  Skip Development:     $SKIP_DEV"
    echo "  Skip Monitoring:      $SKIP_MONITORING"
    echo "  Skip Docker:          $SKIP_DOCKER"
    echo "  Secure Mode:          $SECURE_MODE"
    echo "  Disable Telemetry:    $DISABLE_TELEMETRY"
    echo "  Parallel Install:     $PARALLEL_INSTALL"
    echo "  Debug Mode:           $DEBUG_MODE"
    echo ""
    
    # Phase 1: Security Stack
    if [[ "$SKIP_SECURITY" != "1" ]]; then
        setup_security_stack
    fi
    
    # Phase 2: Development Stack
    if [[ "$SKIP_DEV" != "1" ]]; then
        setup_dev_stack
    fi
    
    # Phase 3: Monitoring Stack
    if [[ "$SKIP_MONITORING" != "1" ]]; then
        setup_monitoring_stack
    fi
    
    log_success "All installation phases completed"
}

# ============================================================================
# Post-installation Tasks
# ============================================================================

post_installation() {
    log_section "🎉 POST-INSTALLATION TASKS"
    
    # Show installed components
    log_info "Installed Components:"
    echo ""
    
    if [[ "$SKIP_SECURITY" != "1" ]]; then
        show_security_status
    fi
    
    if [[ "$SKIP_DEV" != "1" ]]; then
        show_dev_status
    fi
    
    if [[ "$SKIP_MONITORING" != "1" ]]; then
        show_monitoring_status
    fi
    
    # Show dry-run summary
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        show_dryrun_summary
    fi
    
    # Next steps
    log_section "📝 NEXT STEPS"
    echo ""
    echo "1. Review the installation logs"
    echo "2. Reboot the system to apply all changes (if not in dry-run mode)"
    echo "3. Configure cloud backup with: rclone config"
    echo "4. Access monitoring at: http://localhost:19999 (Netdata)"
    echo "5. Start Jupyter Lab with: jupyter lab --ip=0.0.0.0 --no-browser"
    echo ""
    
    if [[ "${DRY_RUN:-0}" != "1" ]]; then
        echo "To validate all scripts, run:"
        echo "  sudo $SCRIPT_DIR/scripts/validate_syntax.sh"
        echo ""
    fi
    
    log_success "BrainVault Elite installation completed!"
}

# ============================================================================
# Error Handler
# ============================================================================

error_handler() {
    local exit_code=$?
    log_error "Installation failed with exit code: $exit_code"
    
    if [[ -f "$ERROR_LOG" ]]; then
        log_error "Check error log: $ERROR_LOG"
    fi
    
    log_info "To retry, fix the errors and run the script again"
    exit $exit_code
}

# ============================================================================
# Main Execution
# ============================================================================

main() {
    # Setup error handling
    trap error_handler ERR
    trap cleanup EXIT
    
    # Show banner
    show_banner
    
    # Parse command-line arguments
    parse_arguments "$@"
    
    # Pre-flight checks
    preflight_checks
    
    # Main installation
    main_installation
    
    # Post-installation
    post_installation
    
    # Final message
    log_section "✅ ALL DONE!"
    
    if [[ "${DRY_RUN:-0}" != "1" ]]; then
        echo ""
        echo "🎉 BrainVault Elite has been successfully installed!"
        echo ""
        echo "Consider rebooting your system to ensure all changes take effect:"
        echo "  sudo reboot"
        echo ""
    fi
}

# Run main function
main "$@"
