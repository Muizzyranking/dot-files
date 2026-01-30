#!/usr/bin/env bash

load_defaults() {
    local DEFAULTS_FILE="${HOME}/.config/themes/defaults.json"
    
    if [ -f "$DEFAULTS_FILE" ]; then
        DEFAULT_GTK=$(jq -r '.gtk_theme // "Adwaita-dark"' "$DEFAULTS_FILE")
        DEFAULT_ICON=$(jq -r '.icon_theme // "Reversal"' "$DEFAULTS_FILE")
        DEFAULT_CURSOR=$(jq -r '.cursor_theme // "catppuccin-mocha-dark-cursors"' "$DEFAULTS_FILE")
        DEFAULT_CURSOR_SIZE=$(jq -r '.cursor_size // 24' "$DEFAULTS_FILE")
        DEFAULT_FONT=$(jq -r '.font // "Sans 10"' "$DEFAULTS_FILE")
    else
        # Hardcoded fallbacks if no defaults file exists
        DEFAULT_GTK="Adwaita-dark"
        DEFAULT_ICON="Reversal"
        DEFAULT_CURSOR="catppuccin-mocha-dark-cursors"
        DEFAULT_CURSOR_SIZE=24
        DEFAULT_FONT="Sans 10"
    fi
    
    export DEFAULT_GTK DEFAULT_ICON DEFAULT_CURSOR DEFAULT_CURSOR_SIZE DEFAULT_FONT
}
