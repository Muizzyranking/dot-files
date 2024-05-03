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


# Install lazygit
# sudo dnf copr enable atim/lazygit -y -q
# sudo dnf install lazygit -y -q
# Enable copr repo for lazygit
if sudo dnf copr-enable atim/lazygit -y -q &> /dev/null; then
  echo "Successfully enabled copr repo for lazygit."
else
  echo "Failed to enable copr repo for lazygit. (Possibly already exists)"
fi

# Install lazygit
if ! dnf list installed lazygit &> /dev/null; then
  # If not installed, attempt installation with dnf
  echo "Installing lazygit..."
  if sudo dnf install lazygit -y -q; then
    echo "Successfully installed lazygit."
  else
    echo "Failed to install lazygit."
  fi
else
  echo "lazygit is already installed, skipping."
fi

echo "Installation completed."

# Zsh Setup

# Oh My Zsh Setup
echo "Installing Oh My Zsh..."

# Check if Oh My Zsh directory exists
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh}" ]]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh already installed, skipping."
fi

# Powerlevel10k theme
echo "Installing Powerlevel10k theme..."

# Check if powerlevel10k directory exists
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
  echo "Powerlevel10k theme already installed, skipping."
fi

# Zsh plugins
echo "Installing Zsh plugins..."

# Zsh history substring search
if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search" ]]; then
  git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
else
  echo "zsh-history-substring-search plugin already installed, skipping."
fi

# Zsh autosuggestions
if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
  echo "zsh-autosuggestions plugin already installed, skipping."
fi

# Zsh syntax highlighting
if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
else
  echo "zsh-syntax-highlighting plugin already installed, skipping."
fi

# Tmux Plugin Manager Installation
echo "Installing Tmux Plugin Manager (TPM)..."

# Check if TPM directory exists
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
  echo "Tmux Plugin Manager (TPM) already installed, skipping."
fi

echo "Installation complete!"

echo -e "Please run the following commands to apply the changes:\n"
echo -e "\$ source ~/.zshrc"
