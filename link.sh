#!/bin/bash

set -euo pipefail

cleanup() {
    echo
    print_message info "Script interrupted....."
    exit 1
}

# Set up trap for cleanup
trap cleanup INT TERM

dotfiles_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
config_dir="$HOME/.config"
backup_dir="$HOME/config_backup"
backup_timestamp=$(date +"%Y%m%d_%H%M%S")

source "$dotfiles_dir/scripts/utils.sh"

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        print_message warning "Directory $dir does not exist. Creating..."
        if mkdir -p "$dir"; then
            print_message success "Created $dir directory"
        else
            print_message error "Failed to create directory: $dir"
            exit 1
        fi
    fi
}
ensure_dir "$config_dir"
ensure_dir "$backup_dir"

# Create symbolic link
create_symlink() {
    local source_dir="$1"
    local target_dir="$2"
    local target_name="$3"

    if [[ -L "$target_dir/$target_name" ]]; then
        print_message warning "Removing existing symlink: $target_name"
        unlink "$target_dir/$target_name" || {
            print_message error "Failed to remove existing symlink: $target_name"
            return 1
        }
    fi

    if [[ -d "$target_dir/$target_name" ]]; then
        local backup_name="${target_name}.bk-${backup_timestamp}"
        print_message warning "$target_name directory already exists. Removing"
        mv "${target_dir:?}/$target_name" "$backup_dir/$backup_name" || {
            print_message error "Failed to move $target_name to backup"
            return 1
        }
        print_message success "Moved $target_name to $backup_dir"
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
link_home_file() {
    local file="$1"
    local source_file="$dotfiles_dir/home/$file"
    local target_file="$HOME/$file"

    # Validate source file exists
    if [[ ! -f "$source_file" ]]; then
        print_message error "Source file not found: $source_file"
        return 1
    fi

    if [[ -L "$target_file" ]]; then
        print_message warning "Existing symlink found for $file. Unlinking."
        unlink "$target_file"
    fi

    if [[ -e "$target_file" ]]; then
        local backup_name="${file}.bk-${backup_timestamp}"
        print_message warning "File $target_file exists. Backing up."

        # Move existing file to backup with timestamped name
        if mv "$target_file" "$backup_dir/$backup_name"; then
            print_message success "Moved $file to $backup_dir/$backup_name"
        else
            print_message error "Failed to move $file to backup"
            return 1
        fi
    fi

    if ln -s "$source_file" "$target_file"; then
        print_message success "Created symbolic link for $file"
    else
        print_message error "Failed to create symbolic link for $file"
        return 1
    fi

    print_message success "Successfully created symbolic link for $file"
}

link_zsh_files() {
    local zsh_files=(".zshrc" ".p10k.zsh")
    for file in "${zsh_files[@]}"; do
        link_home_file "$file"
    done
    link_config "zsh"
}


# Available config files
configs=("bat" "git" "hypr" "kitty" "lazygit" "lazyvim" "my_nvim" "nvim" "rofi" "swaync" "tmux" "waybar" "wlogout" "zsh")

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
            case "$config" in
            "zsh") link_zsh_files ;;
            *) link_config "$config" ;;
            esac
        done
        break
    elif [[ " ${configs[*]} " == *" $arg "* ]]; then
        case "$arg" in
        "zsh") link_zsh_files ;;
        *) link_config "$arg" ;;
        esac
    else
        print_message error "Unknown config: $arg"
        exit 1
    fi
done

print_message success "All requested configurations have been linked."
