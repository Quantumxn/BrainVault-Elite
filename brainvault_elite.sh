#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Full System Hardening + AI Stack Bootstrap
# Version: 2.0 (Modular)
# Author : MD Jahirul
# ================================================================

set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$SCRIPT_DIR/scripts"

# Initialize variables
DRY_RUN=false
SKIP_SECURITY=false
SKIP_AI=false
SKIP_BACKUP=false
DISABLE_TELEMETRY=false
ENABLE_PARALLEL=false
DEBUG=false

# Temporary simple logging before modules are loaded
_temp_log() {
    echo "[$(date '+%F %T')] $*"
}

# ================================================================
# CLI Argument Parser
# ================================================================

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                _temp_log "🔸 DRY-RUN mode enabled"
                shift
                ;;
            --skip-ai)
                SKIP_AI=true
                _temp_log "⚠️  Skipping AI/Dev stack installation"
                shift
                ;;
            --skip-security)
                SKIP_SECURITY=true
                _temp_log "⚠️  Skipping security stack installation"
                shift
                ;;
            --secure)
                SKIP_SECURITY=false
                DISABLE_TELEMETRY=false
                _temp_log "🔐 Security mode enabled (full security stack)"
                shift
                ;;
            --disable-telemetry)
                DISABLE_TELEMETRY=true
                _temp_log "🚫 Telemetry blocking disabled"
                shift
                ;;
            --parallel)
                ENABLE_PARALLEL=true
                _temp_log "⚡ Parallel installation enabled"
                shift
                ;;
            --debug)
                DEBUG=true
                _temp_log "🔍 Debug mode enabled"
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                _temp_log "ERROR: Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Export variables for use in modules
    export DRY_RUN SKIP_SECURITY SKIP_AI SKIP_BACKUP DISABLE_TELEMETRY ENABLE_PARALLEL DEBUG
}

show_help() {
    cat <<EOF
🧠 BrainVault Elite — System Hardening + AI Stack Bootstrap

Usage: $0 [OPTIONS]

Options:
    --dry-run              Run in dry-run mode (no actual changes)
    --skip-ai              Skip AI/Dev stack installation
    --skip-security        Skip security stack installation
    --secure               Enable full security stack (default)
    --disable-telemetry    Disable telemetry blocking
    --parallel             Enable parallel installation (experimental)
    --debug                Enable debug logging
    --help, -h             Show this help message

Examples:
    $0 --dry-run
    $0 --skip-ai --secure
    $0 --disable-telemetry
    $0 --parallel --debug

EOF
}

# ================================================================
# Module Auto-Loading System
# ================================================================

load_all_modules() {
    _temp_log "Loading modules from $SCRIPTS_DIR..."
    
    # Load utility modules first (required by others)
    if [ -d "$SCRIPTS_DIR/utils" ]; then
        for util_module in "$SCRIPTS_DIR/utils"/*.sh; do
            if [ -f "$util_module" ]; then
                _temp_log "Loading utility: $(basename "$util_module")"
                source "$util_module" || {
                    _temp_log "ERROR: Failed to load utility module: $util_module"
                    exit 1
                }
            fi
        done
    fi
    
    # Initialize logging after utilities are loaded
    if type init_logging >/dev/null 2>&1; then
        init_logging
    fi
    
    # Load security modules
    if [ -d "$SCRIPTS_DIR/security" ] && [ "$SKIP_SECURITY" = "false" ]; then
        if type log_debug >/dev/null 2>&1; then
            log_debug "Loading security modules..."
        else
            _temp_log "Loading security modules..."
        fi
        source "$SCRIPTS_DIR/security/security_main.sh" || {
            if type log_error >/dev/null 2>&1; then
                log_error "Failed to load security modules"
            else
                _temp_log "ERROR: Failed to load security modules"
            fi
            exit 1
        }
    fi
    
    # Load dev modules
    if [ -d "$SCRIPTS_DIR/dev" ] && [ "$SKIP_AI" = "false" ]; then
        if type log_debug >/dev/null 2>&1; then
            log_debug "Loading dev modules..."
        else
            _temp_log "Loading dev modules..."
        fi
        source "$SCRIPTS_DIR/dev/dev_main.sh" || {
            if type log_error >/dev/null 2>&1; then
                log_error "Failed to load dev modules"
            else
                _temp_log "ERROR: Failed to load dev modules"
            fi
            exit 1
        }
    fi
    
    # Load monitoring modules
    if [ -d "$SCRIPTS_DIR/monitoring" ]; then
        if type log_debug >/dev/null 2>&1; then
            log_debug "Loading monitoring modules..."
        else
            _temp_log "Loading monitoring modules..."
        fi
        source "$SCRIPTS_DIR/monitoring/monitoring_main.sh" || {
            if type log_error >/dev/null 2>&1; then
                log_error "Failed to load monitoring modules"
            else
                _temp_log "ERROR: Failed to load monitoring modules"
            fi
            exit 1
        }
    fi
    
    if type log_success >/dev/null 2>&1; then
        log_success "All modules loaded successfully"
    else
        _temp_log "All modules loaded successfully"
    fi
}

# ================================================================
# Parallel Installation Support
# ================================================================

run_parallel_install() {
    if [ "${ENABLE_PARALLEL:-false}" != "true" ]; then
        return 0
    fi
    
    log_info "⚡ Running parallel installations..."
    
    # Start background jobs for independent operations
    local pids=()
    
    # Install security packages in background
    if [ "$SKIP_SECURITY" = "false" ]; then
        (
            install_pkg ufw fail2ban apparmor apparmor-utils lynis chkrootkit rkhunter aide-common auditd
        ) &
        pids+=($!)
    fi
    
    # Install dev packages in background
    if [ "$SKIP_AI" = "false" ]; then
        (
            install_pkg git build-essential python3 python3-pip python3-venv docker.io docker-compose
        ) &
        pids+=($!)
    fi
    
    # Install monitoring packages in background
    (
        install_pkg netdata prometheus-node-exporter rclone openssl
    ) &
    pids+=($!)
    
    # Wait for all background jobs
    local failed=0
    for pid in "${pids[@]}"; do
        if wait "$pid"; then
            log_success "Background installation completed (PID: $pid)"
        else
            log_error "Background installation failed (PID: $pid)"
            ((failed++))
        fi
    done
    
    if [ $failed -gt 0 ]; then
        log_warn "$failed parallel installation(s) failed"
        return 1
    fi
    
    log_success "All parallel installations completed"
    return 0
}

# ================================================================
# LLM-Based Audit Suggestions (Advanced)
# ================================================================

generate_llm_audit_suggestions() {
    if [ "${DRY_RUN:-false}" = "true" ]; then
        return 0
    fi
    
    log_info "🤖 Generating LLM-based audit suggestions..."
    
    local audit_data="/tmp/brainvault_audit_data.txt"
    local suggestions_file="/opt/brainvault/llm_suggestions.txt"
    
    # Collect system information
    {
        echo "=== System Information ==="
        uname -a
        echo ""
        echo "=== Installed Packages ==="
        dpkg -l | head -50
        echo ""
        echo "=== Security Configurations ==="
        [ -f /etc/sysctl.d/99-brainvault-hardening.conf ] && \
            cat /etc/sysctl.d/99-brainvault-hardening.conf
        echo ""
        echo "=== Firewall Status ==="
        ufw status 2>/dev/null || echo "UFW not configured"
        echo ""
        echo "=== Service Status ==="
        systemctl list-units --type=service --state=running | head -20
    } > "$audit_data"
    
    # Create suggestions file with instructions for LLM analysis
    cat > "$suggestions_file" <<EOF
# BrainVault Elite - LLM Audit Suggestions

This file contains system audit data that can be analyzed by an LLM for security recommendations.

To analyze:
1. Review the audit data in: $audit_data
2. Use an LLM (GPT-4, Claude, etc.) to analyze the configuration
3. Request suggestions for:
   - Security hardening improvements
   - Performance optimizations
   - Missing security tools
   - Configuration best practices

Audit data location: $audit_data
Generated: $(date)

Note: This is a template. In a production environment, you could integrate with
OpenAI API, Anthropic API, or local LLM models for automated analysis.
EOF
    
    log_success "LLM audit template created: $suggestions_file"
    log_info "To analyze: Review $audit_data and submit to LLM for recommendations"
}

# ================================================================
# Main Execution Function
# ================================================================

main() {
    # Parse arguments first (before logging is initialized)
    parse_args "$@"
    
    # Load all modules (this initializes logging)
    load_all_modules
    
    # Check prerequisites
    check_prerequisites
    
    # Display configuration
    log_info "═══════════════════════════════════════════════════════════"
    log_info "🧠 BrainVault Elite — Starting Installation"
    log_info "═══════════════════════════════════════════════════════════"
    log_info "Configuration:"
    log_info "  DRY_RUN: $DRY_RUN"
    log_info "  SKIP_SECURITY: $SKIP_SECURITY"
    log_info "  SKIP_AI: $SKIP_AI"
    log_info "  SKIP_BACKUP: $SKIP_BACKUP"
    log_info "  DISABLE_TELEMETRY: $DISABLE_TELEMETRY"
    log_info "  ENABLE_PARALLEL: ${ENABLE_PARALLEL:-false}"
    log_info "  DEBUG: $DEBUG"
    log_info "═══════════════════════════════════════════════════════════"
    
    # Update system packages
    log_info "📦 Updating system packages..."
    run_cmd "apt-get update" "Updating package lists"
    run_cmd "apt-get -y upgrade" "Upgrading system packages"
    
    # Install base utilities
    log_info "📦 Installing base utilities..."
    install_pkg ca-certificates curl wget gnupg lsb-release \
        software-properties-common htop iotop nethogs tree pv rsync
    
    # Parallel installation if enabled
    if [ "${ENABLE_PARALLEL:-false}" = "true" ]; then
        run_parallel_install
    fi
    
    # Install security stack
    if [ "$SKIP_SECURITY" = "false" ]; then
        install_security_stack || log_warn "Security stack installation had issues"
    fi
    
    # Install dev/AI stack
    if [ "$SKIP_AI" = "false" ]; then
        install_dev_stack || log_warn "Dev/AI stack installation had issues"
    fi
    
    # Install monitoring and backup
    install_monitoring_stack || log_warn "Monitoring stack installation had issues"
    
    # Final cleanup
    log_info "🧹 Cleaning up..."
    run_cmd "apt-get autoremove -y" "Removing unused packages"
    run_cmd "apt-get clean" "Cleaning package cache"
    
    # Generate LLM audit suggestions
    generate_llm_audit_suggestions
    
    # Generate dry-run summary if in dry-run mode
    if [ "$DRY_RUN" = "true" ]; then
        generate_dry_run_summary
    fi
    
    log_success "═══════════════════════════════════════════════════════════"
    log_success "✅ BrainVault Elite installation complete!"
    log_success "═══════════════════════════════════════════════════════════"
    log_info "Log file: $LOGFILE"
    log_info "System reboot recommended for kernel changes to take effect"
    log_info "═══════════════════════════════════════════════════════════"
}

# ================================================================
# Script Execution
# ================================================================

# Run main function
main "$@"
