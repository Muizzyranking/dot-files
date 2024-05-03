#!/bin/bash

# Update and upgrade the package manager
sudo dnf update -y -qq
sudo dnf upgrade -y -qq

# File containing the list of packages
package_list_file="packages"

# Loop through each package in the file
while read -r package; do
    # Check if the package is already installed
    if dnf list installed "$package" &> /dev/null; then
        echo "Package $package is already installed"
    else
        # Check if the package is available in the repositories
        if dnf info "$package" &> /dev/null; then
            echo -e "Installing package $package\n"
            sudo dnf install -y -q "$package"
            echo -e "\nInstalled package $package"
        else
            echo "Package $package not found, skipping..."
        fi
    fi
done < "$package_list_file"


# Install packages from list
sudo dnf copr enable atim/lazygit -y -q
sudo dnf install lazygit -y -q

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

source "$HOME"/.zshrc
