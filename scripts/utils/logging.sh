#!/usr/bin/env bash

# shellcheck disable=SC2034

__bve_logging_init_colors() {
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        local ncolors
        ncolors=$(tput colors 2>/dev/null || echo 0)
        if [[ ${ncolors} -ge 8 ]]; then
            COLOR_INFO="\033[1;34m"
            COLOR_WARN="\033[1;33m"
            COLOR_ERROR="\033[1;31m"
            COLOR_SUCCESS="\033[1;32m"
            COLOR_DEBUG="\033[1;36m"
            COLOR_RESET="\033[0m"
            return
        fi
    fi

    COLOR_INFO=""
    COLOR_WARN=""
    COLOR_ERROR=""
    COLOR_SUCCESS=""
    COLOR_DEBUG=""
    COLOR_RESET=""
}

__bve_logging_init_colors

: "${LOG_LEVEL:=INFO}"

__bve_log_level_to_int() {
    case "${1^^}" in
        ERROR) echo 0 ;;
        WARN) echo 1 ;;
        INFO) echo 2 ;;
        SUCCESS) echo 2 ;;
        DEBUG) echo 3 ;;
        *) echo 2 ;;
    esac
}

__bve_should_log() {
    local level_int current_int
    level_int=$(__bve_log_level_to_int "$1")
    current_int=$(__bve_log_level_to_int "$LOG_LEVEL")
    [[ $level_int -le $current_int ]]
}

set_log_level() {
    local level="${1:-INFO}"
    LOG_LEVEL="${level^^}"
}

__bve_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

__bve_log() {
    local level="$1"; shift
    local color="$1"; shift
    local message="$*"

    if __bve_should_log "$level"; then
        printf '%b[%s] %-7s%b %s\n' "${color}" "$(__bve_timestamp)" "${level^^}" "${COLOR_RESET}" "$message"
    fi
}

log_info()    { __bve_log INFO    "${COLOR_INFO}"    "$*"; }
log_warn()    { __bve_log WARN    "${COLOR_WARN}"    "$*"; }
log_error()   { __bve_log ERROR   "${COLOR_ERROR}"   "$*"; }
log_success() { __bve_log SUCCESS "${COLOR_SUCCESS}" "$*"; }
log_debug()   { __bve_log DEBUG   "${COLOR_DEBUG}"   "$*"; }

log_section() {
    local title="$1"
    log_info "===== ${title} ====="
}

export -f set_log_level log_info log_warn log_error log_success log_debug log_section
