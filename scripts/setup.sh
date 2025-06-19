#!/usr/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

print_message info "Starting initial system setup..."

if ! check_system_requirements; then
    exit 1
fi

print_message info "Updating system packages..."
sudo dnf update -y

fedora_version=$(rpm -E %fedora)
print_message info "Detected Fedora version: $fedora_version"

print_message info "Enabling RPM Fusion repositories..."
if ! is_package_installed "rpmfusion-free-release"; then
    sudo dnf install -y \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${fedora_version}".noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${fedora_version}".noarch.rpm
fi

print_message info "Enabling Flathub repository..."
if ! flatpak remote-list | grep -q flathub; then
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

if dnf repolist all | grep -qw '^terra'; then
    echo "Repository 'terra' already exists; skipping repofrompath addition."
else
    dnf install --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra$releasever" terra-release
fi

copr_repos=(
    "atim/lazygit"
    "solopasha/hyprland"
    "erikreider/SwayNotificationCenter"
    "elxreno/jetbrains-mono-fonts"
)

for repo in "${copr_repos[@]}"; do
    enable_copr "$repo"
done

print_message info "Refreshing package cache..."
sudo dnf makecache
sudo dnf check-update
sudo dnf upgrade -y

print_message success "Initial system setup completed."
