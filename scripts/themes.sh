#!/bin/bash

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/utils.sh"

# GTK settings file
GTK3_SETTINGS="$HOME/.config/gtk-3.0/settings.ini"
GTK4_SETTINGS="$HOME/.config/gtk-4.0/settings.ini"

apply_gtk_settings() {
    local theme="$1"
    local icons="$2"
    local cursor="$3"
    local cursor_size="${4:-24}"

    print_section "Applying GTK settings"

    mkdir -p "$(dirname "$GTK3_SETTINGS")"
    mkdir -p "$(dirname "$GTK4_SETTINGS")"

    local content="[Settings]
gtk-theme-name=${theme}
gtk-icon-theme-name=${icons}
gtk-cursor-theme-name=${cursor}
gtk-cursor-theme-size=${cursor_size}
gtk-font-name=JetBrainsMono Nerd Font 11
"

    echo "$content" > "$GTK3_SETTINGS"
    echo "$content" > "$GTK4_SETTINGS"
    print_message success "GTK3 and GTK4 settings written"
}

apply_cursor_theme() {
    local cursor="$1"
    local cursor_size="${2:-24}"

    print_section "Setting cursor theme"

    # X11 cursor fallback via index.theme
    local cursor_dir="$HOME/.icons/default"
    mkdir -p "$cursor_dir"
    cat > "$cursor_dir/index.theme" <<EOF
[Icon Theme]
Name=Default
Comment=Default cursor theme
Inherits=${cursor}
EOF

    print_message info "Remember to set in hyprland.conf:"
    print_message info "  env = XCURSOR_THEME,${cursor}"
    print_message info "  env = XCURSOR_SIZE,${cursor_size}"

    print_message success "Cursor theme set to: $cursor"
}

apply_kvantum_theme() {
    local theme="$1"

    print_section "Applying Kvantum theme"

    if ! has_cmd kvantummanager; then
        print_message warning "kvantummanager not found, skipping Kvantum setup"
        return 0
    fi

    run_cmd "Setting Kvantum theme: $theme" \
        kvantummanager --set "$theme"

    print_message success "Kvantum theme set to: $theme"
}

update_font_cache() {
    print_section "Updating font cache"
    run_cmd "Refreshing font cache" fc-cache -fv
}

main() {
    setup_logging
    print_header "Themes, Fonts & Cursors"

    apply_gtk_settings \
        "catppuccin-mocha-standard-blue-dark" \
        "Reversal-blue-dark" \
        "catppuccin-mocha-blue-cursors" \
        24

    # X11/Hyprland cursor
    apply_cursor_theme "catppuccin-mocha-blue-cursors" 24

    # Kvantum for Qt apps
    apply_kvantum_theme "Catppuccin-Mocha-Blue"

    # Font cache
    update_font_cache

    print_message success "Themes applied"
    print_message info "Rose Pine Moon GTK theme is also installed — switch via nwg-look or gsettings"
    print_message info "Available cursors: catppuccin-mocha-blue-cursors, catppuccin-mocha-peach-cursors"
}

main "$@"
