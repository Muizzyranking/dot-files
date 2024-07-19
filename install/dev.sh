#!/bin/bash

source ./utils.sh

print_message info "Installing development-related packages..."

packages=(
    "neovim"
    "zsh"
    "tmux"
    "git"
    "nodejs"
    "npm"
    "python3"
    "gcc"
    "g++"
    "ripgrep"
    "fd-find"
    "fzf"
    "tldr"
    "eza"
)

for package in "${packages[@]}"; do
    install_package "$package"
done

print_message info "Enabling COPR repository for Lazygit..."
sudo dnf copr-enable atim/lazygit -y -q
print_message info "Enabled copr repo for lazygit."
install_package "lazygit"


# Oh My Zsh Setup
print_message info "Setting up Oh My Zsh..."
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh}" ]]; then
    print_message info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_message success "Oh My Zsh installed successfully."
else
    print_message warning "Oh My Zsh already installed, skipping."
fi

# Powerlevel10k theme
print_message info "Installing Powerlevel10k theme..."
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
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
    if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/$plugin" ]]; then
        print_message info "Installing $plugin plugin..."
        git clone "https://github.com/zsh-users/$plugin.git" "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/$plugin"
        print_message success "$plugin plugin installed successfully."
    else
        print_message warning "$plugin plugin already installed, skipping."
    fi
done

# Install fzf-tab plugin
if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab" ]]; then
    print_message info "Installing fzf-tab plugin..."
    git clone https://github.com/Aloxaf/fzf-tab ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/fzf-tab
    print_message success "fzf-tab plugin installed successfully."
else
    print_message warning "fzf-tab plugin already installed, skipping."
fi

# Tmux Plugin Manager Installation
print_message info "Installing Tmux Plugin Manager (TPM)..."
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    print_message success "Tmux Plugin Manager (TPM) installed successfully."
else
    print_message warning "Tmux Plugin Manager (TPM) already installed, skipping."
fi

print_message success "Development-related packages and tools installed successfully."
print_message info "To apply Zsh changes, run: source ~/.zshrc"
print_message info "To install Tmux plugins, open tmux and press prefix + I"

