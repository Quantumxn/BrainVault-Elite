#!/bin/bash
# error_handling.sh - Robust error handling for BrainVault Elite

# Error counter
ERROR_COUNT=0
WARNING_COUNT=0

# Initialize error log
ERROR_LOG="/var/log/brainvault_errors.log"

# Ensure log directory exists
ensure_log_dir() {
    sudo mkdir -p "$(dirname "$ERROR_LOG")" 2>/dev/null || true
    sudo touch "$ERROR_LOG" 2>/dev/null || ERROR_LOG="/tmp/brainvault_errors.log"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        return 1
    fi
    return 0
}

# Check dependencies
check_dependency() {
    local cmd=$1
    local package=${2:-$1}
    
    if ! command_exists "$cmd"; then
        log_warn "Dependency missing: $cmd (package: $package)"
        return 1
    fi
    log_debug "Dependency found: $cmd"
    return 0
}

# Install missing dependency
install_dependency() {
    local package=$1
    log_info "Installing dependency: $package"
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would install: $package"
        return 0
    fi
    
    if command_exists apt-get; then
        sudo apt-get update -qq
        sudo apt-get install -y "$package" || {
            log_error "Failed to install $package"
            return 1
        }
    else
        log_error "Package manager not supported"
        return 1
    fi
    
    log_success "Installed: $package"
    return 0
}

# Safe command execution with error handling
safe_exec() {
    local description=$1
    shift
    
    log_step "$description"
    
    if [[ "${DRY_RUN:-0}" == "1" ]]; then
        log_info "[DRY-RUN] Would execute: $*"
        return 0
    fi
    
    local output
    local exit_code
    
    output=$("$@" 2>&1)
    exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        log_debug "Command succeeded: $*"
        [[ -n "$output" ]] && log_debug "Output: $output"
        return 0
    else
        log_error "Command failed (exit code: $exit_code): $*"
        [[ -n "$output" ]] && log_error "Output: $output"
        echo "$(date '+%Y-%m-%d %H:%M:%S') - FAILED: $* | Exit: $exit_code | Output: $output" >> "$ERROR_LOG"
        ((ERROR_COUNT++))
        return $exit_code
    fi
}

# Trap errors
trap_error() {
    local line=$1
    local command=$2
    log_error "Error occurred in command '$command' at line $line"
    ((ERROR_COUNT++))
}

# Setup error trap
setup_error_trap() {
    set -E
    trap 'trap_error ${LINENO} "$BASH_COMMAND"' ERR
}

# Cleanup function
cleanup() {
    if [[ $ERROR_COUNT -gt 0 ]]; then
        log_warn "Script completed with $ERROR_COUNT error(s) and $WARNING_COUNT warning(s)"
        log_info "Check error log: $ERROR_LOG"
    else
        log_success "Script completed successfully with $WARNING_COUNT warning(s)"
    fi
}

# Check system requirements
check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot determine OS version"
        return 1
    fi
    
    source /etc/os-release
    log_debug "OS: $NAME $VERSION"
    
    # Check if Ubuntu/Debian
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        log_warn "This script is designed for Ubuntu/Debian. Your OS: $ID"
    fi
    
    # Check disk space (need at least 5GB)
    local free_space=$(df / | tail -1 | awk '{print $4}')
    if [[ $free_space -lt 5242880 ]]; then
        log_warn "Low disk space: $(($free_space / 1024 / 1024))GB available"
    fi
    
    # Check memory (need at least 2GB)
    local free_mem=$(free -m | awk 'NR==2{print $7}')
    if [[ $free_mem -lt 2048 ]]; then
        log_warn "Low memory: ${free_mem}MB available"
    fi
    
    log_success "System requirements check completed"
    return 0
}

# Export functions
export -f command_exists
export -f check_root
export -f check_dependency
export -f install_dependency
export -f safe_exec
export -f trap_error
export -f setup_error_trap
export -f cleanup
export -f check_system_requirements
export -f ensure_log_dir

# Initialize
ensure_log_dir
