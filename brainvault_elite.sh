#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Modular DevSecOps + AI Bootstrap System
# Version: 2.0
# Author: MD Jahirul
# ================================================================

set -euo pipefail

# ============= Configuration =============

export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SCRIPTS_BASE="$SCRIPT_DIR/scripts"
export LOGFILE="${LOGFILE:-/var/log/brainvault_elite_$(date +%F_%H-%M-%S).log}"

# Default options
export DRY_RUN="${DRY_RUN:-false}"
export SKIP_AI="${SKIP_AI:-false}"
export SKIP_SECURITY="${SKIP_SECURITY:-false}"
export SKIP_BACKUP="${SKIP_BACKUP:-false}"
export DISABLE_TELEMETRY_BLOCK="${DISABLE_TELEMETRY_BLOCK:-false}"
export SECURE_MODE="${SECURE_MODE:-false}"
export PARALLEL_INSTALLS="${PARALLEL_INSTALLS:-false}"
export VERBOSE="${VERBOSE:-false}"
export NO_COLOR="${NO_COLOR:-false}"

# ============= Auto-Source All Modules =============

source_modules() {
    local modules_sourced=0
    local modules_failed=0
    
    echo "Loading BrainVault Elite modules..."
    
    # Find all shell scripts under /scripts
    while IFS= read -r -d '' module; do
        # Skip non-shell files
        if [[ ! "$module" =~ \.sh$ ]]; then
            continue
        fi
        
        if [[ "$VERBOSE" == "true" ]]; then
            echo "  Loading: $module"
        fi
        
        if source "$module" 2>/dev/null; then
            ((modules_sourced++))
        else
            echo "  ⚠️  Failed to load: $module"
            ((modules_failed++))
        fi
    done < <(find "$SCRIPTS_BASE" -type f -name "*.sh" -print0 2>/dev/null)
    
    echo "✓ Loaded $modules_sourced modules"
    
    if [[ $modules_failed -gt 0 ]]; then
        echo "⚠️  Failed to load $modules_failed modules"
        return 1
    fi
    
    return 0
}

# ============= CLI Argument Parser =============

show_help() {
    cat <<EOF
🧠 BrainVault Elite — Modular DevSecOps + AI Bootstrap System

USAGE:
    sudo ./brainvault_elite.sh [OPTIONS]

OPTIONS:
    --dry-run                   Simulate actions without executing
    --skip-ai                   Skip AI/development stack installation
    --skip-security             Skip security hardening
    --skip-backup               Skip backup system setup
    --secure                    Enable maximum security mode (strict hardening)
    --disable-telemetry         Block telemetry endpoints
    --parallel                  Enable parallel installations (experimental)
    --verbose                   Enable verbose logging
    --no-color                  Disable colored output
    --help, -h                  Show this help message

EXAMPLES:
    # Dry-run to see what would be installed
    sudo ./brainvault_elite.sh --dry-run

    # Skip AI stack, only harden security
    sudo ./brainvault_elite.sh --skip-ai --secure

    # Install everything with parallel mode
    sudo ./brainvault_elite.sh --parallel

    # Maximum security mode with telemetry blocking
    sudo ./brainvault_elite.sh --secure --disable-telemetry

COMPONENTS:
    ✓ Security: UFW, Fail2ban, AppArmor, kernel hardening
    ✓ AI Stack: Python, PyTorch, Transformers, Jupyter
    ✓ Containers: Docker, Docker Compose, Podman
    ✓ Monitoring: Netdata, Prometheus exporters
    ✓ Backup: Encrypted backups with rclone/restic
    ✓ Audit: Lynis, rkhunter, automated security audits

LOGS:
    Installation log: $LOGFILE
    Audit log: /var/log/brainvault-audit.log
    Backup log: /var/log/brainvault-backup.log

For more information, visit: https://github.com/md-jahirul/brainvault-elite
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                export DRY_RUN=true
                shift
                ;;
            --skip-ai)
                export SKIP_AI=true
                shift
                ;;
            --skip-security)
                export SKIP_SECURITY=true
                shift
                ;;
            --skip-backup)
                export SKIP_BACKUP=true
                shift
                ;;
            --secure)
                export SECURE_MODE=true
                shift
                ;;
            --disable-telemetry)
                export DISABLE_TELEMETRY_BLOCK=false  # false means we WILL block
                shift
                ;;
            --parallel)
                export PARALLEL_INSTALLS=true
                shift
                ;;
            --verbose)
                export VERBOSE=true
                export LOG_LEVEL=0  # DEBUG level
                shift
                ;;
            --no-color)
                export NO_COLOR=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Run with --help for usage information"
                exit 1
                ;;
        esac
    done
}

# ============= Pre-flight Checks =============

preflight_checks() {
    log_section "Pre-flight System Checks"
    
    # Check root
    check_root
    
    # Check OS
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        log_info "Operating System: $PRETTY_NAME"
        
        if [[ "$ID" != "ubuntu" ]] && [[ "$ID_LIKE" != *"ubuntu"* ]] && [[ "$ID" != "debian" ]]; then
            log_warn "This script is optimized for Ubuntu/Debian systems"
            log_warn "Some features may not work correctly on $PRETTY_NAME"
        fi
    fi
    
    # Check disk space
    local available_space
    available_space=$(df / | awk 'NR==2 {print $4}')
    local required_space=$((5 * 1024 * 1024))  # 5GB in KB
    
    if [[ $available_space -lt $required_space ]]; then
        log_warn "Low disk space: $(df -h / | awk 'NR==2 {print $4}') available"
        log_warn "Recommended: At least 5GB free space"
    else
        log_success "Disk space: $(df -h / | awk 'NR==2 {print $4}') available"
    fi
    
    # Check internet connectivity
    if ping -c 1 8.8.8.8 &>/dev/null; then
        log_success "Internet connectivity: OK"
    else
        log_error "No internet connectivity detected"
        error_exit "Internet connection required for installation"
    fi
    
    # Check if running in container
    if [[ -f /.dockerenv ]] || grep -q docker /proc/1/cgroup 2>/dev/null; then
        log_warn "Running inside a container - some features may be limited"
    fi
    
    log_success "Pre-flight checks completed"
}

# ============= Installation Phases =============

phase_core_system() {
    log_section "Phase 1: Core System Setup"
    
    if [[ "$SKIP_BACKUP" != "true" ]]; then
        create_snapshot
        backup_configs
    fi
    
    show_system_info
    update_system
    install_essential_tools
}

phase_security() {
    if [[ "$SKIP_SECURITY" == "true" ]]; then
        log_section "Security Phase: SKIPPED"
        return 0
    fi
    
    log_section "Phase 2: Security Hardening"
    
    # Firewall
    setup_firewall
    setup_rate_limiting
    
    # Intrusion detection
    setup_fail2ban
    setup_apparmor
    setup_audit_system
    
    # Kernel hardening
    setup_kernel_hardening
    setup_security_limits
    disable_unused_protocols
    
    # Integrity tools
    setup_integrity_tools
    
    # Telemetry blocking
    if [[ "$DISABLE_TELEMETRY_BLOCK" == "false" ]]; then
        setup_telemetry_block
    fi
    
    log_success "Security hardening completed"
}

phase_ai_stack() {
    if [[ "$SKIP_AI" == "true" ]]; then
        log_section "AI Stack Phase: SKIPPED"
        return 0
    fi
    
    log_section "Phase 3: AI & Development Stack"
    
    # Python stack
    install_python_dev
    install_ml_libraries
    install_ai_tools
    setup_jupyter
    
    # Container stack
    install_docker
    configure_docker_user
    configure_docker
    install_podman
    install_container_tools
    
    # GPU support check
    install_gpu_support
    
    log_success "AI & Development stack installation completed"
}

phase_backup_monitoring() {
    log_section "Phase 4: Backup & Monitoring"
    
    # Backup system
    if [[ "$SKIP_BACKUP" != "true" ]]; then
        install_backup_tools
        create_backup_script
        setup_backup_cron
        setup_restic
    fi
    
    # Monitoring
    install_netdata
    install_prometheus_exporters
    create_audit_script
    install_security_audit_tools
    setup_audit_cron
    
    log_success "Backup & Monitoring setup completed"
}

# ============= Advanced Features =============

suggest_llm_audit() {
    log_section "AI-Powered Security Suggestions"
    
    log_info "BrainVault Elite can integrate with LLMs for advanced security auditing"
    log_info ""
    log_info "Suggested integrations:"
    log_info "  • Run security audits through ChatGPT/Claude for analysis"
    log_info "  • Use local LLMs (Ollama) for privacy-first log analysis"
    log_info "  • Automated vulnerability explanations and remediation steps"
    log_info ""
    log_info "Example: Analyze audit logs with Ollama"
    log_info "  $ ollama run llama2 'Analyze this security audit: \$(cat /var/log/brainvault-audit.log)'"
    log_info ""
    log_info "Example: Generate custom firewall rules"
    log_info "  $ echo 'Generate UFW rules for a Django web app' | ollama run codellama"
    log_info ""
    
    if check_command ollama; then
        log_success "Ollama is installed and ready for LLM-based audits"
        log_info "Try: ollama run llama2"
    else
        log_info "Install Ollama for local LLM capabilities:"
        log_info "  $ curl -fsSL https://ollama.ai/install.sh | sh"
    fi
}

parallel_execution_status() {
    if [[ "$PARALLEL_INSTALLS" == "true" ]]; then
        log_info "Parallel execution mode: ENABLED (experimental)"
        log_warn "This mode can speed up installation but may cause issues"
    else
        log_info "Parallel execution mode: DISABLED (use --parallel to enable)"
    fi
}

# ============= Final Report =============

generate_final_report() {
    log_section "Installation Summary"
    
    local report_file="/opt/brainvault/installation-report.txt"
    mkdir -p "$(dirname "$report_file")"
    
    {
        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║     BrainVault Elite - Installation Report                ║"
        echo "╚════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Date: $(date)"
        echo "Hostname: $(hostname)"
        echo "Installation Log: $LOGFILE"
        echo ""
        echo "═══════════════════════════════════════════════════════════"
        echo "INSTALLED COMPONENTS"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
        
        # Core System
        echo "✓ Core System"
        echo "  - System updated and hardened"
        echo "  - Essential tools installed"
        echo ""
        
        # Security
        if [[ "$SKIP_SECURITY" != "true" ]]; then
            echo "✓ Security Stack"
            systemctl is-active --quiet ufw 2>/dev/null && echo "  - UFW Firewall: Active" || echo "  - UFW Firewall: Inactive"
            systemctl is-active --quiet fail2ban 2>/dev/null && echo "  - Fail2ban: Active" || echo "  - Fail2ban: Inactive"
            systemctl is-active --quiet apparmor 2>/dev/null && echo "  - AppArmor: Active" || echo "  - AppArmor: Inactive"
            echo "  - Kernel hardening: Applied"
            echo ""
        fi
        
        # AI Stack
        if [[ "$SKIP_AI" != "true" ]]; then
            echo "✓ AI & Development Stack"
            command -v python3 &>/dev/null && echo "  - Python: $(python3 --version 2>&1)"
            command -v docker &>/dev/null && echo "  - Docker: $(docker --version 2>&1)"
            command -v jupyter &>/dev/null && echo "  - Jupyter: Installed"
            echo ""
        fi
        
        # Monitoring
        echo "✓ Monitoring & Audit"
        systemctl is-active --quiet netdata 2>/dev/null && echo "  - Netdata: Running (http://localhost:19999)"
        [[ -f /usr/local/bin/brainvault-audit ]] && echo "  - Audit script: /usr/local/bin/brainvault-audit"
        echo ""
        
        # Backup
        if [[ "$SKIP_BACKUP" != "true" ]]; then
            echo "✓ Backup System"
            [[ -f /usr/local/bin/brainvault-backup ]] && echo "  - Backup script: /usr/local/bin/brainvault-backup"
            crontab -l 2>/dev/null | grep -q brainvault-backup && echo "  - Automated backups: Scheduled"
            echo ""
        fi
        
        echo "═══════════════════════════════════════════════════════════"
        echo "NEXT STEPS"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
        echo "1. Reboot your system to apply all changes:"
        echo "   $ sudo reboot"
        echo ""
        echo "2. Run a security audit:"
        echo "   $ sudo brainvault-audit"
        echo ""
        echo "3. Create a backup:"
        echo "   $ export BACKUP_ENCRYPTION_PASSWORD='your-password'"
        echo "   $ sudo brainvault-backup"
        echo ""
        echo "4. Access monitoring dashboard:"
        echo "   http://localhost:19999 (Netdata)"
        echo ""
        echo "5. Start Jupyter Lab (for AI development):"
        echo "   $ jupyter lab"
        echo ""
        
        echo "═══════════════════════════════════════════════════════════"
        echo "USEFUL COMMANDS"
        echo "═══════════════════════════════════════════════════════════"
        echo ""
        echo "Check firewall status:     sudo ufw status verbose"
        echo "Check security services:   sudo systemctl status fail2ban apparmor"
        echo "View system logs:          sudo journalctl -xe"
        echo "Docker status:             sudo docker ps"
        echo "Python packages:           pip list"
        echo ""
        
    } | tee "$report_file"
    
    log_success "Installation report saved: $report_file"
}

# ============= Main Execution =============

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║          🧠 BrainVault Elite v2.0                          ║"
    echo "║     DevSecOps + AI Bootstrap System                        ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Load modules first
    source_modules || error_exit "Failed to load required modules"
    
    # Parse CLI arguments
    parse_args "$@"
    
    # Show configuration
    log_section "Configuration"
    log_info "Dry Run: $DRY_RUN"
    log_info "Skip AI: $SKIP_AI"
    log_info "Skip Security: $SKIP_SECURITY"
    log_info "Skip Backup: $SKIP_BACKUP"
    log_info "Secure Mode: $SECURE_MODE"
    log_info "Disable Telemetry Block: $DISABLE_TELEMETRY_BLOCK"
    log_info "Parallel Installs: $PARALLEL_INSTALLS"
    log_info "Log File: $LOGFILE"
    
    # Pre-flight checks
    preflight_checks
    
    # Execute installation phases
    local start_time
    start_time=$(date +%s)
    
    phase_core_system
    phase_security
    phase_ai_stack
    phase_backup_monitoring
    
    # Advanced features
    suggest_llm_audit
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Print dry-run summary if applicable
    if [[ "$DRY_RUN" == "true" ]]; then
        print_dry_run_summary
    fi
    
    # Final steps
    final_steps
    
    # Generate report
    if [[ "$DRY_RUN" != "true" ]]; then
        generate_final_report
    fi
    
    log_section "Installation Complete! 🎉"
    log_success "Total time: ${duration}s ($((duration / 60))m $((duration % 60))s)"
    log_info ""
    log_info "Thank you for using BrainVault Elite!"
}

# ============= Entry Point =============

# Trap errors
trap 'log_error "Script failed at line $LINENO with exit code $?"' ERR

# Execute main function
main "$@"
