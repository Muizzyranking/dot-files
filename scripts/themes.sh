#!/bin/bash

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ ! -f "$script_dir/utils.sh" ]]; then
    echo "Error: Utility script not found at $script_dir/utils.sh"
    exit 1
fi

source "$script_dir/utils.sh"


# Theme directories
THEMES_DIR="$HOME/.themes"
ICONS_DIR="$HOME/.local/share/icons"
CURSORS_DIR="$HOME/.local/share/icons"
TEMP_DIR="/tmp/theme_install_$$"

# Theme URLs
CATPPUCCIN_GTK_URL="https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-peach-standard+default.zip"
CATPPUCCIN_CURSOR_URL="https://github.com/catppuccin/cursors/releases/download/v2.0.0/catppuccin-mocha-peach-cursors.zip"
REVERSAL_ICONS_REPO="https://github.com/yeyushengfan258/Reversal-icon-theme.git"

cleanup() {
    print_message info "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
}

# Set up cleanup trap
trap cleanup EXIT

create_directories() {
    print_message info "Creating theme directories..."
    mkdir -p "$THEMES_DIR" "$ICONS_DIR" "$CURSORS_DIR" "$TEMP_DIR"
}

install_dependencies() {
    print_message info "Installing required dependencies..."
    local deps=("unzip" "tar" "git" "curl")
    install_packages "${deps[@]}"
}

check_theme_exists() {
    local theme_name="$1"
    local theme_dir="$2"

    if [[ -d "$theme_dir/$theme_name" ]]; then
        print_message warning "Theme $theme_name already exists in $theme_dir, skipping..."
        return 0
    fi
    return 1
}

install_catppuccin_gtk() {
    print_message info "Installing Catppuccin GTK theme..."

    if check_theme_exists "catppuccin*" "$THEMES_DIR"; then
        return 0
    fi

    local zip_file="$TEMP_DIR/catppuccin-gtk.zip"

    if safe_download "$CATPPUCCIN_GTK_URL" "$zip_file"; then
        cd "$TEMP_DIR" || return 1
        if unzip -q "$zip_file"; then
            local theme_dir
            theme_dir=$(find . -maxdepth 1 -name "catppuccin*" -type d | head -1)
            if [[ -n "$theme_dir" ]]; then
                mv "$theme_dir" "$THEMES_DIR/"
                print_message success "Catppuccin GTK theme installed successfully."
            else
                print_message error "Could not find Catppuccin theme directory after extraction."
                return 1
            fi
        else
            print_message error "Failed to extract Catppuccin GTK theme."
            return 1
        fi
    else
        return 1
    fi
}

install_catppuccin_cursors() {
    print_message info "Installing Catppuccin cursor theme..."

    if check_theme_exists "*catppuccin*cursors*" "$CURSORS_DIR"; then
        return 0
    fi

    local zip_file="$TEMP_DIR/catppuccin-cursors.zip"

    if safe_download "$CATPPUCCIN_CURSOR_URL" "$zip_file"; then
        cd "$TEMP_DIR" || return 1
        if unzip -q "$zip_file"; then
            local cursor_dir
            cursor_dir=$(find . -maxdepth 1 -name "*catppuccin*" -type d | head -1)
            if [[ -n "$cursor_dir" ]]; then
                mv "$cursor_dir" "$CURSORS_DIR/"
                print_message success "Catppuccin cursor theme installed successfully."
            else
                print_message error "Could not find Catppuccin cursor directory after extraction."
                return 1
            fi
        else
            print_message error "Failed to extract Catppuccin cursor theme."
            return 1
        fi
    else
        return 1
    fi
}

install_reversal_icons() {
    print_message info "Installing Reversal icon theme (orange variant)..."

    if check_theme_exists "Reversal-orange*" "$ICONS_DIR"; then
        return 0
    fi

    local icons_repo="$TEMP_DIR/reversal-icons"

    if safe_git_clone "$REVERSAL_ICONS_REPO" "$icons_repo"; then
        cd "$icons_repo" || return 1

        # Make install script executable and run it
        if [[ -f "install.sh" ]]; then
            chmod +x install.sh
            if ./install.sh -d "$ICONS_DIR" -t orange 2>/dev/null; then
                print_message success "Reversal icon theme (orange) installed successfully."
            else
                print_message error "Failed to install Reversal icon theme."
                return 1
            fi
        else
            print_message error "Install script not found in Reversal icon theme repository."
            return 1
        fi
    else
        return 1
    fi
}

main() {
    print_message info "Starting theme installation..."

    # Check system requirements
    if ! check_system_requirements; then
        exit 1
    fi

    # Create necessary directories
    create_directories

    # Install dependencies
    if ! install_dependencies; then
        print_message error "Failed to install dependencies."
        exit 1
    fi

    # Install themes
    local install_errors=0

    print_message info "Installing themes (existing themes will be skipped)..."

    install_catppuccin_gtk || ((install_errors++))
    install_catppuccin_cursors || ((install_errors++))
    install_reversal_icons || ((install_errors++))

    # Show results
    print_message success "Theme installation completed!"

    if ((install_errors > 0)); then
        print_message warning "Some themes failed to install. Check the output above for details."
    fi

    print_message info "\nNext steps:"
    print_message info "1. Run the theme setter script to configure themes"
    print_message info "2. Or use a GUI theme manager like gnome-tweaks"
    print_message info "3. Restart applications for themes to take full effect"
}

main "$@"
