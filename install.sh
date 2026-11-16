#!/usr/bin/env bash

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

require_arch() {
    local id="unknown"
    if [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        id="${ID:-unknown} ${ID_LIKE:-}"
    fi
    if [[ "$id" != *"arch"* ]]; then
        print_message error "This installer supports Arch Linux only (detected: $id)."
        exit 1
    fi
    local missing=()
    for cmd in pacman systemctl sudo; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        print_message error "Missing required commands: ${missing[*]}"
        exit 1
    fi
    # Prime sudo so later steps don't interleave password prompts.
    sudo -v
}

main() {
    require_user
    require_arch

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
    echo -e "  ${CYAN}1.${RESET} Install pacman packages (incl. yay + AUR packages)"
    echo -e "  ${CYAN}2.${RESET} Run post-install setup (TPM, zsh as default shell)"
    echo -e "  ${CYAN}3.${RESET} Apply themes, fonts, cursors"
    echo -e "  ${CYAN}4.${RESET} Enable services and groups"
    echo -e "  ${CYAN}5.${RESET} Link dotfiles and enable the quickshell shell"
    echo
    if ! ask "Proceed with installation?" "n"; then
        print_message info "Aborted."
        exit 0
    fi

    # --- Run each step ---
    print_section "Step 1: Packages"
    run_script "packages.sh"

    print_section "Step 2: Post-install Setup"
    run_script "setup.sh"

    print_section "Step 3: Services"
    run_script "services.sh"

    echo
    if ask "Link dotfiles config now?" "n"; then
        bash "$DOTS_DIR/link.sh" all
    else
        print_message info "Skipping config linking"
    fi

    # The quickshell unit comes from config/systemd and only exists after linking
    if ask "Enable the quickshell desktop shell service now?" "n"; then
        systemctl --user daemon-reload
        if run_cmd "Enabling user service: quickshell" systemctl --user enable --now quickshell.service; then
            print_message success "Quickshell is running"
        fi
    fi

    # Spotify theming: quickshell has now written Themes/qs-shell/color.ini on its first palette apply
    if command -v spicetify &>/dev/null; then
        echo
        if ask "Configure Spotify theming (spicetify) now?" "n"; then
            spicetify >/dev/null 2>&1 || true
            run_cmd "Pointing spicetify at the shell theme" \
                spicetify config current_theme qs-shell color_scheme qs-shell
            if ! run_cmd "Applying spicetify" spicetify backup apply; then
                run_cmd "Backup exists — reapplying" spicetify apply || true
            fi
        fi
    fi

    echo
    print_message success "Installation complete!"
    print_message info "Log saved to: $LOG_FILE"
    print_message warning "Please log out and back in for group changes and shell change to take effect"
}

main
