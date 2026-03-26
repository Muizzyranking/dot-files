#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

PACMAN_PACKAGES=(
    # Dev tools
    "git" "gcc" "make" "cmake" "python" "python-pip" "nodejs"
    "npm" "go" "rustup"

    # CLI tools
    "neovim" "zsh" "tmux" "ripgrep" "fd" "fzf" "tldr" "eza" "bat"
    "lazygit" "tree" "btop" "wget" "curl" "jq" "docker"

    # Hyprland + wayland
    "hyprland" "hyprpaper" "hyprlock" "hypridle" "xdg-desktop-portal-hyprland"
    "rofi-wayland" "grim" "slurp" "swappy" "wl-clipboard"
    "cliphist" "pamixer" "wireplumber" "playerctl" "brightnessctl" "polkit-gnome"
    "blueman" "nautilus" "fastfetch" "wlogout" "udiskie" "acpi"

    # Theming
    "qt5ct" "qt6ct" "kvantum" "pavucontrol"
)

AUR_PACKAGES=(
    # Apps
    "google-chrome" "firefox" "visual-studio-code-bin"
    "telegram-desktop" "slack-desktop" "discord" "spotify"

    # CLI
    "yq"

    # Fonts
    "ttf-jetbrains-mono-nerd" "ttf-maple-nerd-font"

    # Themes / icons / cursors
    "reversal-icon-theme-git"
    "catppuccin-cursors-mocha-blue"
    "catppuccin-cursors-mocha-peach"
    "catppuccin-gtk-theme-mocha"
    "kvantum-theme-catppuccin-git"
    "rose-pine-gtk-theme-full"
)

install_pacman_packages() {
    print_section "Installing pacman packages"

    local to_install=()
    for pkg in "${PACMAN_PACKAGES[@]}"; do
        if pacman_has "$pkg"; then
            print_message info "Already installed: $pkg"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        print_message success "All pacman packages already installed"
        return 0
    fi

    print_message info "Installing: ${to_install[*]}"
    run_cmd "pacman: installing ${#to_install[@]} packages" \
        sudo pacman -S --needed --noconfirm "${to_install[@]}"
}

install_yay() {
    print_section "Setting up yay (AUR helper)"

    if has_cmd yay; then
        print_message info "yay already installed"
        return 0
    fi

    print_message info "Installing yay..."
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    run_cmd "Cloning yay" git clone https://aur.archlinux.org/yay.git "$tmp_dir/yay"
    run_cmd "Building yay" bash -c "cd '$tmp_dir/yay' && makepkg -si --noconfirm"
    rm -rf "$tmp_dir"

    print_message success "yay installed"
}

install_aur_packages() {
    print_section "Installing AUR packages"

    if ! has_cmd yay; then
        print_message error "yay not found, skipping AUR packages"
        return 1
    fi

    local to_install=()
    for pkg in "${AUR_PACKAGES[@]}"; do
        if yay_has "$pkg"; then
            print_message info "Already installed: $pkg"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -eq 0 ]]; then
        print_message success "All AUR packages already installed"
        return 0
    fi

    print_message info "Installing: ${to_install[*]}"
    run_cmd "yay: installing ${#to_install[@]} AUR packages" \
        yay -S --needed --noconfirm "${to_install[@]}"
}

main() {
    setup_logging
    print_header "Package Installation"

    run_cmd "Updating package database" sudo pacman -Sy

    install_pacman_packages
    install_yay
    install_aur_packages

    print_message success "All packages installed"
}

main "$@"
