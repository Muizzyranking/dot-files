#!/bin/env bash

print_message() {
    local type="info"
    local message=""

    if [ $# -eq 1 ]; then
        message="$1"
    elif [ $# -ge 2 ]; then
        type="$1"
        message="$2"
    else
        echo "Usage: print_message [type] <message>"
        exit 1
    fi

    case "$type" in
    error) echo -e "\033[0;31mError: $message\033[0m" ;;
    success) echo -e "\033[0;32mSuccess: $message\033[0m" ;;
    warning) echo -e "\033[0;33mWarning: $message\033[0m" ;;
    info) echo -e "\033[0;34m$message\033[0m" ;;
    *) echo -e "$message" ;;
    esac
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
        print_message warning "❌ Missing required dependencies:" >&2
        printf "   - %s\n" "${missing[@]}" >&2
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
