#!/bin/bash

set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTS_DIR/scripts/utils.sh"

cleanup() {
    echo
    print_message info "Script interrupted....."
    # Kill the sudo keep-alive background process if it exists
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
    exit 1
}

trap cleanup INT TERM

print_banner() {
    echo -e "${CYAN}"
    echo "=================================================="
    echo "       DOTFILES SETUP         "
    echo "=================================================="
    echo -e "${NC}"
}

check_sudo() {
    echo "This script requires sudo privileges for package installation."

    # Test if we can run sudo without password
    if sudo -n true 2>/dev/null; then
        echo "✓ Sudo access confirmed"
        return 0
    fi

    # Prompt for password once
    echo "Please enter your password to continue:"
    if sudo -v; then
        print_message info "✓ Sudo access granted"

        # Keep sudo alive in background - more aggressive refresh
        {
            while kill -0 $ 2>/dev/null; do
                sleep 30
                sudo -n true 2>/dev/null || break
            done
        } &

        SUDO_KEEPALIVE_PID=$!
        trap 'kill $SUDO_KEEPALIVE_PID 2>/dev/null || true' EXIT

        return 0
    else
        print_message error "✗ Sudo access required but not granted"
        exit 1
    fi
}

show_menu() {
    echo "Please select an option:"
    echo "1) Full Installation (System + Apps + Dev + Hypr + Themes + Link)"
    echo "2) System Setup Only (Repos, Codecs, Tweaks)"
    echo "3) Applications Only (Browsers, VSCode, Flatpaks)"
    echo "4) Development Tools Only"
    echo "5) Hyprland Environment Only"
    echo "6) Themes & Icons Only"
    echo "7) Link Dotfiles Only"
    echo "c) Clear Progress (Reset State)"
    echo "q) Quit"
    echo
    read -rp "Choice: " choice
}

run_step() {
    local script="$1"
    if [[ -f "$DOTS_DIR/scripts/$script" ]]; then
        bash "$DOTS_DIR/scripts/$script"
    elif [[ -f "$DOTS_DIR/$script" ]]; then
        bash "$DOTS_DIR/$script"
    else
        print_message error "Script $script not found!"
    fi
}

main() {
    check_fedora
    check_sudo
    print_banner

    if [[ -f "$STATE_FILE" ]]; then
        print_message warning "Existing setup progress detected."
        read -rp "Continue from where you left off? (y/n): " resume
        if [[ "$resume" =~ ^[Yy]$ ]]; then
            run_step "setup.sh"
            run_step "apps.sh"
            run_step "dev.sh"
            run_step "hypr.sh"
            run_step "themes.sh"
            bash "$DOTS_DIR/link.sh"
            print_message success "Installation resumed and completed."
            exit 0
        fi
    fi

    show_menu

    case "$choice" in
    1)
        run_step "setup.sh"
        run_step "apps.sh"
        run_step "dev.sh"
        run_step "hypr.sh"
        run_step "themes.sh"
        bash "$DOTS_DIR/link.sh"
        ;;
    2) run_step "setup.sh" ;;
    3)
        run_step "apps.sh"
        bash "$DOTS_DIR/link.sh" vscode
        ;;
    4)
        run_step "dev.sh"
        bash "$DOTS_DIR/link.sh" nvim zsh tmux lazygit bat git
        ;;
    5)
        run_step "hypr.sh"
        bash "$DOTS_DIR/link.sh" hypr waybar rofi swaync wlogout kitty
        ;;
    6) run_step "themes.sh" ;;
    7) bash "$DOTS_DIR/link.sh" ;;
    c)
        clear_state
        print_message success "Progress state cleared."
        ;;
    q) exit 0 ;;
    *) print_message error "Invalid choice." ;;
    esac

    print_message success "Operation completed."
}

main "$@"

