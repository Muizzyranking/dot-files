#!/bin/bash

set -euo pipefail

# --- Setup ---
DOTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/config_backup"
BACKUP_TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Source utils if available
if [[ -f "$DOTS_DIR/scripts/utils.sh" ]]; then
    source "$DOTS_DIR/scripts/utils.sh"
else
    # Fallback print_message if utils missing
    print_message() { echo "$2"; }
fi

cleanup() {
    echo
    print_message info "Script interrupted."
    exit 1
}
trap cleanup INT TERM

# --- Helpers ---

ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        if mkdir -p "$dir"; then
            print_message info "Created directory: $dir"
        else
            print_message error "Failed to create directory: $dir"
            exit 1
        fi
    fi
}

backup_item() {
    local target="$1"
    local name
    name=$(basename "$target")
    local backup_name="${name}.bk-${BACKUP_TIMESTAMP}"

    ensure_dir "$BACKUP_DIR"

    if mv "$target" "$BACKUP_DIR/$backup_name"; then
        print_message warning "Backed up existing $target to $BACKUP_DIR/$backup_name"
    else
        print_message error "Failed to backup $target"
        return 1
    fi
}

link_item() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        print_message error "Source does not exist: $source"
        return 1
    fi

    if [[ -L "$target" ]]; then
        local current_link
        current_link=$(readlink "$target")
        if [[ "$current_link" == "$source" ]]; then
            print_message info "Skipping: $target already links to $source"
            return 0
        else
            print_message warning "Relinking: $target (was $current_link)"
            unlink "$target"
        fi
    elif [[ -e "$target" ]]; then
        backup_item "$target"
    fi

    ensure_dir "$(dirname "$target")"

    if ln -s "$source" "$target"; then
        print_message success "Linked: $source -> $target"
    else
        print_message error "Failed to link $target"
        return 1
    fi
}

# --- Specific Linkers ---

link_config_folder() {
    local config_name="$1"
    link_item "$DOTS_DIR/config/$config_name" "$CONFIG_DIR/$config_name"
}

link_home_file() {
    local filename="$1"
    link_item "$DOTS_DIR/home/$filename" "$HOME/$filename"
}

link_vscode() {
    print_message info "Processing VSCode configuration..."
    local vscode_user_dir="$HOME/.config/Code/User"
    ensure_dir "$vscode_user_dir"
    if [[ -f "$DOTS_DIR/config/vscode/settings.json" ]]; then
        link_item "$DOTS_DIR/config/vscode/settings.json" "$vscode_user_dir/settings.json"
    fi
}

link_git() {
    print_message info "Processing Git configuration..."
    
    # Check for ~/.gitconfig
    local global_git_config="$CONFIG_DIR/.gitconfig"
    if [[ -f "$global_git_config" ]]; then
        print_message warning "Found .gitconfig in home config directory."
        if backup_item "$global_git_config"; then
            print_message success "Backed up .gitconfig to allow git config to work properly"
        else
            print_message error "Failed to backup .gitconfig, git config may not work correctly"
        fi
    fi
    # Now link the git config
    link_config_folder "git"
}

link_zsh() {
    print_message info "Processing Zsh configuration..."
    link_home_file ".zshrc"
    link_config_folder "zsh"
    link_config_folder "oh-my-posh"
}

link_bash() {
    print_message info "Processing Bash configuration..."
    link_home_file ".bashrc"
}

# --- Main Logic ---

# 1. Discover available configs
available_configs=()
while IFS= read -r config; do
    case "$config" in
    vscode | zsh | oh-my-posh) continue ;;
    *) available_configs+=("$config") ;;
    esac
done < <(find "$DOTS_DIR/config" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)

tasks=()
want_all=false

if [[ $# -eq 0 ]]; then
    want_all=true
else
    for arg in "$@"; do
        if [[ "$arg" == "all" ]]; then
            want_all=true
            break
        else
            tasks+=("$arg")
        fi
    done
fi

if $want_all; then
    tasks+=("${available_configs[@]}")
    tasks+=("zsh" "bash" "vscode")

    while IFS= read -r file; do
        case "$file" in
        .zshrc | .bashrc) continue ;;
        *) tasks+=("$file") ;;
        esac
    done < <(find "$DOTS_DIR/home" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort)
fi

# Deduplicate
IFS=$'\n' sorted_unique_tasks=($(sort -u <<<"${tasks[*]}"))
unset IFS

for item in "${sorted_unique_tasks[@]}"; do
    case "$item" in
    vscode) link_vscode ;;
    zsh) link_zsh ;;
    bash) link_bash ;;
    git) link_git ;;
    oh-my-posh) link_config_folder "oh-my-posh" ;;
    *)
        if [[ -d "$DOTS_DIR/config/$item" ]]; then
            link_config_folder "$item"
        elif [[ -f "$DOTS_DIR/home/$item" ]]; then
            link_home_file "$item"
        else
            print_message warning "Unknown config or task: $item"
        fi
        ;;
    esac
done

print_message success "Linking complete."
