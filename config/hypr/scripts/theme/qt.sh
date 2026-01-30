#!/usr/bin/env bash

generate_qt_colors() {
    local theme_file="$1"
    local colors_dir="$HOME/.config/qt6ct/colors"
    local colors_file="$colors_dir/theme-colors.conf"

    mkdir -p "$colors_dir"

    # Read colors from theme
    local bg=$(jq -r '.colors.background' "$theme_file")
    local fg=$(jq -r '.colors.foreground' "$theme_file")
    local accent=$(jq -r '.colors.accent' "$theme_file")
    local surface=$(jq -r '.colors.surface' "$theme_file")
    local overlay=$(jq -r '.colors.overlay' "$theme_file")
    local red=$(jq -r '.colors.red' "$theme_file")

    # Convert hex to Qt format (add ff prefix for alpha)
    bg_qt="ff${bg#\#}"
    fg_qt="ff${fg#\#}"
    accent_qt="ff${accent#\#}"
    surface_qt="ff${surface#\#}"
    overlay_qt="ff${overlay#\#}"
    red_qt="ff${red#\#}"

    cat >"$colors_file" <<EOFCOLORS
[ColorScheme]
active_colors=#${fg_qt}, #${bg_qt}, #${overlay_qt}, #${surface_qt}, #${overlay_qt}, #${surface_qt}, #${fg_qt}, #${fg_qt}, #${fg_qt}, #${bg_qt}, #${bg_qt}, #${surface_qt}, #${accent_qt}, #${bg_qt}, #${accent_qt}, #${red_qt}, #${bg_qt}, #${fg_qt}, #${bg_qt}, #${fg_qt}, #80${surface_qt}
disabled_colors=#${overlay_qt}, #${bg_qt}, #${overlay_qt}, #${surface_qt}, #${overlay_qt}, #${surface_qt}, #${overlay_qt}, #${overlay_qt}, #${overlay_qt}, #${bg_qt}, #${bg_qt}, #${surface_qt}, #${accent_qt}, #${overlay_qt}, #${accent_qt}, #${red_qt}, #${bg_qt}, #${fg_qt}, #${bg_qt}, #${fg_qt}, #80${surface_qt}
inactive_colors=#${fg_qt}, #${bg_qt}, #${overlay_qt}, #${surface_qt}, #${overlay_qt}, #${surface_qt}, #${fg_qt}, #${fg_qt}, #${fg_qt}, #${bg_qt}, #${bg_qt}, #${surface_qt}, #${accent_qt}, #${overlay_qt}, #${accent_qt}, #${red_qt}, #${bg_qt}, #${fg_qt}, #${bg_qt}, #${fg_qt}, #80${surface_qt}
EOFCOLORS

    echo "$colors_file"
}

generate_qt_file() {
    local font="$1"
    local icon_theme="$2"
    local font_name=$(echo "$font" | sed 's/ [0-9]*$//')
    local font_size=$(echo "$font" | grep -oE '[0-9]+$')
    local COLORS_FILE=$(generate_qt_colors "$THEME_FILE")
    
    mkdir -p "$HOME/.config/qt5ct/colors"
    mkdir -p "$HOME/.config/qt6ct/colors"

    cp "$COLORS_FILE" "$HOME/.config/qt5ct/colors/theme-colors.conf"
    cp "$COLORS_FILE" "$HOME/.config/qt6ct/colors/theme-colors.conf"

    cat >"$HOME/.config/qt5ct/qt5ct.conf" <<EOFQT5
[Appearance]
color_scheme_path=$HOME/.config/qt5ct/colors/theme-colors.conf
custom_palette=true
icon_theme=${icon_theme}
standard_dialogs=default
style=kvantum

[Fonts]
fixed="${font_name},${font_size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
general="${font_name},${font_size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=General, AnimateMenu, AnimateCombo, AnimateTooltip, AnimateToolBox
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
EOFQT5

    cat >"$HOME/.config/qt6ct/qt6ct.conf" <<EOFQT6
[Appearance]
color_scheme_path=$HOME/.config/qt6ct/colors/theme-colors.conf
custom_palette=true
icon_theme=${icon_theme}
standard_dialogs=default
style=kvantum

[Fonts]
fixed="${font_name},${font_size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
general="${font_name},${font_size},-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

[Interface]
activate_item_on_single_click=1
buttonbox_layout=0
cursor_flash_time=1000
dialog_buttons_have_icons=1
double_click_interval=400
gui_effects=General, AnimateMenu, AnimateCombo, AnimateTooltip, AnimateToolBox
keyboard_scheme=2
menus_have_icons=true
show_shortcuts_in_context_menus=true
toolbutton_style=4
underline_shortcut=1
wheel_scroll_lines=3
EOFQT6
}
