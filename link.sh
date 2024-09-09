#!/bin/bash

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_dir="$HOME/.config"

source "$dotfiles_dir/install/utils.sh"

if [[ ! -d "$config_dir" ]]; then
    if mkdir -p "$config_dir"; then
        print_message success "Created $config_dir directory"
    else
        print_message error "Failed to create $config_dir directory"
        exit 1
    fi
fi

# Create symbolic link
create_symlink() {
    local source_dir="$1"
    local target_dir="$2"
    local target_name="$3"

    if [[ -d "$target_dir/$target_name" ]]; then
        print_message warning "$target_name directory already exists. Removing"
        rm -r "${target_dir:?}/${target_name:?}" || {
            print_message error "Failed to remove $target_name directory"
            return 1
        }
        print_message success "Successfully removed $target_name directory"
    fi

    print_message info "Creating symbolic link for $target_name"
    ln -s "$source_dir/$target_name" "$target_dir/$target_name" || {
        print_message error "Failed to create symbolic link for $target_name"
        return 1
    }
    print_message success "Successfully created symbolic link for $target_name"
}

# Function to link config files
link_config() {
    local config="$1"
    echo -e "\n"
    create_symlink "$dotfiles_dir/config" "$config_dir" "$config" || exit 1
}

# Function to link shell files
link_shell_file() {
    local file="$1"
    if [ -f "$HOME/$file" ]; then
        print_message warning "File $HOME/$file exists. Removing"
        rm "$HOME/$file" || {
            print_message error "Failed to remove $HOME/$file"
            exit 1
        }
        print_message success "Successfully removed $HOME/$file"
    fi
    ln -s "$dotfiles_dir/shell/$file" "$HOME/$file" || {
        print_message error "Failed to create symbolic link for $file"
        exit 1
    }
    print_message success "Successfully created symbolic link for $file"
}

# Available config files
configs=("bat" "ags" "cava" "hypr" "kitty" "Kvantum" "lazygit" "lazyvim" "neofetch" "nvim" "rofi" "swaync" "tmux" "waybar" "wlogout" "zsh")

# If no arguments provided, show usage
if [ $# -eq 0 ]; then
    print_message error "Usage: $0 [config_name ...] [all]"
    print_message info "Available configs: ${configs[*]}"
    exit 1
fi

# Process arguments
for arg in "$@"; do
    if [ "$arg" = "all" ]; then
        for config in "${configs[@]}"; do
            if [ "$config" = "zsh" ]; then
                link_shell_file ".zshrc"
                link_shell_file ".p10k.zsh"
            else
                link_config "$config"
            fi
        done
        break
    elif [[ " ${configs[*]} " == *" $arg "* ]]; then
        if [ "$arg" = "zsh" ]; then
            link_shell_file ".zshrc"
            link_shell_file ".p10k.zsh"
        else
            link_config "$arg"
        fi
    else
        print_message error "Unknown config: $arg"
        exit 1
    fi
done

print_message success "All requested configurations have been linked."
