#!/bin/bash

set -euo pipefail

DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$DOTS_DIR/scripts/utils.sh"

cleanup() {
    echo
    print_message warning "Installation interrupted."
    exit 1
}
trap cleanup INT TERM

run_script() {
    local script="$DOTS_DIR/scripts/$1"
    if [[ ! -f "$script" ]]; then
        print_message error "Script not found: $script"
        return 1
    fi
    bash "$script"
}

main() {
    setup_logging

    echo -e "${BOLD}${BLUE}"
    echo "  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗"
    echo "  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝"
    echo "  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗"
    echo "  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║"
    echo "  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║"
    echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝"
    echo -e "${RESET}"
    print_message info "Log file: $LOG_FILE"
    echo

    echo
    print_message info "This will:"
    echo -e "  ${CYAN}1.${RESET} Install pacman packages"
    echo -e "  ${CYAN}2.${RESET} Install yay + AUR packages"
    echo -e "  ${CYAN}3.${RESET} Run post-install setup (rustup, TPM, zsh, docker)"
    echo -e "  ${CYAN}4.${RESET} Apply themes, fonts, cursors"
    echo -e "  ${CYAN}5.${RESET} Enable services"
    echo
    if ! ask "Proceed with installation?"; then
        print_message info "Aborted."
        exit 0
    fi

    # --- Run each step ---
    print_section "Step 1: Packages"
    run_script "packages.sh"

    print_section "Step 2: Post-install Setup"
    run_script "setup.sh"

    print_section "Step 3: Themes"
    run_script "themes.sh"

    print_section "Step 4: Services"
    run_script "services.sh"

    echo
    if ask "Link dotfiles config now?" "n"; then
        bash "$DOTS_DIR/link.sh" all
    else
        print_message info "Skipping config linking"
    fi

    echo
    print_message success "Installation complete!"
    print_message info "Log saved to: $LOG_FILE"
    print_message warning "Please log out and back in for group changes and shell change to take effect"
}

main "$@"
