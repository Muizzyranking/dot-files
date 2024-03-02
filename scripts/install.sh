#!/bin/bash

# Update and upgrade the package manager
sudo dnf update -y
sudo dnf upgrade -y

# Install packages from your list
curl https://raw.githubusercontent.com/muizzyranking/dotfiles/scripts/packages | xargs sudo dnf install -y
sudo dnf copr enable atim/lazygit -y
sudo dnf install lazygit -y
if [ $? -ne 0 ]; then
	echo "Error: Package installation failed. Please check manually."
	exit 1 # Exit the script on error
fi

echo "Installation completed."

# Configuration Management
config_dir="$HOME/.config"

if [ -d "$config_dir" ]; then
	cd "$config_dir" || exit 1 # Exit if the cd command fails

	if [ -d ".git" ]; then
		echo "Removing existing Git repository..."
		rm -rf .git
	fi

	echo "Initializing new Git repository..."
	git init
	git remote add origin git@github.com:Muizzyranking/dot-files.git
	git fetch origin
	git checkout -b master --track origin/master
else
	echo "Error: ~/.config directory does not exist."
	exit 1
fi

# Zsh Setup
echo "Installing Oh My Zsh..."
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "Installing Powerlevel10k theme..."
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k

echo "Installing Zsh plugins..."
git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting

# .zshrc Handling
if [ -f ~/.zshrc ]; then
	echo "Removing existing ~/.zshrc"
	rm ~/.zshrc
fi

echo "Creating symlink for ~/.zshrc"
ln -s ~/.config/shell/.zshrc ~/.zshrc
ln -s ~/.config/shell/.p10k.zsh ~/.p10k.zsh

# Tmux Plugin Manager Installation
echo "Installing Tmux Plugin Manager (TPM)..."
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

#Symlink konsole colorscheme
echo "Setting konsole colorscheme..."
ln -s ~/.config/konsole/Catppuccin-Mocha.colorscheme ~/.local/share/konsole/catppuccin-mocha.colorscheme

echo "Switching to Zsh..."
chsh -s "$(which zsh)"
source ~/.zshrc
