#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="${HOME}/.config/themes"
CACHE_DIR="${HOME}/.cache/themes"
DEFAULTS_FILE="${THEME_DIR}/defaults.json"

mkdir -p "$CACHE_DIR"

source "${SCRIPT_DIR}/defaults.sh"
source "${SCRIPT_DIR}/qt.sh"
source "${SCRIPT_DIR}/kitty.sh"
source "${SCRIPT_DIR}/gtk.sh"
source "${SCRIPT_DIR}/kvantum.sh"
source "${SCRIPT_DIR}/hyprland.sh"
source "${SCRIPT_DIR}/wallpaper.sh"

# Function to apply theme
apply_theme() {
    local THEME_FILE="$1"

    if [ ! -f "$THEME_FILE" ]; then
        echo "Theme file not found: $THEME_FILE"
        notify-send "Theme Error" "Theme file not found" -u critical
        exit 1
    fi

    load_defaults

    THEME_NAME=$(jq -r '.name' "$THEME_FILE")
    WALLPAPER=$(jq -r '.wallpaper' "$THEME_FILE")
    WALLPAPER="${WALLPAPER/#\~/$HOME}"
    GTK_THEME=$(jq -r ".gtk_theme // \"$DEFAULT_GTK\"" "$THEME_FILE")
    ICON_THEME=$(jq -r ".icon_theme // \"$DEFAULT_ICON\"" "$THEME_FILE")
    CURSOR_THEME=$(jq -r ".cursor_theme // \"$DEFAULT_CURSOR\"" "$THEME_FILE")
    CURSOR_SIZE=$(jq -r ".cursor_size // \"$DEFAULT_CURSOR_SIZE\"" "$THEME_FILE")
    KVANTUM_THEME=$(jq -r '.kvantum_theme // ""' "$THEME_FILE")
    DARK_MODE=$(jq -r '.dark_mode // "1"' "$THEME_FILE")
    FONT=$(jq -r ".font // \"$DEFAULT_FONT\"" "$THEME_FILE")

    jq -r '.colors | to_entries[] | "export COLOR_\(.key | ascii_upcase)=\"\(.value)\""' "$THEME_FILE" >"$CACHE_DIR/current_theme.sh"
    source "$CACHE_DIR/current_theme.sh"

    jq -r '.colors' "$THEME_FILE" >"$CACHE_DIR/colors.json"
    jq -r '.colors | to_entries[] | "\(.key)=\"\(.value)\""' "$THEME_FILE" >"$CACHE_DIR/colors.sh"

    echo "FONT=\"$FONT\"" >"$CACHE_DIR/font.sh"

    echo "Applying theme: $THEME_NAME"
    
    set_gtk_theme "$GTK_THEME" "$ICON_THEME" "$CURSOR_THEME" "$CURSOR_SIZE" "$DARK_MODE" "$FONT"
    set_kvantum_theme "$KVANTUM_THEME"
    generate_kitty_theme "$THEME_FILE"
    set_wallpaper "$WALLPAPER"
    generate_hyprland_colors "$THEME_FILE" "$THEME_NAME" "$FONT"

    echo "$THEME_FILE" >"$CACHE_DIR/current_theme"
    
    echo "Theme applied successfully!"
}

if [ -n "$1" ]; then
    apply_theme "$1"
else
    THEMES=$(find -L "$THEME_DIR" -name "*.json" -type f 2>/dev/null)

    if [ -z "$THEMES" ]; then
        notify-send "No Themes Found" "Create themes in $THEME_DIR" -u critical
        exit 1
    fi

    SELECTED=$(echo "$THEMES" | while read -r theme; do
        jq -r '.name' "$theme"
    done | sort | rofi -dmenu -p "Select Theme" -config ~/.config/rofi/themeswitcher.rasi)

    if [ -n "$SELECTED" ]; then
        THEME_FILE=$(echo "$THEMES" | while read -r theme; do
            if [ "$(jq -r '.name' "$theme")" = "$SELECTED" ]; then
                echo "$theme"
            fi
        done)
        apply_theme "$THEME_FILE"
    fi
fi
