#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

setup_rustup() {
    print_section "Setting up Rust (rustup)"

    if ! has_cmd rustup; then
        print_message error "rustup not found, skipping Rust setup"
        return 1
    fi

    if has_cmd cargo; then
        print_message info "Rust toolchain already initialized"
    else
        run_cmd "Installing stable Rust toolchain" rustup toolchain install stable
        run_cmd "Setting stable as default" rustup default stable
    fi

    print_message success "Rust ready — $(rustc --version 2>/dev/null || echo 'version unknown')"
}

setup_tpm() {
    print_section "Setting up TPM (Tmux Plugin Manager)"

    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [[ -d "$tpm_dir" ]]; then
        print_message info "TPM already installed at $tpm_dir"
        return 0
    fi

    run_cmd "Cloning TPM" \
        git clone https://github.com/tmux-plugins/tpm "$tpm_dir"

    print_message success "TPM installed at $tpm_dir"
    print_message info "Press prefix + I inside tmux to install plugins"
}

setup_zsh_default() {
    print_section "Setting Zsh as default shell"

    local zsh_path
    zsh_path="$(command -v zsh 2>/dev/null || echo "")"

    if [[ -z "$zsh_path" ]]; then
        print_message warning "zsh not found, skipping shell change"
        return 0
    fi

    if [[ "$SHELL" == "$zsh_path" ]]; then
        print_message info "zsh is already the default shell"
        return 0
    fi

    # Ensure zsh is in /etc/shells
    if ! grep -qx "$zsh_path" /etc/shells; then
        run_cmd "Adding zsh to /etc/shells" \
            bash -c "echo '$zsh_path' | sudo tee -a /etc/shells"
    fi

    run_cmd "Changing default shell to zsh" chsh -s "$zsh_path"
    print_message success "Default shell changed to zsh (takes effect on next login)"
}

main() {
    setup_logging
    print_header "Post-Install Setup"

    setup_rustup
    setup_tpm
    setup_zsh_default

    print_message success "Setup complete"
}

main "$@"
