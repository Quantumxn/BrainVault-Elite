#!/bin/bash
# Error handling utility for BrainVault Elite

# Source logging if available
[[ -f "${BASH_SOURCE%/*}/logging.sh" ]] && source "${BASH_SOURCE%/*}/logging.sh"

# Error handling flags
set -euo pipefail

# Trap errors
trap 'error_exit $? $LINENO' ERR

error_exit() {
    local exit_code=$1
    local line_no=$2
    log_error "Error occurred at line $line_no (exit code: $exit_code)"
    exit "${exit_code}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if package is installed
package_installed() {
    dpkg -l | grep -q "^ii.*$1 " || return 1
}

# Check if service is running
service_running() {
    systemctl is-active --quiet "$1" || return 1
}

# Check if file exists
file_exists() {
    [[ -f "$1" ]] || return 1
}

# Check if directory exists
dir_exists() {
    [[ -d "$1" ]] || return 1
}

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Check dependencies
check_dependencies() {
    local missing_deps=()
    for dep in "$@"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Installing missing dependencies..."
        return 1
    fi
    return 0
}

# Safe execution with error handling
safe_exec() {
    local cmd="$1"
    local description="${2:-Executing command}"
    
    log_step "$description"
    if eval "$cmd"; then
        log_success "$description completed"
        return 0
    else
        log_error "$description failed"
        return 1
    fi
}
