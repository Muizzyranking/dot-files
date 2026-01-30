#!/usr/bin/env bash

CACHE_DIR="${HOME}/.cache/themes"
THEME_DIR="${HOME}/.config/themes"
DEFAULTS_FILE="${THEME_DIR}/defaults.json"
SCRIPT_DIR="${HOME}/.config/hypr/scripts"
THEME_SWITCHER="${SCRIPT_DIR}/theme/switch.sh"

if [ -f "$CACHE_DIR/current_theme" ]; then
    THEME_FILE=$(cat "$CACHE_DIR/current_theme")
    if [ -f "$THEME_FILE" ]; then
        echo "Applying last used theme: $THEME_FILE"
        "$THEME_SWITCHER" "$THEME_FILE"
        exit 0
    fi
fi

echo "No cached theme found, applying default theme"

if [ -f "$DEFAULTS_FILE" ]; then
    "$THEME_SWITCHER" "$DEFAULTS_FILE"
else
    FIRST_THEME=$(find -L "$THEME_DIR" -name "*.json" -type f 2>/dev/null | head -n 1)
    if [ -n "$FIRST_THEME" ]; then
        echo "Using first available theme: $FIRST_THEME"
        "$THEME_SWITCHER" "$FIRST_THEME"
    else
        echo "No themes found! Please create themes in $THEME_DIR"
        notify-send "Theme System" "No themes found." -u critical
    fi
fi
