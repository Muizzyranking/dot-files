#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

print_message info "Installing Hyprland and related packages..."

print_message info "Enabling COPR repositories..."
sudo dnf copr enable solopasha/hyprland -y
sudo dnf copr enable -y erikreider/SwayNotificationCenter

packages=(
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
    "hyprland"
    "waybar"
    "grim"
    "slurp"
    "wl-clipboard"
    "mako"
    "pamixer"
    "light"
    "polkit-gnome"
    "playerctl"
    "pulseaudio"
    "bluez"
    "bluez-tools"
    "NetworkManager-tui"
    "z-tui"
    "rofi-wayland"
    "udiskie"
    "nautilus"
    "acpi"
    "qt5ct"
    "qgnomeplatform"
    "Kvantum"
    "SwayNotificationCenter"
)

for package in "${packages[@]}"; do
    install_package "$package"
done

print_message success "Hyprland and related packages installed successfully."
