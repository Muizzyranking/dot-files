#!/bin/bash

# Ensure the script is run with sudo
if [ "$EUID" -ne 0 ]; then
    echo "This script requires sudo privileges. Re-running with sudo..."
    sudo "$0" "$@"
    exit $?
fi

# Get the directory where install.sh is located
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source utils.sh using the resolved path
source "$script_dir/scripts/utils.sh"

if [ $# -eq 0 ]; then
    print_message error "No arguments provided. Usage: ./install.sh [\"all\", \"dev\", \"hypr\"] ..."
    exit 1
fi

for group in "$@"; do
    case $group in
        all)
            bash "$script_dir/scripts/dev.sh"
            bash "$script_dir/scripts/hypr.sh"
            bash "$script_dir/link.sh" all
            ;;
        hypr)
            bash "$script_dir/scripts/hypr.sh"
            bash "$script_dir/link.sh" hypr Kvantum fastfetch rofi swaync waybar wlogout zsh
            ;;
        dev)
            bash "$script_dir/scripts/dev.sh"
            bash "$script_dir/link.sh" kitty nvim bat lazyvim lazygit zsh tmux
            ;;
        *)
            print_message error "Unknown group: $group"
            ;;
    esac
done

print_message success "Installation complete!"
