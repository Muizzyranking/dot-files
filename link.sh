#!/bin/bash

dotfiles_dir="$HOME/dot-files"
config_dir="$HOME/.config"

# Colors
RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Print message with color based on type
print_message() {
	case "$1" in
	error)
		echo -e "${RED}Error: $2${NC}"
		;;
	warning)
		echo -e "${YELLOW}Warning: $2${NC}"
		;;
	success)
		echo -e "${GREEN}Success: $2${NC}"
		;;
	info)
		echo -e "${BLUE}Info: $2${NC}"
		;;
	*)
		echo "$2"
		;;
	esac
}

# Create symbolic link
create_symlink() {
	local source_dir="$1"
	local target_dir="$2"
	local target_name="$3"

	if [[ -d "$target_dir/$target_name" ]]; then
		print_message warning "$target_name directory already exists. Removing"
		#shellcheck disable=SC2115
		rm -r "$target_dir/$target_name" || {
			print_message error "Failed to remove $target_name directory"
			return 1
		}
		print_message success "Successfully removed $target_name directory"
		print_message info "Creating symbolic link for $target_name"
		ln -s "$source_dir/$target_name" "$target_dir/$target_name" || {
			print_message error "Failed to create symbolic link for $target_name"
			return 1
		}
		print_message success "Successfully created symbolic link for $target_name"
	else
		print_message info "Creating symbolic link for $target_name"
		ln -s "$source_dir/$target_name" "$target_dir/$target_name" || {
			print_message error "Failed to create symbolic link for $target_name"
			return 1
		}
		print_message success "Successfully created symbolic link for $target_name"
	fi
}

# Try to change directory to $config_dir, create it if it doesn't exist
if cd "$config_dir"; then
	echo "Directory $config_dir exists."
else
	print_message warning "$HOME/.config directory does not exist. Creating it."
	if mkdir -p "$config_dir" && cd "$config_dir"; then
		print_message success "Successfully created $HOME/.config directory"
	else
		print_message error "Failed to create $HOME/.config directory"
		exit 1
	fi
fi

echo -e "\n"
print_message info "Creating symbolic link for bat"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "bat" || exit 1

echo -e "\n"
print_message info "Creating symbolic link for kitty"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "kitty" || exit 1

echo -e "\n"
print_message info "Creating symbolic link for lazyvim"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "lazyvim" || exit 1

echo -e "\n"
print_message info "Creating symbolic link for lazygit"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "lazygit" || exit 1

echo -e "\n"
print_message info "Creating symbolic link for neofetch"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "neofetch" || exit 1

echo -e "\n"
print_message info "Creating symbolic link for nvim"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "nvim" || exit 1

echo -e "\n"
print_message info "Creating symbolic link for tmux"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "tmux" || exit 1

if [ -f "$HOME/.zshrc" ]; then
	print_message warning "File $HOME/.zshrc exists. Removing"
	rm "$HOME/.zshrc" || {
		print_message error "Failed to remove $HOME/.zshrc"
		exit 1
	}
	print_message success "Successfully removed $HOME/.zshrc"
fi
ln -s "$dotfiles_dir/shell/.zshrc" "$HOME/.zshrc" || {
	print_message error "Failed to create symbolic link for .zshrc"
	exit 1
}

if [ -f "$HOME/.p10k.zsh" ]; then
	print_message warning "File $HOME/.p10k.zsh exists. Removing"
	rm "$HOME/.zshrc" || {
		print_message error "Failed to remove $HOME/.p10k.zsh"
		exit 1
	}
	print_message success "Successfully removed $HOME/.p10k.zsh"
fi
ln -s "$dotfiles_dir/shell/.p10k.zsh" "$HOME/.p10k.zsh" || {
	print_message error "Failed to create symbolic link for .p10k.zsh"
	exit 1
}
