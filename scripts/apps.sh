#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

check_fedora
check_internet

print_message step "Installing Applications"

if ! is_step_complete "apps_browsers"; then
    print_message info "Installing Browsers..."

    # Chrome
    add_repo "google-chrome" "[google-chrome]
        name=google-chrome
        baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
        enabled=1
        gpgcheck=1
        gpgkey=https://dl.google.com/linux/linux_signing_key.pub"
    sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub 2>/dev/null || true
    sudo dnf check-update

    # Brave
    sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc 2>/dev/null || true

    enable_copr "sneexy/zen-browser"
    local browsers=("firefox" "google-chrome-stable" "brave-browser", "zen-browser")
    install_packages "${browsers[@]}"

    mark_step_complete "apps_browsers"
fi

if ! is_step_complete "apps_vscode"; then
    print_message info "Installing VS Code..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null || true
    add_repo "vscode" "[code]
    name=Visual Studio Code
    baseurl=https://packages.microsoft.com/yumrepos/vscode
    enabled=1
    gpgcheck=1
    gpgkey=https://packages.microsoft.com/keys/microsoft.asc"
    install_package code
    mark_step_complete "apps_vscode"
fi

if ! is_step_complete "commununication_apps"; then
    print_message info "Installing Communication Applications..."

    local dnf_apps=("thunderbird" "telegram-desktop")
    local flatpak_apps=("com.slack.Slack", "com.discordapp.Discord")

    install_packages "${dnf_apps[@]}"
    install_flatpaks "${flatpak_apps[@]}"
    mark_step_complete "commununication_apps"
fi

if ! is_step_complete "media"; then
    print_message info "Installing Extra Applications..."
    local dnf_apps=("vlc")
    local flatpak_apps=("com.spotify.Client" "com.discordapp.Discord")

    install_packages "${extra_apps[@]}"

    mark_step_complete "media"
fi

if ! is_step_complete "apps_flatpak"; then
    print_message info "Installing Flatpak Apps..."

    local apps=("com.spotify.Client" "com.discordapp.Discord")

    for app in "${apps[@]}"; do
        install_flatpak "$app"
    done

    mark_step_complete "apps_flatpak"
fi

print_message success "Applications installation complete."
