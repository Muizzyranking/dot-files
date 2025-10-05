#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$script_dir/utils.sh" ]]; then
    echo "Error: Utility script not found at $script_dir/utils.sh"
    exit 1
fi

source "$script_dir/utils.sh"

print_message info "Installing development-related packages..."

core_packages=(
    "git"
    "gcc"
    "gcc-c++"
    "make"
    "cmake"
    "python3"
    "python3-pip"
    "nodejs"
    "nodejs-npm"
    "golang"
    "rust"
    "cargo"
)

cli_tools=(
    "neovim"
    "zsh"
    "tmux"
    "ripgrep"
    "fd-find"
    "fzf"
    "tldr"
    "eza"
    "bat"
    "lazygit"
    "tree"
    "btop"
    "wget"
    "curl"
    "jq"
    "yq"
)

print_message info "Installing core development packages..."
install_packages "${core_packages[@]}"

print_message info "Installing CLI tools..."
install_packages "${cli_tools[@]}"

# Tmux Plugin Manager Installation
print_message info "Installing Tmux Plugin Manager (TPM)..."
tmux_dir="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$tmux_dir" ]]; then
    safe_git_clone https://github.com/tmux-plugins/tpm "$tmux_dir"

    if [[ -d "$tmux_dir" ]]; then
        print_message success "Tmux Plugin Manager (TPM) installed successfully."
        print_message info "Installing Tmux plugins"
        "$tmux_dir/bin/install_plugins"
    fi
else
    print_message warning "Tmux Plugin Manager (TPM) already installed, skipping."
fi

print_message success "Development-related packages and tools installed successfully."
print_message info "To apply Zsh changes, run: source ~/.zshrc"
print_message info "To install Tmux plugins, open tmux and press prefix + I"
