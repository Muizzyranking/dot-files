#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

print_message step "Installing Themes & Icons"

THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.local/share/icons"
TEMP_DIR="/tmp/theme_install"

mkdir -p "$THEMES_DIR" "$ICONS_DIR" "$TEMP_DIR"

if ! is_step_complete "theme_gtk"; then
    print_message info "Installing Catppuccin Mocha GTK Theme..."
    URL="https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-peach-standard+default.zip"
    curl -fL "$URL" -o "$TEMP_DIR/gtk.zip"
    unzip -q "$TEMP_DIR/gtk.zip" -d "$TEMP_DIR/gtk"
    mv "$TEMP_DIR/gtk/"* "$THEMES_DIR/"
    mark_step_complete "theme_gtk"
fi

if ! is_step_complete "theme_icons"; then
    print_message info "Installing Reversal Icon Theme..."
    REPO="https://github.com/yeyushengfan258/Reversal-icon-theme.git"
    git clone --depth=1 "$REPO" "$TEMP_DIR/icons"
    bash "$TEMP_DIR/icons/install.sh" -d "$ICONS_DIR" -t orange
    mark_step_complete "theme_icons"
fi

if ! is_step_complete "theme_cursors"; then
    print_message info "Installing Catppuccin Cursors..."
    URL="https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-mocha-peach-cursors.zip"
    curl -fL "$URL" -o "$TEMP_DIR/cursors.zip"
    unzip -q "$TEMP_DIR/cursors.zip" -d "$ICONS_DIR"
    mark_step_complete "theme_cursors"
fi

# Apply themes using gsettings (best effort)
if command_exists gsettings; then
    print_message info "Applying themes via gsettings..."
    gsettings set org.gnome.desktop.interface gtk-theme "catppuccin-mocha-peach-standard+default"
    gsettings set org.gnome.desktop.interface icon-theme "Reversal-orange-dark"
    gsettings set org.gnome.desktop.interface cursor-theme "catppuccin-mocha-peach-cursors"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
fi

rm -rf "$TEMP_DIR"
print_message success "Theme installation complete."
