#!/bin/env bash

print_message() {
    local type="info"
    local message=""
    local prefix=""
    local code=""
    local fd=1
    local line

    if [ $# -eq 1 ]; then
        message="$1"
    elif [ $# -ge 2 ]; then
        type="$1"
        message="$2"
    else
        echo "Usage: print_message [type] <message>" >&2
        return 1
    fi

    case "$type" in
    error)   code='0;31'; prefix="Error: ";   fd=2 ;;
    success) code='0;32'; prefix="Success: " ;;
    warning) code='0;33'; prefix="Warning: "; fd=2 ;;
    info)    code='0;34' ;;
    *)       ;;
    esac

    if [[ -n "$code" && -z "${NO_COLOR:-}" && -t $fd ]]; then
        line="$(printf '\033[%sm%s%s\033[0m' "$code" "$prefix" "$message")"
    else
        line="${prefix}${message}"
    fi

    if [[ $fd -eq 2 ]]; then
        printf '%s\n' "$line" >&2
    else
        printf '%s\n' "$line"
    fi
}

require() {
    local missing=()
    local cmd

    for cmd in "$@"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        print_message error "Missing required dependencies:"
        printf '   - %s\n' "${missing[@]}" >&2
        echo "" >&2
        print_message info "Please install the missing dependencies and try again." >&2
        return 1
    fi

    return 0
}

require_or_exit() {
    if ! require "$@"; then
        exit 1
    fi
}
