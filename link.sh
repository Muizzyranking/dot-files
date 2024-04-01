#!/bin/bash

# Settings
dotfiles_dir="$HOME/dot-files"
config_dir="$HOME/.config"
home_dir="$HOME"

# Check if $HOME/.config exists
if [[ -d "$config_dir" ]]; then
	cd "$config_dir" || exit 1 # Change directory (exit on failure)

	# Handle existing 'nvim' directory
	if [[ -d "nvim" ]]; then
		mv "nvim" "nvim.bk" || exit 2 # Rename to nvim.bk (exit on failure)
	fi
	if [[ -d "tmux" ]]; then
		mv "tmux" "tmux.bk" || exit 2 # Rename to nvim.bk (exit on failure)
	fi

	# Create the symlink
	ln -s "$dotfiles_dir/config/nvim" "$config_dir/nvim" || exit 3 # Exit on failure
	ln -s "$dotfiles_dir/config/nvim" "$config_dir/tmux" || exit 4 # Exit on failure

	echo "Successfully linked configuration"
else
	echo "$HOME/.config directory does not exist."
fi

# Handle .zshrc
if [[ -f "$home_dir/.zshrc" ]]; then
	rm "$home_dir/.zshrc" || exit 5 # Delete existing .zshrc (exit on failure)
fi

if [[ -f "$home_dir/.p10k.zsh" ]]; then
	rm "$home_dir/.p10k.zsh" || exit 6 # Delete existing .zshrc (exit on failure)
fi

ln -s "$dotfiles_dir/.zshrc" "$home_dir/.zshrc" || exit 7
ln -s "$dotfiles_dir/.p10k.zsh" "$home_dir/.p10k.zsh" || exit 8
source "$home_dir/.zshrc" || exit 9

ln -s "$dotfiles_dir/local/konsole/Catppuccin-Mocha.colorscheme" "$home_dir/.local/share/konsole"
