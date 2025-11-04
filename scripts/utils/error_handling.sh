#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Error Handling & Recovery Utilities
# ================================================================

# Error trap handler
set_error_trap() {
    trap 'error_handler $? $LINENO "$BASH_COMMAND"' ERR
}

# Error handler function
error_handler() {
    local exit_code=$1
    local line_no=$2
    local command="$3"
    
    log_error "Error occurred at line $line_no: $command (exit code: $exit_code)"
    
    if [ "${DRY_RUN:-false}" != "true" ]; then
        log_error "Stack trace:"
        local frame=0
        while caller $frame; do
            ((frame++))
        done | while read -r line func file; do
            log_error "  at $file:$line in $func"
        done
    fi
    
    # If not in dry-run mode and critical error, exit
    if [ "${EXIT_ON_ERROR:-true}" = "true" ] && [ "${DRY_RUN:-false}" != "true" ]; then
        exit "$exit_code"
    fi
}

# Enable strict error handling
enable_strict_mode() {
    set -euo pipefail
    set_error_trap
}

# Disable strict mode (for functions that need to handle errors manually)
disable_strict_mode() {
    set +euo pipefail
    trap - ERR
}

# Restore strict mode
restore_strict_mode() {
    enable_strict_mode
}

# Retry function with exponential backoff
retry_with_backoff() {
    local max_attempts="${1:-3}"
    local delay="${2:-1}"
    local command="${3:-}"
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_debug "Attempt $attempt/$max_attempts: $command"
        
        if eval "$command" >>"$LOGFILE" 2>&1; then
            log_success "Command succeeded on attempt $attempt"
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            log_warn "Command failed, retrying in ${delay}s..."
            sleep "$delay"
            delay=$((delay * 2))  # Exponential backoff
        fi
        
        ((attempt++))
    done
    
    log_error "Command failed after $max_attempts attempts"
    return 1
}

# Validate prerequisites
check_prerequisites() {
    local missing=()
    
    # Check if running as root or with sudo
    if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
        log_error "This script requires root privileges"
        exit 1
    fi
    
    # Check required commands
    local required_commands=("apt-get" "systemctl" "bash")
    for cmd in "${required_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing+=("$cmd")
        fi
    done
    
    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing[*]}"
        exit 1
    fi
    
    log_success "All prerequisites met"
    return 0
}

# Rollback function placeholder
rollback_changes() {
    log_warn "Rolling back changes..."
    # Implementation would depend on what needs to be rolled back
    # This could restore backups, remove installed packages, etc.
}
