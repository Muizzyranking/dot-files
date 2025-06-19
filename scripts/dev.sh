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

# Oh My Zsh Setup
print_message info "Installing Oh My Zsh..."

if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh}" ]]; then
    temp_script="/tmp/install-oh-my-zsh.sh"

    print_message info "Downloading Oh My Zsh install script..."

    if safe_download "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh" "$temp_script"; then
        if bash -n "$temp_script"; then
            sh "$temp_script" "" --unattended
            rm -f "$temp_script"
            print_message success "Oh My Zsh installed successfully."
        else
            print_message error "Invalid Oh My Zsh install script"
            rm -f "$temp_script"
        fi
    fi
else
    print_message warning "Oh My Zsh already installed, skipping."
fi

# Powerlevel10k theme
print_message info "Installing Powerlevel10k theme..."
p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [[ ! -d "$p10k_dir" ]]; then
    safe_git_clone https://github.com/romkatv/powerlevel10k.git "$p10k_dir"
    print_message success "Powerlevel10k theme installed successfully."
fi

# Zsh plugins
zsh_plugins=(
    "zsh-history-substring-search"
    "zsh-autosuggestions"
    "zsh-syntax-highlighting"
)

for plugin in "${zsh_plugins[@]}"; do
    plugin_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/$plugin"
    if [[ ! -d "$plugin_dir" ]]; then
        print_message info "Installing $plugin plugin..."
        safe_git_clone "https://github.com/zsh-users/$plugin.git" "$plugin_dir"
    fi
done

# Install fzf-tab plugin
fzf_tab_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fzf-tab"
if [[ ! -d "$fzf_tab_dir" ]]; then
    print_message info "Installing fzf-tab plugin..."
    safe_git_clone https://github.com/Aloxaf/fzf-tab "$fzf_tab_dir"
    print_message success "fzf-tab plugin installed successfully."
else
    print_message warning "fzf-tab plugin already installed, skipping."
fi

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
