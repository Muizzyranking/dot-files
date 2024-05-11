#!/bin/bash

# File containing the list of packages
package_list_file="packages"

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
print_message info "Starting installation..."

print_message info "Updating package manager..."
# Update and upgrade the package manager
sudo dnf update -y -q
print_message success "Package manager updated successfully."

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

print_message info "Installation complete!"

print_message info "To apply the changes, run the following command:"
print_message info "\n\t\$ source ~/.zshrc"
