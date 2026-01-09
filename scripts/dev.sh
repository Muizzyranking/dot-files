#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

print_message step "Setting up Development Environment"

if ! is_step_complete "dev_packages"; then
    print_message info "Installing development packages and CLI tools..."

    core_pkgs=(
        "git" "gcc" "gcc-c++" "make" "cmake" "python3" "python3-pip"
        "nodejs" "nodejs-npm" "golang" "rust" "cargo"
    )

    cli_tools=(
        "neovim" "zsh" "tmux" "ripgrep" "fd-find" "fzf"
        "tldr" "eza" "bat" "lazygit" "tree" "btop"
        "wget" "curl" "jq" "yq"
    )

    sudo dnf install -y "${core_pkgs[@]}" "${cli_tools[@]}"
    mark_step_complete "dev_packages"
fi

if ! is_step_complete "font"; then
    enable_copr "elxreno/jetbrains-mono-fonts"
    print_message info "Installing Jetbrains Nerd Font..."
    install_package "jetbrains-mono-fonts"
    mark_step_complete "font"
fi

if ! is_step_complete "tpm"; then
    print_message info "Installing Tmux Plugin Manager (TPM)..."
    tpm_dir="$HOME/.tmux/plugins/tpm"
    if ! safe_git_clone https://github.com/tmux-plugins/tpm "$tmux_dir"; then
        print_message error "Failed to install/update Tmux Plugin Manager."
    fi

    mark_step_complete "tpm"
fi

print_message success "Development environment setup complete."
