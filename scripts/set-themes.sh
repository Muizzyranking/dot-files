#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$script_dir/utils.sh" ]]; then
    echo "Error: Utility script not found at $script_dir/utils.sh"
    exit 1
fi

source "$script_dir/utils.sh"

THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.local/share/icons"
CURSORS_DIR="$HOME/.local/share/icons"

# Default theme names (these can be customized)
DEFAULT_GTK_THEME="Catppuccin-Mocha-Standard-Peach-Dark"
DEFAULT_ICON_THEME="Reversal-orange-dark"
DEFAULT_CURSOR_THEME="Catppuccin-Mocha-Peach-Cursors"
DEFAULT_COLOR_SCHEME="prefer-dark"
DEFAULT_CURSOR_SIZE="24"

check_theme_installed() {
    local theme_name="$1"
    local search_dir="$2"

    if find "$search_dir" -maxdepth 1 -name "*${theme_name}*" -type d | grep -q .; then
        return 0
    else
        return 1
    fi
}

find_theme_name() {
    local pattern="$1"
    local search_dir="$2"

    find "$search_dir" -maxdepth 1 -name "*${pattern}*" -type d | head -1 | xargs basename 2>/dev/null
}

check_installed_themes() {
    print_message info "Checking for installed themes..."

    local missing_themes=()

    if ! check_theme_installed "catppuccin" "$THEMES_DIR"; then
        missing_themes+=("GTK themes (Catppuccin)")
    fi

    if ! check_theme_installed "Reversal" "$ICONS_DIR"; then
        missing_themes+=("Reversal icon theme")
    fi

    if ! check_theme_installed "catppuccin" "$CURSORS_DIR"; then
        missing_themes+=("Catppuccin cursor theme")
    fi

    if [[ ${#missing_themes[@]} -gt 0 ]]; then
        print_message warning "Missing themes detected:"
        for theme in "${missing_themes[@]}"; do
            print_message warning "  - $theme"
        done
        print_message info "Run the theme installer script first to install missing themes."
        return 1
    fi
    print_message success "All required themes found!"
    return 0
}

set_system_themes() {
    print_message info "Setting system themes via gsettings..."

    if ! command_exists gsettings; then
        print_message warning "gsettings not available. Install gtk3 or gnome-settings-daemon."
        return 1
    fi

    # Find actual theme names
    local gtk_theme=$(find_theme_name "catppuccin" "$THEMES_DIR")
    local icon_theme=$(find_theme_name "Reversal" "$ICONS_DIR")
    local cursor_theme=$(find_theme_name "catppuccin" "$CURSORS_DIR")

    gtk_theme=${gtk_theme:-$DEFAULT_GTK_THEME}
    icon_theme=${icon_theme:-$DEFAULT_ICON_THEME}
    cursor_theme=${cursor_theme:-$DEFAULT_CURSOR_THEME}

    gsettings set org.gnome.desktop.interface color-scheme "$DEFAULT_COLOR_SCHEME" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size "$DEFAULT_CURSOR_SIZE" 2>/dev/null || true
    print_message success "System themes configured via gsettings."
}

setup_flatpak_themes() {
    print_message info "Configuring Flatpak theme access..."

    if command_exists flatpak; then
        flatpak override --user --filesystem=~/.themes:ro 2>/dev/null || true
        flatpak override --user --filesystem=~/.local/share/icons:ro 2>/dev/null || true
        flatpak override --user --filesystem=~/.local/share/themes:ro 2>/dev/null || true

        print_message success "Flatpak theme access configured."
        print_message info "Restart Flatpak applications for themes to take effect."
    else
        print_message warning "Flatpak not found. Skipping Flatpak configuration."
    fi
}

show_configuration_info() {
    print_message success "Theme configuration completed!"
    print_message info "\nConfiguration files created:"
    print_message info "\nFor Chromium-based browsers:"
    print_message info "  1. Enable 'Use system title bar and borders' in Settings > Appearance"
    print_message info "  2. Set Theme to 'GTK+' or 'System'"
    print_message info "  3. Restart browser for full effect"

    print_message info "\nNext steps:"
    print_message info "  2. Restart applications for themes to take effect"
    print_message info "  3. Use gnome-tweaks or similar for fine-tuning"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -s, --set          Set themes (default action)"
    echo "  -r, --reset        Reset theme configuration"
    echo "  -c, --check        Check for installed themes only"
    echo "  -h, --help         Show this help"
    echo ""
}

main() {
    local action="set"

    while [[ $# -gt 0 ]]; do
        case $1 in
        -s | --set)
            action="set"
            shift
            ;;
        -c | --check)
            action="check"
            shift
            ;;
        -h | --help)
            show_usage
            exit 0
            ;;
        *)
            print_message error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        esac
    done

    print_message info "Theme setter for Fedora Linux..."

    case $action in
    "check")
        check_installed_themes
        exit $?
        ;;
    "set")
        if ! check_installed_themes; then
            exit 1
        fi

        set_system_themes
        setup_flatpak_themes
        show_configuration_info
        ;;
    esac
}

main "$@"
