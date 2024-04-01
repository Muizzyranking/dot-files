#!/bin/bash

# Update and upgrade the package manager
sudo dnf update -y
sudo dnf upgrade -y

# Install packages from list
curl https://raw.githubusercontent.com/Muizzyranking/dot-files/master/packages | xargs sudo dnf install -y
sudo dnf copr enable atim/lazygit -y
sudo dnf install lazygit -y

echo "Installation completed."

# Zsh Setup
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing Powerlevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# Tmux Plugin Manager Installation
echo "Installing Tmux Plugin Manager (TPM)..."
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

echo "Switching to Zsh..."
chsh -s "$(which zsh)"
source ~/.zshrc
