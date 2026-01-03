#!/usr/bin/env bash

validate_syntax() {
    local target_root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
    local -a files
    local failed=0

    if [[ ! -d "$target_root" ]]; then
        __bve_vs_log error "Target root not found: $target_root"
        return 1
    fi

    mapfile -t files < <(find "$target_root" -type f -name '*.sh' | sort)
    __bve_vs_log info "Validating bash syntax for ${#files[@]} files"

    local file
    for file in "${files[@]}"; do
        if bash -n "$file"; then
            __bve_vs_log success "Syntax OK :: $file"
        else
            __bve_vs_log error "Syntax error :: $file"
            failed=1
        fi
    done

    if (( failed )); then
        __bve_vs_log error "Syntax validation encountered errors"
        return 1
    fi

    __bve_vs_log success "All scripts passed bash -n validation"
}

__bve_vs_log() {
    local level="$1"; shift
    local message="$*"

    case "$level" in
        success)
            if command -v log_success >/dev/null 2>&1; then
                log_success "$message"
            else
                printf '[SUCCESS] %s\n' "$message"
            fi
            ;;
        error)
            if command -v log_error >/dev/null 2>&1; then
                log_error "$message"
            else
                printf '[ERROR] %s\n' "$message" >&2
            fi
            ;;
        info)
            if command -v log_info >/dev/null 2>&1; then
                log_info "$message"
            else
                printf '[INFO] %s\n' "$message"
            fi
            ;;
        *)
            printf '%s\n' "$message"
            ;;
    esac
}

export -f validate_syntax

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    # shellcheck source=/dev/null
    source "$(cd "$(dirname "${BASH_SOURCE[0]}")/utils" && pwd)/logging.sh" 2>/dev/null || true
    validate_syntax "$@"
fi
