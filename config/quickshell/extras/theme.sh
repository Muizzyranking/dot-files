#!/bin/sh
# Applies the system-wide appearance: GTK 3/4 settings, GSettings (what Chrome, Electron
# apps like Spotify and libadwaita apps read), the cursor, and optionally Qt (qt6ct).
# The shell runs this when the palette changes (theming.system in config.json).
# It reads its settings from environment variables set by the shell:
#   SHELL_MODE dark|light, SHELL_GTK_THEME, SHELL_ICONS, SHELL_CURSOR, SHELL_CURSOR_SIZE,
#   SHELL_FONT, SHELL_QT (1 to configure qt6ct/qt5ct), SHELL_QT_COLORS (colour scheme file)
# Empty values are left unchanged. Safe to run again: files are only rewritten when needed,
# and each settings file is backed up once as <file>.shell-bak.

mode="${SHELL_MODE:-dark}"
gtk="${SHELL_GTK_THEME:-}"
icons="${SHELL_ICONS:-}"
cursor="${SHELL_CURSOR:-}"
csize="${SHELL_CURSOR_SIZE:-24}"
font="${SHELL_FONT:-}"

# ini_set FILE SECTION KEY VALUE: set one key, keeping everything else
ini_set() {
    f=$1; sec=$2; key=$3; val=$4
    mkdir -p "$(dirname "$f")"
    [ -f "$f" ] || printf '[%s]\n' "$sec" > "$f"
    [ -e "$f.shell-bak" ] || cp -f "$f" "$f.shell-bak"
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
    ' "$f" > "$f.tmp" && cat "$f.tmp" > "$f"
    rm -f "$f.tmp"
}

dark=0; [ "$mode" = dark ] && dark=1

# GTK 3 and 4 settings files
for v in 3.0 4.0; do
    ini="$HOME/.config/gtk-$v/settings.ini"
    [ -n "$gtk" ]    && ini_set "$ini" Settings gtk-theme-name "$gtk"
    [ -n "$icons" ]  && ini_set "$ini" Settings gtk-icon-theme-name "$icons"
    [ -n "$cursor" ] && ini_set "$ini" Settings gtk-cursor-theme-name "$cursor"
    [ -n "$cursor" ] && ini_set "$ini" Settings gtk-cursor-theme-size "$csize"
    [ -n "$font" ]   && ini_set "$ini" Settings gtk-font-name "$font"
    [ "$v" = 3.0 ] && ini_set "$ini" Settings gtk-application-prefer-dark-theme "$dark"
done

# GTK colours: gtk.css must import shell-colors.css (written by the gtk.css target). Themes that
# were installed by hand often symlink their own gtk.css, gtk-dark.css and assets here, which
# hides ours. Symlinks are removed; with SHELL_GTK_CLEAN=1 real leftovers are moved aside too.
for v in 3.0 4.0; do
    d="$HOME/.config/gtk-$v"
    mkdir -p "$d"
    for f in gtk.css gtk-dark.css assets; do
        [ -L "$d/$f" ] && rm -f "$d/$f"
        if [ "${SHELL_GTK_CLEAN:-}" = 1 ] && [ "$f" != gtk.css ] && [ -e "$d/$f" ]; then
            mkdir -p "$d/shell-backup" && mv "$d/$f" "$d/shell-backup/$f"
        fi
    done
    [ -f "$d/shell-colors.css" ] || : > "$d/shell-colors.css"
    if ! grep -qs 'shell-colors.css' "$d/gtk.css" 2>/dev/null; then
        { printf '@import url("shell-colors.css");\n'; cat "$d/gtk.css" 2>/dev/null; } > "$d/gtk.css.tmp" \
            && cat "$d/gtk.css.tmp" > "$d/gtk.css"
        rm -f "$d/gtk.css.tmp"
    fi
done

# GSettings: Chrome, Electron (Spotify, ...) and libadwaita read these. Set the cursor here too,
# otherwise apps that start reading GSettings fall back to a cursor theme that may not exist
# and the pointer disappears.
if command -v gsettings >/dev/null 2>&1; then
    g() { gsettings set org.gnome.desktop.interface "$1" "$2" 2>/dev/null; }
    [ -n "$gtk" ]    && g gtk-theme "$gtk"
    [ -n "$icons" ]  && g icon-theme "$icons"
    [ -n "$cursor" ] && g cursor-theme "$cursor" && g cursor-size "$csize"
    [ -n "$font" ]   && g font-name "$font"
    g color-scheme "prefer-$mode"
fi

# Cursor: X11 fallback, and Hyprland right now
if [ -n "$cursor" ]; then
    mkdir -p "$HOME/.icons/default"
    printf '[Icon Theme]\nName=Default\nComment=Default cursor theme\nInherits=%s\n' "$cursor" > "$HOME/.icons/default/index.theme"
    command -v hyprctl >/dev/null 2>&1 && hyprctl setcursor "$cursor" "$csize" >/dev/null 2>&1
fi

# Qt through qt6ct / qt5ct: Fusion style with the shell's colour scheme
if [ "${SHELL_QT:-}" = 1 ]; then
    for q in qt6ct qt5ct; do
        conf="$HOME/.config/$q/$q.conf"
        ini_set "$conf" Appearance style Fusion
        ini_set "$conf" Appearance custom_palette true
        [ -n "${SHELL_QT_COLORS:-}" ] && ini_set "$conf" Appearance color_scheme_path "$SHELL_QT_COLORS"
        [ -n "$icons" ] && ini_set "$conf" Appearance icon_theme "$icons"
    done
fi
exit 0
