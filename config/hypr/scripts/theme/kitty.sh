#!/usr/bin/env bash

generate_kitty_theme() {
    local theme_file="$1"
    local kitty_target="$HOME/.config/kitty/theme.conf"
    local kitty_themes_dir="$HOME/.config/kitty/themes"

    local app_theme=$(jq -r '.apps.kitty // empty' "$theme_file")

    if [ -n "$app_theme" ]; then
        local source_file=""
        if [[ "$app_theme" == ~* || "$app_theme" == /* ]]; then
            source_file="${app_theme/#\~/$HOME}"
        else
            source_file="$kitty_themes_dir/$app_theme"
        fi

        if [ -f "$source_file" ]; then
            echo "Applying pre-made Kitty theme: $source_file"
            cp "$source_file" "$kitty_target"
        else
            echo "Warning: Kitty theme file not found at $source_file. Falling back to generation."
            app_theme="" # Trigger fallback
        fi
    fi

    if [ -z "$app_theme" ]; then
        echo "Generating Kitty theme from palette..."
        local bg=$(jq -r '.colors.background' "$theme_file")
        local fg=$(jq -r '.colors.foreground' "$theme_file")
        local acc=$(jq -r '.colors.accent' "$theme_file")

        cat >"$kitty_target" <<EOFKITTY
## Generated from Palette
background $bg
foreground $fg
cursor $fg
selection_background $acc
selection_foreground $bg
active_tab_background $acc
active_tab_foreground $bg
# ANSI Colors
color0 $(jq -r '.colors.black' "$theme_file")
color1 $(jq -r '.colors.red' "$theme_file")
color2 $(jq -r '.colors.green' "$theme_file")
color3 $(jq -r '.colors.yellow' "$theme_file")
color4 $(jq -r '.colors.blue' "$theme_file")
color5 $(jq -r '.colors.magenta' "$theme_file")
color6 $(jq -r '.colors.cyan' "$theme_file")
color7 $(jq -r '.colors.white' "$theme_file")
EOFKITTY
    fi

    pkill -USR1 kitty 2>/dev/null
}
