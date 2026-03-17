#!/bin/bash

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# --- Log setup ---
LOG_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles"
LOG_FILE="$LOG_DIR/install-$(date +"%Y%m%d_%H%M%S").log"

setup_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    print_message info "Logging to: $LOG_FILE"
}

# --- Print + log ---
print_message() {
    local level="$1"
    local msg="$2"
    local timestamp
    timestamp="$(date +"%Y-%m-%d %H:%M:%S")"
    local color=""
    local prefix=""

    case "$level" in
    info)
        color="$CYAN"
        prefix="[INFO]"
        ;;
    success)
        color="$GREEN"
        prefix="[OK]"
        ;;
    warning)
        color="$YELLOW"
        prefix="[WARN]"
        ;;
    error)
        color="$RED"
        prefix="[ERROR]"
        ;;
    header)
        color="$BOLD$BLUE"
        prefix="[====]"
        ;;
    *)
        color="$RESET"
        prefix="[LOG]"
        ;;
    esac

    local console_line="${color}${prefix}${RESET} ${msg}"
    local log_line="${timestamp} ${prefix} ${msg}"

    echo -e "$console_line"
    if [[ -n "${LOG_FILE:-}" ]]; then
        echo "$log_line" >>"$LOG_FILE"
    fi
}

print_header() {
    local msg="$1"
    echo
    print_message header "========================================"
    print_message header "  $msg"
    print_message header "========================================"
    echo
}

# Ask a yes/no question, returns 0 for yes, 1 for no
ask() {
    local question="$1"
    local default="${2:-y}" # default to yes
    local prompt

    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi

    while true; do
        echo -ne "${BOLD}${CYAN}?${RESET} ${question} ${prompt} "
        read -r answer
        answer="${answer:-$default}"
        case "${answer,,}" in
        y | yes) return 0 ;;
        n | no) return 1 ;;
        *) echo -e "${YELLOW}Please answer y or n${RESET}" ;;
        esac
    done
}

# Run a command, log it, and handle errors
run_cmd() {
    local description="$1"
    shift
    print_message info "$description"
    if "$@" >>"$LOG_FILE" 2>&1; then
        print_message success "$description — done"
        return 0
    else
        print_message error "$description — failed (see $LOG_FILE)"
        return 1
    fi
}

# Check if a command exists
has_cmd() {
    command -v "$1" &>/dev/null
}

# Check if a package is installed via pacman
pacman_has() {
    pacman -Qi "$1" &>/dev/null
}

# Check if a package is installed via yay (includes AUR)
yay_has() {
    yay -Qi "$1" &>/dev/null
}
