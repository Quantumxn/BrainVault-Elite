#!/bin/bash
# logging.sh - Color-coded logging utility for BrainVault Elite

# Color codes
COLOR_RESET='\033[0m'
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_CYAN='\033[0;36m'
COLOR_MAGENTA='\033[0;35m'
COLOR_GRAY='\033[0;90m'

# Logging functions
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_success() {
    echo -e "${COLOR_GREEN}[SUCCESS]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') - $*"
}

log_error() {
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') - $*" >&2
}

log_debug() {
    if [[ "${DEBUG_MODE:-0}" == "1" ]]; then
        echo -e "${COLOR_GRAY}[DEBUG]${COLOR_RESET} $(date '+%Y-%m-%d %H:%M:%S') - $*"
    fi
}

log_section() {
    echo ""
    echo -e "${COLOR_CYAN}╔════════════════════════════════════════════════════════════════╗${COLOR_RESET}"
    echo -e "${COLOR_CYAN}║${COLOR_RESET} $*"
    echo -e "${COLOR_CYAN}╚════════════════════════════════════════════════════════════════╝${COLOR_RESET}"
    echo ""
}

log_step() {
    echo -e "${COLOR_MAGENTA}➤${COLOR_RESET} $*"
}

# Progress indicator
show_progress() {
    local duration=$1
    local message=$2
    echo -n "$message "
    for ((i=0; i<duration; i++)); do
        echo -n "."
        sleep 1
    done
    echo " Done!"
}

# Export functions
export -f log_info
export -f log_success
export -f log_warn
export -f log_error
export -f log_debug
export -f log_section
export -f log_step
export -f show_progress
