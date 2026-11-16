#!/bin/sh
# Applies the system-wide appearance: GTK 3/4 settings, GSettings (what Chrome, Electron
# apps like Spotify and libadwaita apps read), the cursor, and optionally Qt (qt6ct).
# The shell runs this when the palette changes (theming.system in config.json).
# Settings come from environment variables set by the shell:
#   SHELL_MODE dark|light, SHELL_GTK_THEME (the BASE theme, adw-gtk3 or -dark),
#   SHELL_ICONS, SHELL_CURSOR, SHELL_CURSOR_SIZE, SHELL_FONT,
#   SHELL_QT (1 to configure qt6ct/qt5ct), SHELL_QT_COLORS (colour scheme file)
# Empty values are left unchanged. Nothing is rewritten when it already has the right
# value, because every rewrite makes running apps (Firefox especially) re-theme.
# Each settings file is backed up once as <file>.shell-bak.
#
# Palette COLOURS are not handled here: they are rendered into ~/.config/gtk-*/colors.css
# by a theming target and @imported by the static ~/.config/gtk-*/gtk.css. Running apps
# keep the old colours until restarted; that is accepted.

mode="${SHELL_MODE:-dark}"
gtk="${SHELL_GTK_THEME:-}"
icons="${SHELL_ICONS:-}"
cursor="${SHELL_CURSOR:-}"
csize="${SHELL_CURSOR_SIZE:-24}"
font="${SHELL_FONT:-}"

# ini_set FILE SECTION KEY VALUE: set one key, keeping everything else; no write if unchanged
ini_set() {
    f=$1; sec=$2; key=$3; val=$4
    mkdir -p "$(dirname "$f")"
    [ -f "$f" ] || printf '[%s]\n' "$sec" > "$f"
    tmp="$f.tmp"
    awk -v sec="$sec" -v key="$key" -v val="$val" '
        BEGIN { insec = 0; seen = 0; done = 0 }
        /^\[.*\]/ {
            if (insec && !done) { print key "=" val; done = 1 }
            insec = ($0 == "[" sec "]")
            if (insec) seen = 1
            print; next
        }
        { if (insec && index($0, key "=") == 1) { if (!done) { print key "=" val; done = 1 } next } print }
        END { if (!done) { if (!seen) print "[" sec "]"; print key "=" val } }
    ' "$f" > "$tmp"
    if cmp -s "$tmp" "$f"; then rm -f "$tmp"; return 0; fi
    [ -e "$f.shell-bak" ] || cp -f "$f" "$f.shell-bak"
    cat "$tmp" > "$f"
    rm -f "$tmp"
}

dark=0; [ "$mode" = dark ] && dark=1

# a named theme only exists if its directory exists; writing a missing name
# makes apps fall back to generic icons or stock colours with no warning
theme_ok() {
    [ -d "/usr/share/icons/$1" ] || [ -d "$HOME/.icons/$1" ] || [ -d "$HOME/.local/share/icons/$1" ]
}

# --- GTK colours -------------------------------------------------------------
# The palette colours live in ~/.config/gtk-*/colors.css (rendered by a theming
# target). gtk.css must be a REAL file here, and the base theme must be reachable
# by name: a downloaded theme sometimes symlinks its own gtk.css over it.
for v in 3.0 4.0; do
    [ -L "$HOME/.config/gtk-$v/gtk.css" ] && rm -f "$HOME/.config/gtk-$v/gtk.css"
done

# GTK 3 and 4 settings files
for v in 3.0 4.0; do
    ini="$HOME/.config/gtk-$v/settings.ini"
    [ -n "$gtk" ] && ini_set "$ini" Settings gtk-theme-name "$gtk"
    if [ -n "$icons" ]; then
        if theme_ok "$icons"; then ini_set "$ini" Settings gtk-icon-theme-name "$icons"
        else echo "icons: theme '$icons' is not installed, keeping the current one" >&2; fi
    fi
    if [ -n "$cursor" ]; then
        if theme_ok "$cursor"; then ini_set "$ini" Settings gtk-cursor-theme-name "$cursor"
        else echo "cursor: theme '$cursor' is not installed, keeping the current one" >&2; fi
    fi
    [ -n "$cursor" ] && ini_set "$ini" Settings gtk-cursor-theme-size "$csize"
    [ -n "$font" ]   && ini_set "$ini" Settings gtk-font-name "$font"
    [ "$v" = 3.0 ] && ini_set "$ini" Settings gtk-application-prefer-dark-theme "$dark"
done

# Migration: the shell used to render palette colours into gtk-3.0/shell-colors.css and
# import it from gtk.css; and later assembled themes into ~/.local/share/themes/qs-gtk-*.
# Both are replaced by ~/.config/gtk-*/colors.css now.
for v in 3.0 4.0; do
    d="$HOME/.config/gtk-$v"
    [ -f "$d/gtk.css" ] && sed -i '\|@import url("shell-colors.css");|d' "$d/gtk.css"
    [ -f "$d/shell-colors.css" ] && rm -f "$d/shell-colors.css"
done
rm -rf "$HOME/.local/share/themes"/qs-gtk-*

# GSettings: Chrome, Electron (Spotify, ...) and libadwaita read these.
# Only set what differs, and never unset a theme by writing an empty one.
if command -v gsettings >/dev/null 2>&1; then
    g() {
        cur=$(gsettings get org.gnome.desktop.interface "$1" 2>/dev/null) || return 0
        [ "$cur" = "'$2'" ] || [ "$cur" = "$2" ] || gsettings set org.gnome.desktop.interface "$1" "$2" 2>/dev/null
    }
    [ -n "$gtk" ] && g gtk-theme "$gtk"
    if [ -n "$icons" ] && theme_ok "$icons"; then g icon-theme "$icons"; fi
    if [ -n "$cursor" ] && theme_ok "$cursor"; then g cursor-theme "$cursor"; fi
    [ -n "$cursor" ] && g cursor-size "$csize"
    [ -n "$font" ]   && g font-name "$font"
    g color-scheme "prefer-$mode"
fi

# Cursor: X11 fallback, and Hyprland right now. setcursor always runs: at boot
# Hyprland read the previous session's (possibly stale) colours.lua, so the live
# cursor must be corrected even when the state file already matches.
if [ -n "$cursor" ]; then
    idx="$HOME/.icons/default/index.theme"
    want=$(printf '[Icon Theme]\nName=Default\nComment=Default cursor theme\nInherits=%s\n' "$cursor")
    if [ "$(cat "$idx" 2>/dev/null)" != "$want" ]; then
        mkdir -p "$HOME/.icons/default"; printf '%s\n' "$want" > "$idx"
    fi
    command -v hyprctl >/dev/null 2>&1 && hyprctl setcursor "$cursor" "$csize" >/dev/null 2>&1
    state="$HOME/.local/state/qs-shell/cursor"
    printf '%s' "$cursor $csize" > "$state"
fi

# Qt through qt6ct / qt5ct: Fusion style with the shell's colour scheme. The scheme file
# itself is written by a theming target, in place (same inode): the Qt platform theme
# watches that inode with QFileSystemWatcher, so already open Qt apps recolour live.
if [ "${SHELL_QT:-}" = 1 ]; then
    for q in qt6ct qt5ct; do
        conf="$HOME/.config/$q/$q.conf"
        ini_set "$conf" Appearance style Fusion
        ini_set "$conf" Appearance custom_palette true
        [ -n "${SHELL_QT_COLORS:-}" ] && ini_set "$conf" Appearance color_scheme_path "$SHELL_QT_COLORS"
        [ -n "$icons" ] && theme_ok "$icons" && ini_set "$conf" Appearance icon_theme "$icons"
    done
fi
exit 0
