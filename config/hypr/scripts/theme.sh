#!/usr/bin/env bash

set -uo pipefail

THEME_NAME="Catppuccin"

COLOR_BACKGROUND="#1e1e2e"
COLOR_FOREGROUND="#cdd6f4"
COLOR_BLACK="#45475a"
COLOR_RED="#f38ba8"
COLOR_GREEN="#a6e3a1"
COLOR_YELLOW="#f9e2af"
COLOR_BLUE="#89b4fa"
COLOR_MAGENTA="#f5c2e7"
COLOR_CYAN="#94e2d5"
COLOR_WHITE="#bac2de"
COLOR_ACCENT="#89b4fa"
COLOR_SURFACE="#313244"
COLOR_OVERLAY="#6c7086"

WALLPAPER="${HOME}/Pictures/wallpapers/3d-model.jpg"
APPLY_WALLPAPER=false
WALLPAPER_CMD='swww img "$WALLPAPER"'

GTK_THEME="catppuccin-mocha-blue-standard+default"
ICON_THEME="Reversal"
CURSOR_THEME="catppuccin-mocha-blue-cursors"
CURSOR_SIZE=24
KVANTUM_THEME="Catppuccin-Mocha-Blue"
DARK_MODE=1
FONT="JetBrainsMono Nerd Font 10"

GTK3_DIR="${HOME}/.config/gtk-3.0"
GTK4_DIR="${HOME}/.config/gtk-4.0"
QT5CT_DIR="${HOME}/.config/qt5ct"
QT6CT_DIR="${HOME}/.config/qt6ct"
KVANTUM_DIR="${HOME}/.config/Kvantum"

set_gtk_theme() {
    local gtk_dark="false"
    [ "$DARK_MODE" = "1" ] || [ "$DARK_MODE" = "true" ] && gtk_dark="true"

    mkdir -p "$GTK3_DIR"
    cat >"$GTK3_DIR/settings.ini" <<EOFGTK3
[Settings]
gtk-theme-name=${GTK_THEME}
gtk-icon-theme-name=${ICON_THEME}
gtk-font-name=${FONT}
gtk-cursor-theme-name=${CURSOR_THEME}
gtk-cursor-theme-size=${CURSOR_SIZE}
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-event-sounds=1
gtk-enable-input-feedback-sounds=1
gtk-xft-antialias=1
gtk-xft-hinting=1
gtk-xft-hintstyle=hintfull
gtk-application-prefer-dark-theme=${gtk_dark}
EOFGTK3

    mkdir -p "$GTK4_DIR"
    cat >"$GTK4_DIR/settings.ini" <<EOFGTK4
[Settings]
gtk-theme-name=${GTK_THEME}
gtk-icon-theme-name=${ICON_THEME}
gtk-font-name=${FONT}
gtk-cursor-theme-name=${CURSOR_THEME}
gtk-cursor-theme-size=${CURSOR_SIZE}
gtk-application-prefer-dark-theme=${gtk_dark}
EOFGTK4

    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface gtk-theme "$GTK_THEME" 2>/dev/null
        gsettings set org.gnome.desktop.interface icon-theme "$ICON_THEME" 2>/dev/null
        if [ "$gtk_dark" = "true" ]; then
            gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null
        else
            gsettings set org.gnome.desktop.interface color-scheme "default" 2>/dev/null
        fi
        gsettings set org.gnome.desktop.interface font-name "$FONT" 2>/dev/null
        gsettings set org.gnome.desktop.interface monospace-font-name "$FONT" 2>/dev/null
    fi

    if command -v hyprctl &>/dev/null; then
        hyprctl setcursor "$CURSOR_THEME" "$CURSOR_SIZE" 2>/dev/null
    fi
}

set_kvantum_theme() {
    [ -z "$KVANTUM_THEME" ] && return
    mkdir -p "$KVANTUM_DIR"
    cat >"$KVANTUM_DIR/kvantum.kvconfig" <<EOFKV
[General]
theme=${KVANTUM_THEME}
EOFKV
}

set_qt_theme() {
    local colors_dir="$QT6CT_DIR/colors"
    local colors_file="$colors_dir/theme-colors.conf"
    mkdir -p "$colors_dir"

    local bg_qt="ff${COLOR_BACKGROUND#\#}" fg_qt="ff${COLOR_FOREGROUND#\#}"
    local accent_qt="ff${COLOR_ACCENT#\#}" surface_qt="ff${COLOR_SURFACE#\#}"
    local overlay_qt="ff${COLOR_OVERLAY#\#}" red_qt="ff${COLOR_RED#\#}"

    cat >"$colors_file" <<EOFCOLORS
[ColorScheme]
active_colors=#${fg_qt}, #${bg_qt}, #${overlay_qt}, #${surface_qt}, #${overlay_qt}, #${surface_qt}, #${fg_qt}, #${fg_qt}, #${fg_qt}, #${bg_qt}, #${bg_qt}, #${surface_qt}, #${accent_qt}, #${bg_qt}, #${accent_qt}, #${red_qt}, #${bg_qt}, #${fg_qt}, #${bg_qt}, #${fg_qt}, #80${surface_qt}
disabled_colors=#${overlay_qt}, #${bg_qt}, #${overlay_qt}, #${surface_qt}, #${overlay_qt}, #${surface_qt}, #${overlay_qt}, #${overlay_qt}, #${overlay_qt}, #${bg_qt}, #${bg_qt}, #${surface_qt}, #${accent_qt}, #${overlay_qt}, #${accent_qt}, #${red_qt}, #${bg_qt}, #${fg_qt}, #${bg_qt}, #${fg_qt}, #80${surface_qt}
inactive_colors=#${fg_qt}, #${bg_qt}, #${overlay_qt}, #${surface_qt}, #${overlay_qt}, #${surface_qt}, #${fg_qt}, #${fg_qt}, #${fg_qt}, #${bg_qt}, #${bg_qt}, #${surface_qt}, #${accent_qt}, #${overlay_qt}, #${accent_qt}, #${red_qt}, #${bg_qt}, #${fg_qt}, #${bg_qt}, #${fg_qt}, #80${surface_qt}
EOFCOLORS

    local font_name font_size
    font_name=$(echo "$FONT" | sed 's/ [0-9]*$//')
    font_size=$(echo "$FONT" | grep -oE '[0-9]+$')

    mkdir -p "$QT5CT_DIR/colors" "$QT6CT_DIR/colors"
    cp "$colors_file" "$QT5CT_DIR/colors/theme-colors.conf"
    cp "$colors_file" "$QT6CT_DIR/colors/theme-colors.conf"

    for dir in "$QT5CT_DIR" "$QT6CT_DIR"; do
        local ver=5
        [ "$dir" = "$QT6CT_DIR" ] && ver=6
        cat >"$dir/qt${ver}ct.conf" <<EOFQT
[Appearance]
color_scheme_path=${dir}/colors/theme-colors.conf
custom_palette=true
icon_theme=${ICON_THEME}
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
EOFQT
    done
}

set_wallpaper() {
    [ "$APPLY_WALLPAPER" != true ] && return
    [ -z "$WALLPAPER" ] && return
    if [ ! -f "$WALLPAPER" ]; then
        echo "Wallpaper file not found: $WALLPAPER"
        return
    fi
    eval "$WALLPAPER_CMD" 2>/dev/null
}

echo "Applying theme: $THEME_NAME"
set_gtk_theme
set_qt_theme
set_kvantum_theme
set_wallpaper
echo "Theme applied successfully!"
