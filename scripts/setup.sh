#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_fedora
check_internet

print_message step "Starting Initial System Setup"

# 1. Repositories
if ! is_step_complete "setup_repos"; then
    print_message info "Configuring Repositories..."

    fedora_version=$(rpm -E %fedora)
    print_message info "Detected Fedora version: $fedora_version"

    if ! is_package_installed "rpmfusion-free-release"; then
        sudo dnf install -y \
            https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"${fedora_version}".noarch.rpm \
            https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"${fedora_version}".noarch.rpm
    fi

    # Flathub
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # Terra
    if ! dnf repolist all | grep -qw '^terra'; then
        sudo dnf install -y --nogpgcheck --repofrompath "terra,https://repos.fyralabs.com/terra$(rpm -E %fedora)" terra-release
    fi

    # COPRs
    enable_copr "atim/lazygit"
    enable_copr "solopasha/hyprland"
    enable_copr "erikreider/SwayNotificationCenter"

    sudo dnf makecache
    mark_step_complete "setup_repos"
fi

# 2. Updates
if ! is_step_complete "setup_update"; then
    print_message info "Updating system..."
    sudo dnf update -y
    mark_step_complete "setup_update"
    request_reboot
fi

# 3. Multimedia
if ! is_step_complete "setup_media"; then
    print_message info "Installing Multimedia Codecs..."

    sudo dnf swap -y ffmpeg-free ffmpeg --allowerasing

    install_packages \
        gstreamer1-plugins-{bad-*,good-*,base} \
        gstreamer1-plugin-openh264 gstreamer1-libav lame-* \
        ffmpeg-libs libva libva-utils \
        openh264 mozilla-openh264

    sudo dnf group install -y multimedia sound-and-video

    # Firefox Config
    sudo dnf config-manager --set-enabled fedora-cisco-openh264

    mark_step_complete "setup_media"
fi

# 4. System Tweaks
if ! is_step_complete "setup_tweaks"; then
    print_message info "Applying System Tweaks..."

    # Speed up boot
    sudo systemctl disable NetworkManager-wait-online.service 2>/dev/null || true

    # Utilities
    install_packages fuse fuse-libs p7zip p7zip-plugins unrar

    mark_step_complete "setup_tweaks"
fi

# 5. DNS (Cloudflare DoT)
if ! is_step_complete "setup_dns"; then
    print_message info "Configuring Encrypted DNS (Cloudflare)..."

    install_package dnsconfd
    sudo systemctl disable --now systemd-resolved 2>/dev/null || true
    sudo systemctl mask systemd-resolved 2>/dev/null || true
    sudo systemctl enable --now dnsconfd

    sudo mkdir -p /etc/NetworkManager/conf.d
    sudo tee /etc/NetworkManager/conf.d/global-dot.conf >/dev/null <<EOF
[main]
dns=dnsconfd

[global-dns]
resolve-mode=exclusive

[global-dns-domain-*]
servers=dns+tls://1.1.1.1#one.one.one.one
EOF

    sudo systemctl restart NetworkManager
    mark_step_complete "setup_dns"
fi

print_message success "System Setup Complete."
