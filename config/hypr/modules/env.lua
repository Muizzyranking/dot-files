_G.TERMINAL = "kitty"
_G.FILEMANAGER = "thunar"
_G.MENU = "hyprlauncher"
_G.HOME_DIR = os.getenv("HOME")
_G.BROWSER = "google-chrome-stable"
_G.CURSOR = {
	size = "24",
	theme = "catppuccin-mocha-blue-cursors",
}
_G.GTK_THEME = "catppuccin-mocha-blue-standard+default"
_G.COLORS = {
	primary = "#89b4fa",
	outline = "#6c7086",
	error = "#f38ba8",
}

hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

local XDG_DATA_DIRS_OLD = os.getenv("XDG_DATA_DIRS") or ""
hl.env(
	"XDG_DATA_DIRS",
	HOME_DIR
		.. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share:"
		.. XDG_DATA_DIRS_OLD
)

hl.env("XDG_MENU_PREFIX", "plasma-")
hl.env("XCURSOR_SIZE", CURSOR.size)
hl.env("HYPRCURSOR_SIZE", CURSOR.size)
hl.env("HYPRCURSOR_THEME", CURSOR.theme)

hl.env("BROWSER", BROWSER)
hl.env("TERMINAL", TERMINAL)
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_SCALE_FACTOR", "1")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
-- hl.env("QT_STYLE_OVERRIDE", "kvantum")
hl.env("GTK_THEME", GTK_THEME)
