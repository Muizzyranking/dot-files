#!/bin/bash

# File containing the list of packages
package_list_file="packages"
dotfiles_dir="$HOME/dot-files"
config_dir="$HOME/.config"

create_symlink() {
	local source_dir="$1"
	local target_dir="$2"
	local target_name="$3"

	if [[ -d "$target_dir/$target_name" ]]; then
		print_message warning "$target_name directory already exists. Removing"
		#shellcheck disable=SC2115
		rm -r "$target_dir/$target_name"
		if [[ -d "$target_dir/$target_name" ]]; then
			print_message error "Failed to remove $target_name directory"
			return 1
		else
			print_message success "Successfully removed $target_name directory"
			print_message info "Creating symbolic link for $target_name"
			ln -s "$source_dir/$target_name" "$target_dir/$target_name" || {
				print_message error "Failed to create symbolic link for $target_name"
				return 1
			}
			print_message success "Successfully created symbolic link for $target_name"

		fi
	else
		print_message info "Creating symbolic link for $target_name"
		ln -s "$source_dir/$target_name" "$target_dir/$target_name" || {
			print_message error "Failed to create symbolic link for $target_name"
			return 1
		}
		print_message success "Successfully created symbolic link for $target_name"
	fi
}

print_message() {
	# colors
	RED='\033[0;31m'
	YELLOW='\033[0;33m'
	GREEN='\033[0;32m'
	BLUE='\033[0;34m'
	NC='\033[0m' # No Color

	case "$1" in
	error)
		echo -e "${RED}$2${NC}"
		;;
	warning)
		echo -e "${YELLOW}$2${NC}"
		;;
	success)
		echo -e "${GREEN}$2${NC}"
		;;
	info)
		echo -e "${BLUE}$2${NC}"
		;;
	*)
		echo -e "$2"
		;;
	esac
}
print_message info "-------------------------------"
print_message info "Starting installation..."
print_message info "-------------------------------"
echo -e "\n"

print_message info "Updating package manager..."
# Update and upgrade the package manager
sudo dnf update -y -q
print_message success "Package manager updated successfully."
echo -e "\n"

print_message info "Installing packages..."
echo -e "\n"

# Loop through each package in the file
while read -r package; do
	# Check if the package is already installed
	if dnf list installed "$package" &>/dev/null; then
		print_message warning "Package $package already installed, skipping..."
	else
		# Check if the package is available in the repositories
		if dnf info "$package" &>/dev/null; then
			print_message info "Installing package $package..."
			sudo dnf install -y -q "$package"
			print_message success "Successfully installed package $package."
		else
			print_message error "Package $package not found in the repositories."
		fi
	fi
done <"$package_list_file"

# Install lazygit
# sudo dnf copr enable atim/lazygit -y -q
# sudo dnf install lazygit -y -q
# Enable copr repo for lazygit
if sudo dnf copr-enable atim/lazygit -y -q &>/dev/null; then
	print_message info "Enabled copr repo for lazygit."
else
	print_message error "Failed to enable copr repo for lazygit."
fi

# Install lazygit
if ! dnf list installed lazygit &>/dev/null; then
	# If not installed, attempt installation with dnf
	print_message info "Installing lazygit..."
	if sudo dnf install lazygit -y -q; then
		print_message success "Successfully installed lazygit."
	else
		print_message error "Failed to install lazygit."
	fi
else
	print_message warning "lazygit already installed, skipping..."
fi

print_message info "Installation complete!"

# Zsh Setup

# Oh My Zsh Setup
print_message info "Installing Oh My Zsh..."

# Check if Oh My Zsh directory exists
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh}" ]]; then
	print_message info "Installing Oh My Zsh..."
	sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
	print_message warning "Oh My Zsh already installed, skipping."
fi

# Powerlevel10k theme
print_message info "Installing Powerlevel10k theme..."
# Check if powerlevel10k directory exists
if [[ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
	print_message info "Installing Powerlevel10k theme..."
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
else
	print_message warning "Powerlevel10k theme already installed, skipping."
fi

# Zsh plugins
print_message info "Installing Zsh plugins..."

# Zsh history substring search
if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search" ]]; then
	print_message info "Installing zsh-history-substring-search plugin..."
	git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search
else
	print_message warning "zsh-history-substring-search plugin already installed, skipping."
fi

# Zsh autosuggestions
if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]]; then
	print_message info "Installing zsh-autosuggestions plugin..."
	git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
else
	print_message warning "zsh-autosuggestions plugin already installed, skipping."
fi

# Zsh syntax highlighting
if [[ ! -d "${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]]; then
	print_message info "Installing zsh-syntax-highlighting plugin..."
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
else
	print_message warning "zsh-syntax-highlighting plugin already installed, skipping."
fi

# Tmux Plugin Manager Installation
print_message info "Installing Tmux Plugin Manager (TPM)..."
# Check if TPM directory exists
if [[ ! -d ~/.tmux/plugins/tpm ]]; then
	print_message info "Installing Tmux Plugin Manager (TPM)..."
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
else
	print_message warning "Tmux Plugin Manager (TPM) already installed, skipping."
fi

echo -e "\n"
echo "---------------------------------------"
print_message info "Installation complete! Check for any errors"
echo "---------------------------------------"
echo -e "\n"

echo "---------------------------------------"
print_message info "Creating symlinks..."
echo "---------------------------------------"

if cd "$config_dir"; then
	print_message success "Successfully changed directory to $HOME/.config"
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
create_symlink "$dotfiles_dir/config" "$config_dir" "bat" || {
	print_message error "Failed to create symbolic link for bat"
	exit 1
}

echo -e "\n"
print_message info "Creating symbolic link for kitty"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "kitty" || {
	print_message error "Failed to create symbolic link for kitty"
	exit 1
}
echo -e "\n"
print_message info "Creating symbolic link for lazygit"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "lazygit" || {
	print_message error "Failed to create symbolic link for lazygit"
	exit 1
}
echo -e "\n"
print_message info "Creating symbolic link for lazyvim"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "lazyvim" || {
	print_message error "Failed to create symbolic link for lazyvim"
	exit 1
}
echo -e "\n"
print_message info "Creating symbolic link for neofetch"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "neofetch" || {
	print_message error "Failed to create symbolic link for neofetch"
	exit 1
}
echo -e "\n"
print_message info "Creating symbolic link for nvim"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "nvim" || {
	print_message error "Failed to create symbolic link for nvim"
	exit 1
}
echo -e "\n"
print_message info "Creating symbolic link for tmux"
echo -e "\n"
create_symlink "$dotfiles_dir/config" "$config_dir" "tmux" || {
	print_message error "Failed to create symbolic link for tmux"
	exit 1
}

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

echo "---------------------------------------"
print_message success "Created symlinks..."
echo "---------------------------------------"

print_message info "To apply the changes, run the following command:"
print_message info "\n\t\$ source ~/.zshrc"
