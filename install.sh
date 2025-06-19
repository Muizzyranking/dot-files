#!/bin/bash

set -euo pipefail

SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="Fedora Dotfiles Installer"

cleanup() {
    echo
    print_message info "Script interrupted....."
    exit 1
}

# Set up trap for cleanup
trap cleanup INT TERM

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

print_banner() {
    echo "================================================"
    echo "  Automated Fedora development environment setup"
    echo "================================================"
    echo
}

show_usage() {
    /usr/bin/cat <<EOF
Usage: $0 [OPTIONS] [GROUPS...]

GROUPS:
    all         Install everything (dev + hypr + apps)
    dev         Development tools (git, neovim, vscode, etc.)
    hypr        Hyprland and Wayland ecosystem
    apps        Applications (browsers, themes, cursors)
    minimal     Basic development setup only

OPTIONS:
    -h, --help     Show this help message
    -v, --version  Show version information

EXAMPLES:
    $0 all                    # Install everything
    $0 dev apps              # Install dev tools and applications

EOF
}

check_dependencies() {
    dots_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    if [[ ! -f "$dots_dir/scripts/utils.sh" ]]; then
        echo "Utility script not found at $dots_dir/scripts/utils.sh"
        exit 1
    fi

    # Source utils.sh
    source "$dots_dir/scripts/utils.sh"
}

install() {
    for group in "$@"; do
        case $group in
        all)
            print_message info "Installing all components..."
            bash "$dots_dir/scripts/dev.sh"
            bash "$dots_dir/scripts/hypr.sh"
            bash "$dots_dir/scripts/apps.sh"
            if [[ -f "$dots_dir/link.sh" ]]; then
                bash "$dots_dir/link.sh" all
            fi
            break
            ;;
        dev)
            print_message info "Installing development tools..."
            bash "$dots_dir/scripts/dev.sh"
            if [[ -f "$dots_dir/link.sh" ]]; then
                bash "$dots_dir/link.sh" kitty nvim bat lazygit zsh tmux
            fi
            ;;
        hypr)
            print_message info "Installing Hyprland environment..."
            bash "$dots_dir/scripts/hypr.sh"
            if [[ -f "$dots_dir/link.sh" ]]; then
                bash "$dots_dir/link.sh" hypr Kvantum fastfetch rofi swaync waybar wlogout zsh
            fi
            ;;
        apps)
            print_message info "Installing applications..."
            bash "$dots_dir/scripts/apps.sh"
            ;;
        *)
            print_message error "Unknown group: $group"
            ;;
        esac
    done
}

main() {
    check_dependencies
    GRPS=()

    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            echo "help"
            show_usage
            exit 0
            ;;
        -v | --version)
            echo "$SCRIPT_NAME v$SCRIPT_VERSION"
            exit 0
            ;;
        all | dev | hypr | apps | minimal)
            GRPS+=("$1")
            shift
            ;;
        *)
            print_message error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        esac
    done

    if [[ ${#GRPS[@]} -eq 0 ]]; then
        print_message error "No installation groups specified."
        show_usage
        exit 1
    fi

    print_banner
    check_sudo

    print_message info "Starting installation process..."
    bash "$dots_dir/scripts/setup.sh"
    install "${GRPS[@]}"
    print_message success "Installation completed successfully!"
}

main "$@"
