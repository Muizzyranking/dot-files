#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$script_dir/utils.sh" ]]; then
    echo "Error: Utility script not found at $script_dir/utils.sh"
    exit 1
fi

source "$script_dir/utils.sh"

print_message info "Installing development-related packages..."

packages=(
    "neovim"
    "zsh"
    "tmux"
    "git"
    "nodejs"
    "nodejs-npm"
    "python3"
    "gcc"
    # "g++"
    "ripgrep"
    "fd-find"
    "fzf"
    "tldr"
    "eza"
    "bat"
    "lazygit"
)

for package in "${packages[@]}"; do
    if ! install_package "$package"; then
        print_message error "Failed to install $package"
    fi
done

print_message info "Enabling COPR repository for Lazygit..."
if sudo dnf copr enable atim/lazygit -y; then
    install_package "lazygit"
else
    print_message error "Failed to enable COPR repository for Lazygit."
fi

# Oh My Zsh Setup
print_message info "Installing Oh My Zsh..."
omz_install_script="/tmp/install-oh-my-zsh.sh"
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh}" ]]; then
    print_message info "Downloading Oh My Zsh install script..."

    # Download with timeout and SSL verification
    if ! curl -fsSL --connect-timeout 30 --max-time 300 \
        https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
        -o "$omz_install_script"; then
        print_message error "Failed to download Oh My Zsh install script"
        exit 1
    fi

    # Verify script before executing (basic check)
    if ! bash -n "$omz_install_script"; then
        print_message error "Invalid Oh My Zsh install script"
        exit 1
    fi

    # Execute with more robust error handling
    if ! sh "$omz_install_script" "" --unattended; then
        print_message error "Oh My Zsh installation failed"
        exit 1
    fi

    # Clean up download
    rm -f "$omz_install_script"

    print_message success "Oh My Zsh installed successfully."
else
    print_message warning "Oh My Zsh already installed, skipping."
fi

safe_git_clone() {
    local repo="$1"
    local dest="$2"
    local max_attempts=3
    local attempt=0

    while ((attempt < max_attempts)); do
        if git clone --depth=1 --filter=blob:none \
            --quiet "$repo" "$dest"; then
            return 0
        fi
        ((attempt++))
        sleep 2
    done
    return 1
}

# Powerlevel10k theme
print_message info "Installing Powerlevel10k theme..."
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
    safe_git_clone https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    print_message success "Powerlevel10k theme installed successfully."
else
    print_message warning "Powerlevel10k theme already installed, skipping."
fi

# Zsh plugins
zsh_plugins=(
    "zsh-history-substring-search"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
)

for plugin in "${zsh_plugins[@]}"; do
    if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin" ]]; then
        print_message info "Installing $plugin plugin..."
        safe_git_clone "https://github.com/zsh-users/$plugin.git" "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
        print_message success "$plugin plugin installed successfully."
    else
        print_message warning "$plugin plugin already installed, skipping."
    fi
done

# Install fzf-tab plugin
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab" ]]; then
    print_message info "Installing fzf-tab plugin..."
    safe_git_clone https://github.com/Aloxaf/fzf-tab "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab"
    print_message success "fzf-tab plugin installed successfully."
else
    print_message warning "fzf-tab plugin already installed, skipping."
fi

# Tmux Plugin Manager Installation
print_message info "Installing Tmux Plugin Manager (TPM)..."
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    safe_git_clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"

    if [[ -d $HOME/.tmux/plugins/tpm ]]; then
        print_message success "Tmux Plugin Manager (TPM) installed successfully."
        print_message info "Installing Tmux plugins"
        "$HOME/.tmux/plugins/tpm/bin/install_plugins"
    fi
else
    print_message warning "Tmux Plugin Manager (TPM) already installed, skipping."
fi

print_message success "Development-related packages and tools installed successfully."
print_message info "To apply Zsh changes, run: source ~/.zshrc"
print_message info "To install Tmux plugins, open tmux and press prefix + I"
