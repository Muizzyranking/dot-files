#!/usr/bin/env bash

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

die() {
    local message="${1:-Fatal error}"
    local code="${2:-1}"
    print_message error "$message"
    exit "$code"
}

warn() {
    print_message warning "$*"
}

info() {
    print_message info "$*"
}

success() {
    print_message success "$*"
}

# Respects QUIET=true for scripts with a --quiet flag.
log() {
    if [[ "${QUIET:-false}" == true ]]; then
        return 0
    fi
    print_message info "$*"
}

# Simple y/n prompt. Returns 0 on yes, 1 otherwise.
# Usage: if confirm "Overwrite it?"; then ...; fi
confirm() {
    local prompt="${1:-Are you sure?}"
    local reply
    read -r -p "$prompt (y/n): " reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

# Standard interrupt message for long/interactive scripts.
trap_interrupt() {
    trap 'echo; print_message info "Script interrupted..."' INT TERM
}

# Returns 0 if <cmd> exists in PATH, 1 otherwise.
command_exists() {
    if [ $# -eq 0 ]; then
        return 1
    fi
    command -v "$1" >/dev/null 2>&1
}

# Returns 0 if [dir] (default: .) is inside a git work tree.
is_git_repo() {
    git -C "${1:-.}" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# Fatal version of is_git_repo. Exits non-zero with a clear message.
require_git_repo() {
    if ! is_git_repo "${1:-.}"; then
        die "Not inside a git repository: ${1:-.}"
    fi
}

require() {
    local missing=()
    local cmd

    for cmd in "$@"; do
        if ! command_exists "$cmd"; then
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
