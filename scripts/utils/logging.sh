#!/bin/bash
# ================================================================
# BrainVault Elite - Enhanced Logging Utilities
# Provides color-coded logging, error handling, and dry-run support
# ================================================================

# Color codes for enhanced output
readonly COLOR_RESET='\033[0m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_MAGENTA='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_BOLD='\033[1m'

# Log levels
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARN=2
readonly LOG_ERROR=3
readonly LOG_SUCCESS=4

# Global configuration
LOGFILE="${LOGFILE:-/var/log/brainvault_elite_$(date +%F_%H-%M-%S).log}"
LOG_LEVEL="${LOG_LEVEL:-$LOG_INFO}"
DRY_RUN="${DRY_RUN:-false}"
NO_COLOR="${NO_COLOR:-false}"

# Ensure log directory exists
mkdir -p "$(dirname "$LOGFILE")" 2>/dev/null || true

# ============= Core Logging Functions =============

log_raw() {
    local message="$1"
    local color="${2:-}"
    local timestamp
    timestamp="$(date '+%F %T')"
    
    if [[ "$NO_COLOR" == "true" ]] || [[ ! -t 1 ]]; then
        echo "[ $timestamp ] $message" | tee -a "$LOGFILE"
    else
        echo -e "${color}[ $timestamp ] $message${COLOR_RESET}" | tee -a "$LOGFILE"
    fi
}

log() {
    log_raw "$*" "$COLOR_CYAN"
}

log_info() {
    [[ $LOG_LEVEL -le $LOG_INFO ]] && log_raw "ℹ️  INFO: $*" "$COLOR_BLUE"
}

log_success() {
    [[ $LOG_LEVEL -le $LOG_SUCCESS ]] && log_raw "✅ SUCCESS: $*" "$COLOR_GREEN"
}

log_warn() {
    [[ $LOG_LEVEL -le $LOG_WARN ]] && log_raw "⚠️  WARNING: $*" "$COLOR_YELLOW"
}

log_error() {
    log_raw "❌ ERROR: $*" "$COLOR_RED" >&2
}

log_debug() {
    [[ $LOG_LEVEL -le $LOG_DEBUG ]] && log_raw "🔍 DEBUG: $*" "$COLOR_MAGENTA"
}

log_section() {
    local section="$1"
    log_raw "" ""
    log_raw "════════════════════════════════════════════════" "$COLOR_BOLD$COLOR_CYAN"
    log_raw "  $section" "$COLOR_BOLD$COLOR_CYAN"
    log_raw "════════════════════════════════════════════════" "$COLOR_BOLD$COLOR_CYAN"
    log_raw "" ""
}

# ============= Error Handling Functions =============

error_exit() {
    local message="$1"
    local exit_code="${2:-1}"
    log_error "$message"
    log_error "Exiting with code $exit_code"
    exit "$exit_code"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root (use sudo)" 10
    fi
}

check_command() {
    local cmd="$1"
    local package="${2:-$1}"
    
    if ! command -v "$cmd" &>/dev/null; then
        log_warn "Command '$cmd' not found. Please install package: $package"
        return 1
    fi
    return 0
}

validate_path() {
    local path="$1"
    local type="${2:-file}" # file or directory
    
    if [[ "$type" == "directory" ]]; then
        if [[ ! -d "$path" ]]; then
            log_error "Directory not found: $path"
            return 1
        fi
    else
        if [[ ! -f "$path" ]]; then
            log_error "File not found: $path"
            return 1
        fi
    fi
    return 0
}

# ============= Command Execution Functions =============

run_cmd() {
    local cmd="$1"
    local desc="${2:-Executing command}"
    local exit_on_fail="${3:-true}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_raw "🔸 [DRY-RUN] $desc" "$COLOR_YELLOW"
        log_raw "   └─ Command: $cmd" "$COLOR_YELLOW"
        return 0
    fi
    
    log_info "$desc"
    log_debug "Executing: $cmd"
    
    local start_time
    start_time=$(date +%s)
    
    if eval "$cmd" >>"$LOGFILE" 2>&1; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_success "$desc completed in ${duration}s"
        return 0
    else
        local exit_code=$?
        log_error "$desc failed with exit code $exit_code"
        log_error "Command was: $cmd"
        
        if [[ "$exit_on_fail" == "true" ]]; then
            error_exit "Command execution failed" "$exit_code"
        fi
        return "$exit_code"
    fi
}

run_cmd_silent() {
    local cmd="$1"
    eval "$cmd" &>/dev/null
}

# ============= Package Management =============

install_pkg() {
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "No packages specified for installation"
        return 0
    fi
    
    log_info "Installing packages: ${packages[*]}"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_raw "🔸 [DRY-RUN] Would install: ${packages[*]}" "$COLOR_YELLOW"
        return 0
    fi
    
    # Check if apt is available
    if ! check_command apt-get; then
        log_error "apt-get not found. This script requires Debian/Ubuntu"
        return 1
    fi
    
    # Update package lists if needed (only once per session)
    if [[ ! -f /tmp/brainvault_apt_updated ]]; then
        log_info "Updating package lists..."
        apt-get update >>"$LOGFILE" 2>&1 || {
            log_warn "apt-get update failed, continuing anyway..."
        }
        touch /tmp/brainvault_apt_updated
    fi
    
    # Install packages
    local failed_packages=()
    for pkg in "${packages[@]}"; do
        log_info "Installing package: $pkg"
        if DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$pkg" >>"$LOGFILE" 2>&1; then
            log_success "Package installed: $pkg"
        else
            log_error "Failed to install package: $pkg"
            failed_packages+=("$pkg")
        fi
    done
    
    if [[ ${#failed_packages[@]} -gt 0 ]]; then
        log_error "Failed to install packages: ${failed_packages[*]}"
        return 1
    fi
    
    return 0
}

# ============= Progress Tracking =============

show_progress() {
    local current="$1"
    local total="$2"
    local task="${3:-Processing}"
    local percent=$((current * 100 / total))
    
    log_info "$task: [$current/$total] ${percent}%"
}

# ============= Dry-Run Summary =============

declare -a DRY_RUN_SUMMARY=()

add_to_summary() {
    local category="$1"
    local action="$2"
    DRY_RUN_SUMMARY+=("$category|$action")
}

print_dry_run_summary() {
    if [[ "$DRY_RUN" != "true" ]]; then
        return
    fi
    
    log_section "DRY-RUN SUMMARY"
    
    local categories=()
    local current_category=""
    
    # Sort and organize by category
    printf '%s\n' "${DRY_RUN_SUMMARY[@]}" | sort | while IFS='|' read -r category action; do
        if [[ "$category" != "$current_category" ]]; then
            log_raw "" ""
            log_raw "📦 $category:" "$COLOR_BOLD$COLOR_CYAN"
            current_category="$category"
        fi
        log_raw "   • $action" "$COLOR_YELLOW"
    done
    
    log_raw "" ""
    log_info "Total actions planned: ${#DRY_RUN_SUMMARY[@]}"
    log_raw "" ""
}

# Export functions for use in other scripts
export -f log log_info log_success log_warn log_error log_debug log_section
export -f log_raw error_exit check_root check_command validate_path
export -f run_cmd run_cmd_silent install_pkg show_progress
export -f add_to_summary print_dry_run_summary
