#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

print_message step "Installing Hyprland Packages"

if ! is_step_complete "hypr_packages"; then
    print_message info "Installing Hyprland and related components..."

    # Core Hyprland & Wayland
    hypr_core=(
        "hyprland" "hyprpaper" "hyprlock" "hypridle"
        "xdg-desktop-portal-hyprland" "waybar" "rofi-wayland"
    )

    # Utilities
    hypr_utils=(
        "grim" "slurp" "swappy" "wl-clipboard" "cliphist"
        "SwayNotificationCenter" "pamixer" "wireplumber" "playerctl"
        "brightnessctl" "polkit-gnome" "NetworkManager-tui"
        "blueman" "nautilus" "fastfetch" "wlogout", "udiskie", "acpi"
    )

    dev_packages=(
        "wayland-devel" "wayland-protocols-devel" "hyprlang-devel"
        "pango-devel" "cairo-devel" "file-devel" "libglvnd-devel"
        "libglvnd-core-devel" "libjpeg-turbo-devel" "libwebp-devel" "gcc-c++")

    # Theme & GUI
    hypr_gui=(
        "qt5ct" "qt6ct" "kvantum" "pavucontrol"
    )

    sudo dnf install -y "${hypr_core[@]}" "${hypr_utils[@]}" "${hypr_gui[@]}" "${dev_packages[@]}"
    mark_step_complete "hypr_packages"
fi

print_message success "Hyprland environment setup complete."
