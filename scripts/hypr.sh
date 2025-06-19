#!/bin/bash

# scripts/hypr.sh

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

print_message info "Installing Hyprland and related packages..."

print_message info "Enabling COPR repositories..."
sudo dnf copr enable solopasha/hyprland -y
sudo dnf copr enable -y erikreider/SwayNotificationCenter

dev_packages=(
    "wayland-devel"
    "wayland-protocols-devel"
    "hyprlang-devel"
    "pango-devel"
    "cairo-devel"
    "file-devel"
    "libglvnd-devel"
    "libglvnd-core-devel"
    "libjpeg-turbo-devel"
    "libwebp-devel"
    "gcc-c++"
)

hyprland_packages=(
    "hyprland"
    "hyprpaper"
    "hyprlock"
    "hypridle"
    "xdg-desktop-portal-hyprland"
    "waybar"
    "wofi"
    "rofi-wayland"
)

# Screenshot and clipboard tools
screenshot_packages=(
    "grim"
    "slurp"
    "swappy"
    "wl-clipboard"
    "cliphist"
)

# Notification and system tools
system_packages=(
    "mako"
    "SwayNotificationCenter"
    "pamixer"
    "wireplumber"
    "playerctl"
    "light"
    "brightnessctl"
    "polkit-gnome"
)

# Network and bluetooth
network_packages=(
    "NetworkManager-tui"
    "bluez"
    "bluez-tools"
    "blueman"
)

# File management and utilities
utility_packages=(
    "nautilus"
    "udiskie"
    "acpi"
    "fastfetch"
    "wlogout"
)

# Theme and appearance
theme_packages=(
    "qt5ct"
    "qt6ct"
    "kvantum"
    "pavucontrol"
)

print_message info "Installing development dependencies..."
install_packages "${dev_packages[@]}"

print_message info "Installing core Hyprland packages..."
install_packages "${hyprland_packages[@]}"

print_message info "Installing screenshot and clipboard tools..."
install_packages "${screenshot_packages[@]}"

print_message info "Installing system packages..."
install_packages "${system_packages[@]}"

print_message info "Installing network and bluetooth packages..."
install_packages "${network_packages[@]}"

print_message info "Installing utility packages..."
install_packages "${utility_packages[@]}"

print_message info "Installing theme and appearance packages..."
install_packages "${theme_packages[@]}"

print_message success "Hyprland and related packages installed successfully."
