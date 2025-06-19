#!/bin/bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$script_dir/utils.sh"

print_message info "Installing applications and themes..."

# Install Firefox (if not already installed)
print_message info "Installing Firefox..."
install_package "firefox"

# Install Google Chrome
print_message info "Installing Google Chrome..."
if ! is_package_installed "google-chrome-stable"; then
    # Add Google Chrome repository
    if [[ ! -f /etc/yum.repos.d/google-chrome.repo ]]; then
        add_repo "google-chrome" "[google-chrome]
        name=google-chrome
        baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
        enabled=1
        gpgcheck=1
        gpgkey=https://dl.google.com/linux/linux_signing_key.pub"
        sudo rpm --import https://dl.google.com/linux/linux_signing_key.pub
    fi

    sudo dnf check-update
    install_package "google-chrome-stable"
else
    print_message warning "Google Chrome is already installed, skipping."
fi
print_message info "Installing Visual Studio Code..."

if ! is_package_installed "code"; then
    # Add Microsoft repository
    if [[ ! -f /etc/yum.repos.d/vscode.repo ]]; then
        sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
        add_repo "vscode" "[code]
        name=Visual Studio Code
        baseurl=https://packages.microsoft.com/yumrepos/vscode
        enabled=1
        autorefresh=1
        type=rpm-md
        gpgcheck=1
        gpgkey=https://packages.microsoft.com/keys/microsoft.asc"
    fi
    
    sudo dnf check-update
    install_package "code"
else
    print_message warning "Visual Studio Code is already installed, skipping."
fi

print_message info "Installing Zen Browser..."
enable_copr "sneexy/zen-browser"
install_package "zen-browser"

# Install Catppuccin GTK theme
print_message info "Installing Catppuccin GTK theme..."
themes_dir="$HOME/.themes"
mkdir -p "$themes_dir"

catppuccin_theme_dir="$themes_dir/Catppuccin-Mocha"
if [[ ! -d "$catppuccin_theme_dir" ]]; then
    temp_dir=$(mktemp -d)
    cd "$temp_dir"

    if safe_download "https://github.com/catppuccin/gtk/releases/latest/download/Catppuccin-Mocha-Standard-Peach-Dark.zip" "catppuccin-gtk.zip"; then
        unzip -q catppuccin-gtk.zip
        mv Catppuccin-* "$catppuccin_theme_dir"
        print_message success "Catppuccin GTK theme installed."
    fi

    cd - >/dev/null
    rm -rf "$temp_dir"
else
    print_message warning "Catppuccin GTK theme already installed, skipping."
fi

# Install Catppuccin cursor theme
print_message info "Installing Catppuccin cursor theme..."
icon_dir="$HOME/.local/share/icons"
mkdir -p "$icon_dir"

cursor_theme_dir="$icon_dir/catppuccin-mocha-peach-cursors"
if [[ ! -d "$cursor_theme_dir" ]]; then
    temp_dir=$(mktemp -d)
    cd "$temp_dir"

    if safe_download "https://github.com/catppuccin/cursors/releases/latest/download/catppuccin-mocha-peach-cursors.zip" "catppuccin-cursors.zip"; then
        unzip -q catppuccin-cursors.zip
        mv catppuccin-mocha-peach-cursors "$icon_dir/"
        print_message success "Catppuccin cursor theme installed."
    fi

    cd - >/dev/null
    rm -rf "$temp_dir"
else
    print_message warning "Catppuccin cursor theme already installed, skipping."
fi

print_message info "Installing Reversal icon theme..."
shopt -s nocaseglob nullglob
reversal_dirs=("$icon_dir"/reversal*)
shopt -u nocaseglob nullglob

if [[ ${#reversal_dirs[@]} -eq 0 ]]; then
    temp_dir=$(mktemp -d)
    reversal_dir="$icon_dir/Reversal-icon-theme"
    color_variant="orange"

    if safe_git_clone "https://github.com/yeyushengfan258/Reversal-icon-theme" "$reversal_dir"; then
        cd "$reversal_dir"
        if [[ -x "./install.sh" ]]; then
            ./install.sh -d "$icon_dir" "$color_variant" --unattended
            print_message success "Reversal icon theme installed successfully"
        else
            print_message error "install.sh not found or not executable"
        fi
        cd - >/dev/null
    else
        print_message error "Failed to clone Reversal icon theme repository"
    fi
    rm -rf "$temp_dir"
else
    print_message warning "Reversal icon theme already installed, skipping."
fi

# Install additional applications via Flatpak
print_message info "Installing Flatpak applications..."
flatpak_apps=(
    "com.discordapp.Discord"
    "com.spotify.Client"
)

for app in "${flatpak_apps[@]}"; do
    if ! flatpak list | grep -q "$app"; then
        print_message info "Installing Flatpak app: $app"
        flatpak install flathub "$app" -y
    else
        print_message warning "Flatpak app $app already installed, skipping."
    fi
done

# Configure themes (basic configuration)
print_message info "Configuring themes..."

# Set GTK theme
if command_exists "gsettings"; then
    gsettings set org.gnome.desktop.interface gtk-theme "Catppuccin-Mocha"
    gsettings set org.gnome.desktop.wm.preferences theme "Catppuccin-Mocha"
    gsettings set org.gnome.desktop.interface cursor-theme "catppuccin-mocha-peach-cursors"
    if [[ -d "$icon_dir/Reversal" ]]; then
        gsettings set org.gnome.desktop.interface icon-theme "Reversal"
    fi
    print_message success "GTK and cursor themes configured."
fi

print_message success "Applications and themes installation completed."
