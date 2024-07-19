#!/bin/bash

source ./utils.sh

if [ $# -eq 0 ]; then
    print_message error "No arguments provided. Usage: ./install.sh [argument] ..."
    exit 1
fi

for group in "$@"; do
    case $group in
        all)
            bash ./install/dev.sh
            bash ./install/hypr.sh
            bash ./link.sh all
            ;;
        hypr)
            bash ./install/hypr.sh
            bash ./link.sh gtk-3.0 gtk-4.0 hypr Kvantum neofetch qt5ct rofi swaync waybar wlogout zsh
            ;;
        dev)
            bash ./install/dev.sh
            bash ./link.sh kitty nvim bat lazyvim lazygit zsh tmux
            ;;
        *)
            print_message error "Unknown group: $group"
            ;;
    esac
done

print_message success "Installation complete!"
