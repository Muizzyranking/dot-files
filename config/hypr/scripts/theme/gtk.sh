#!/usr/bin/env bash

set_gtk_theme() {
    local gtk_theme="$1"
    local icon_theme="$2"
    local cursor_theme="$3"
    local cursor_size="$4"
    local dark_mode="$5"
    local font="$6"

    # Create GTK3 config directory
    mkdir -p ~/.config/gtk-3.0

    cat >~/.config/gtk-3.0/settings.ini <<EOFGTK3
[Settings]
gtk-theme-name=${gtk_theme}
gtk-icon-theme-name=${icon_theme}
gtk-font-name=${font}
gtk-cursor-theme-name=${cursor_theme}
gtk-cursor-theme-size=${cursor_size}
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-application-prefer-dark-theme=${dark_mode}
EOFGTK3

    # Create GTK4 config directory
    mkdir -p ~/.config/gtk-4.0

    cat >~/.config/gtk-4.0/settings.ini <<EOFGTK4
[Settings]
gtk-theme-name=${gtk_theme}
gtk-icon-theme-name=${icon_theme}
gtk-font-name=${font}
gtk-cursor-theme-name=${cursor_theme}
gtk-cursor-theme-size=${cursor_size}
gtk-application-prefer-dark-theme=${dark_mode}
EOFGTK4

    # Generate Qt configs (depends on qt.sh)
    generate_qt_file "$font" "$icon_theme"

    # Set with gsettings for running apps
    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null
        gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null
        gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme" 2>/dev/null
        gsettings set org.gnome.desktop.interface cursor-size "$cursor_size" 2>/dev/null
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null
        gsettings set org.gnome.desktop.interface font-name "$font" 2>/dev/null
        gsettings set org.gnome.desktop.interface monospace-font-name "$font" 2>/dev/null
    fi

    # Set cursor theme in Hyprland
    hyprctl setcursor "$cursor_theme" "$cursor_size"
}
