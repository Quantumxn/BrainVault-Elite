#!/usr/bin/env bash

__BVE_ERROR_CONTEXT_STACK=()

__bve_current_error_context() {
    local len=${#__BVE_ERROR_CONTEXT_STACK[@]}
    if (( len > 0 )); then
        echo "${__BVE_ERROR_CONTEXT_STACK[$((len-1))]}"
    else
        echo "GLOBAL"
    fi
}

__bve_trap_handler() {
    local exit_code=$1
    local failed_command=$2
    local context
    context=$(__bve_current_error_context)
    if command -v log_error >/dev/null 2>&1; then
        log_error "[$context] Command failed (exit: ${exit_code}): ${failed_command}"
    else
        printf '[%s] ERROR: Command failed (exit: %s): %s\n' "$context" "$exit_code" "$failed_command" 1>&2
    fi
    return "$exit_code"
}

register_error_handler() {
    local context="${1:-GLOBAL}"
    __BVE_ERROR_CONTEXT_STACK+=("$context")
    trap '__bve_trap_handler $? "${BASH_COMMAND}"' ERR
    set -o errtrace
}

clear_error_handler() {
    local len=${#__BVE_ERROR_CONTEXT_STACK[@]}
    if (( len > 0 )); then
        unset "__BVE_ERROR_CONTEXT_STACK[$((len-1))]"
        __BVE_ERROR_CONTEXT_STACK=(${__BVE_ERROR_CONTEXT_STACK[@]-})
    fi
    if (( ${#__BVE_ERROR_CONTEXT_STACK[@]} == 0 )); then
        trap - ERR
    fi
}

ensure_dependencies() {
    local context="${1:-DEPENDENCY}"
    shift || true
    local missing=()
    local dependency

    for dependency in "$@"; do
        if ! command -v "$dependency" >/dev/null 2>&1; then
            missing+=("$dependency")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        log_error "[$context] Missing dependencies: ${missing[*]}"
        return 1
    fi

    log_debug "[$context] Dependencies satisfied: ${*:-none}"
}

with_retries() {
    local retries=${1:-3}
    local delay=${2:-2}
    shift 2

    local attempt=1
    local exit_code

    while (( attempt <= retries )); do
        "$@"
        exit_code=$?
        if (( exit_code == 0 )); then
            return 0
        fi
        log_warn "Retry ${attempt}/${retries} failed for command: $*"
        ((attempt++))
        sleep "$delay"
    done

    return "$exit_code"
}

export -f register_error_handler clear_error_handler ensure_dependencies with_retries
