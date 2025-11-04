#!/bin/bash
# ================================================================
# 🧠 BrainVault Elite — Logging & Error Handling Utilities
# ================================================================

# Color definitions
readonly COLOR_RESET='\033[0m'
readonly COLOR_BOLD='\033[1m'
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_MAGENTA='\033[0;35m'
readonly COLOR_CYAN='\033[0;36m'
readonly COLOR_WHITE='\033[0;37m'

# Log levels
readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3

# Initialize logging
init_logging() {
    if [ -z "${LOGFILE:-}" ]; then
        LOGFILE="/var/log/brainvault_elite_$(date +%F_%H-%M-%S).log"
    fi
    mkdir -p "$(dirname "$LOGFILE")"
    touch "$LOGFILE"
}

# Enhanced logging function with colors
log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    local timestamp
    timestamp=$(date '+%F %T')
    
    case "${level^^}" in
        DEBUG)
            echo -e "${COLOR_CYAN}[$timestamp] [DEBUG]${COLOR_RESET} $message" | tee -a "$LOGFILE"
            ;;
        INFO)
            echo -e "${COLOR_GREEN}[$timestamp] [INFO]${COLOR_RESET} $message" | tee -a "$LOGFILE"
            ;;
        WARN)
            echo -e "${COLOR_YELLOW}[$timestamp] [WARN]${COLOR_RESET} $message" | tee -a "$LOGFILE"
            ;;
        ERROR)
            echo -e "${COLOR_RED}[$timestamp] [ERROR]${COLOR_RESET} $message" | tee -a "$LOGFILE"
            ;;
        SUCCESS)
            echo -e "${COLOR_GREEN}${COLOR_BOLD}[$timestamp] [SUCCESS]${COLOR_RESET} $message" | tee -a "$LOGFILE"
            ;;
        *)
            echo -e "[$timestamp] $message" | tee -a "$LOGFILE"
            ;;
    esac
}

# Log with emoji for visual distinction
log_info() {
    log "INFO" "ℹ️  $*"
}

log_success() {
    log "SUCCESS" "✅ $*"
}

log_warn() {
    log "WARN" "⚠️  $*"
}

log_error() {
    log "ERROR" "❌ $*"
}

log_debug() {
    if [ "${DEBUG:-false}" = "true" ]; then
        log "DEBUG" "🔍 $*"
    fi
}

# Run command with error handling and logging
run_cmd() {
    local cmd="$1"
    local desc="${2:-Running command}"
    local on_error="${3:-}"
    local exit_on_error="${4:-true}"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "(DRY-RUN) $desc → $cmd"
        return 0
    fi
    
    log_info "$desc"
    log_debug "Executing: $cmd"
    
    if eval "$cmd" >>"$LOGFILE" 2>&1; then
        log_success "Completed: $desc"
        return 0
    else
        local exit_code=$?
        log_error "Failed: $desc (exit code: $exit_code)"
        
        if [ -n "$on_error" ]; then
            log_warn "Running error handler: $on_error"
            eval "$on_error"
        fi
        
        if [ "$exit_on_error" = "true" ]; then
            log_error "Aborting due to error"
            exit "$exit_code"
        fi
        
        return "$exit_code"
    fi
}

# Install packages with error handling
install_pkg() {
    local packages="$*"
    local desc="Installing packages: $packages"
    
    if [ "${DRY_RUN:-false}" = "true" ]; then
        log_info "(DRY-RUN) $desc"
        return 0
    fi
    
    log_info "$desc"
    
    if ! apt-get install -y $packages >>"$LOGFILE" 2>&1; then
        log_error "Failed to install packages: $packages"
        return 1
    fi
    
    log_success "Installed packages: $packages"
    return 0
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verify module is loaded
verify_module() {
    local module_name="$1"
    if [ -z "${MODULE_LOADED_${module_name}:-}" ]; then
        log_error "Module $module_name not properly loaded"
        return 1
    fi
    return 0
}

# Mark module as loaded
mark_module_loaded() {
    local module_name="$1"
    export "MODULE_LOADED_${module_name}=true"
}
