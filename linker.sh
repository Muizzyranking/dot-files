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
backup_dir="$HOME/.dotfiles_backup"
backup_timestamp=$(date +"%Y%m%d_%H%M%S")

source "$dotfiles_dir/scripts/utils.sh"

print_banner() {
    echo "================================================"
    echo "  $SCRIPT_NAME v$SCRIPT_VERSION"
    echo "  Creating symbolic links for dotfiles"
    echo "================================================"
    echo
}

show_usage() {
    /usr/bin/cat <<EOF
Usage: $0 [OPTIONS] [CONFIGS...]

CONFIGS:
    all         Link all available configurations
    $(printf "%s " "${configs[@]}")

OPTIONS:
    -h, --help      Show this help message
    -v, --version   Show version information
    -b, --backup    Show backup directory location
    -r, --restore   Restore from backup (interactive)

EXAMPLES:
    $0 all                    # Link all configurations
    $0 nvim zsh kitty        # Link specific configurations
    $0 --restore             # Restore from backup

EOF
}

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

# Enhanced backup function with better organization
create_backup() {
    local source_path="$1"
    local item_name="$2"
    local backup_subdir="$backup_dir/$backup_timestamp"

    ensure_dir "$backup_subdir"

    if [[ -e "$source_path" ]]; then
        local backup_path="$backup_subdir/$item_name"

        # Create parent directories if needed
        mkdir -p "$(dirname "$backup_path")"

        if cp -r "$source_path" "$backup_path" 2>/dev/null; then
            print_message success "Backed up $item_name to $backup_path"

            # Create backup manifest
            echo "$(date): $source_path -> $backup_path" >>"$backup_subdir/manifest.txt"
            return 0
        else
            print_message error "Failed to backup $item_name"
            return 1
        fi
    fi

    return 1
}

# Create symbolic link with enhanced backup
create_symlink() {
    local source_dir="$1"
    local target_dir="$2"
    local target_name="$3"
    local target_path="$target_dir/$target_name"
    local source_path="$source_dir/$target_name"

    # Validate source exists
    if [[ ! -e "$source_path" ]]; then
        print_message error "Source not found: $source_path"
        return 1
    fi

    # Handle existing symlink
    if [[ -L "$target_path" ]]; then
        local link_target
        link_target=$(readlink "$target_path")
        if [[ "$link_target" == "$source_path" ]]; then
            print_message info "$target_name is already correctly linked"
            return 0
        fi

        print_message warning "Removing existing symlink: $target_name"
        unlink "$target_path" || {
            print_message error "Failed to remove existing symlink: $target_name"
            return 1
        }
    fi

    # Handle existing directory/file
    if [[ -e "$target_path" ]]; then
        print_message warning "$target_name already exists. Creating backup..."
        if create_backup "$target_path" "$target_name"; then
            rm -rf "$target_path" || {
                print_message error "Failed to remove existing $target_name"
                return 1
            }
        else
            print_message error "Backup failed for $target_name. Aborting link creation."
            return 1
        fi
    fi

    print_message info "Creating symbolic link for $target_name"
    if ln -s "$source_path" "$target_path"; then
        print_message success "Successfully created symbolic link for $target_name"
        return 0
    else
        print_message error "Failed to create symbolic link for $target_name"
        return 1
    fi
}

# Function to link config files
link_config() {
    local config="$1"
    echo -e "\n"
    print_message info "Linking configuration: $config"
    create_symlink "$dotfiles_dir/config" "$config_dir" "$config" || {
        print_message error "Failed to link $config"
        return 1
    }
}

# Function to link home files
link_home_file() {
    local file="$1"
    local source_file="$dotfiles_dir/home/$file"
    local target_file="$HOME/$file"

    print_message info "Linking home file: $file"

    # Validate source file exists
    if [[ ! -f "$source_file" ]]; then
        print_message error "Source file not found: $source_file"
        return 1
    fi

    # Handle existing symlink
    if [[ -L "$target_file" ]]; then
        local link_target
        link_target=$(readlink "$target_file")
        if [[ "$link_target" == "$source_file" ]]; then
            print_message info "$file is already correctly linked"
            return 0
        fi

        print_message warning "Existing symlink found for $file. Unlinking."
        unlink "$target_file"
    fi

    # Handle existing file
    if [[ -e "$target_file" ]]; then
        print_message warning "File $target_file exists. Creating backup..."
        if create_backup "$target_file" "$file"; then
            rm -f "$target_file" || {
                print_message error "Failed to remove existing $file"
                return 1
            }
        else
            print_message error "Backup failed for $file. Aborting link creation."
            return 1
        fi
    fi

    if ln -s "$source_file" "$target_file"; then
        print_message success "Successfully created symbolic link for $file"
        return 0
    else
        print_message error "Failed to create symbolic link for $file"
        return 1
    fi
}

# Specialized linking functions
link_zsh_files() {
    print_message info "Setting up Zsh configuration..."
    local zsh_files=(".zshrc" ".p10k.zsh")
    local success=true

    for file in "${zsh_files[@]}"; do
        if ! link_home_file "$file"; then
            success=false
        fi
    done

    if ! link_config "zsh"; then
        success=false
    fi

    if $success; then
        print_message success "Zsh configuration linked successfully"
    else
        print_message error "Some Zsh files failed to link"
        return 1
    fi
}

link_git_files() {
    print_message info "Setting up Git configuration..."
    if link_home_file ".gitconfig"; then
        print_message success "Git configuration linked successfully"
    else
        print_message error "Failed to link Git configuration"
        return 1
    fi
}

# Initialize directories
ensure_dir "$config_dir"
ensure_dir "$backup_dir"

# Available config files
configs=("bat" "git" "hypr" "kitty" "lazygit" "lazyvim" "nvim" "rofi" "swaync" "tmux" "waybar" "wlogout" "zsh")

main() {
    local show_help=false
    local show_backup=false
    local configs_to_link=()

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
        -h | --help)
            show_help=true
            shift
            ;;
        -b | --backup)
            show_backup=true
            shift
            ;;
        all)
            configs_to_link=("${configs[@]}")
            shift
            ;;
        *)
            if [[ " ${configs[*]} " == *" $1 "* ]]; then
                configs_to_link+=("$1")
            else
                print_message error "Unknown config: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
        esac
    done

    # Handle special flags
    if $show_help; then
        show_usage
        exit 0
    fi

    if $show_backup; then
        echo "Backup directory: $backup_dir"
        if [[ -d "$backup_dir" ]]; then
            echo "Backup size: $(du -sh "$backup_dir" 2>/dev/null | cut -f1)"
        fi
        exit 0
    fi

    # Validate we have configs to link
    if [[ ${#configs_to_link[@]} -eq 0 ]]; then
        print_message error "No configurations specified."
        show_usage
        exit 1
    fi

    print_banner
    print_message info "Backup directory: $backup_dir"
    print_message info "Backup timestamp: $backup_timestamp"
    echo

    # Process configurations
    local overall_success=true
    for config in "${configs_to_link[@]}"; do
        case "$config" in
        "zsh")
            if ! link_zsh_files; then
                overall_success=false
            fi
            ;;
        "git")
            if ! link_git_files; then
                overall_success=false
            fi
            ;;
        *)
            if ! link_config "$config"; then
                overall_success=false
            fi
            ;;
        esac
    done

    echo
    if $overall_success; then
        print_message success "All requested configurations have been linked successfully!"
        print_message info "Backups are stored in: $backup_dir/$backup_timestamp"
    else
        print_message warning "Some configurations failed to link. Check the output above."
        exit 1
    fi
}

main "$@"
