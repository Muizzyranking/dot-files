# Theming every app from one palette

Your palette is a set of colours. Every app wants colours in its own format, so the shell turns the palette into each format, writes the file where that app looks for it, and tells the app to reload. A second step sets the system-wide GTK theme, cursor and Qt style.

Switch palettes from the control center (Palette tile), from Settings, with `qsctl theme set <name>`, or by editing `palette` in `config.json`.

## How it works

1. `palettes/<name>.json` holds the colours (plus an optional `system` block with the matching cursor theme).
2. `templates/` has one file per format with placeholders like `{{accent}}`.
3. `theming.targets` in `config.json` says which template goes to which path, and how to reload the app.
4. `theming.system` controls the GTK theme, icons, cursor and Qt style (runs `extras/theme.sh`).
5. With `"theming.enabled": true`:
   - files that do not exist yet are created when the shell starts,
   - when the palette changes, every target is rewritten and reloaded,
   - `qsctl theme apply` rewrites everything on demand.
   A target that is a symlink is replaced by a real file, so a downloaded theme is never modified. A target path may contain `*` (used for the Firefox profile folder).

## Placeholders

`{{bg}} {{panel}} {{surface}} {{surfaceHi}} {{island}} {{fg}} {{fgBright}} {{fgDim}} {{fgFaint}} {{accent}} {{onAccent}} {{good}} {{warn}} {{warm}} {{bad}} {{redAlt}} {{info}} {{blue}} {{purple}} {{magenta}} {{cyan}} {{foam}} {{diffAdd}} {{diffChange}} {{diffDelete}} {{diffText}} {{contrast}}`

- Add `.hex` for the value without `#` (`{{accent.hex}}`) or `.rgb` for `r, g, b`.
- `{{name}}` is the palette name, `{{mode}}` is `dark` or `light`.
- `{{contrast}}` is the palette colour whose hue is furthest from the accent. It is used where "active" and "inactive" must never look alike.
- A palette that does not define `blue`, `purple`, `magenta`, `cyan` or `foam` gets them derived. The Catppuccin palettes define all of them.

## Targets to add

Put these in `theming.targets` (keep the ones you already have):

    { "template": "tmux.conf", "out": "~/.config/tmux/tmux/colors.conf", "reload": "tmux source-file ~/.config/tmux/tmux.conf" },
    { "template": "nvim.lua", "out": "~/.config/nvim/lua/shell-colors.lua", "reload": "" },
    { "template": "firefox-chrome.css", "out": "~/.mozilla/firefox/*.default*/chrome/userChrome.css", "reload": "" },
    { "template": "hyprland.lua", "out": "~/.config/hypr/colors.lua", "reload": "hyprctl reload" }

and the system block:

    "system": {
      "enabled": true,
      "gtkTheme": "adw-gtk3",
      "gtkThemeDark": "adw-gtk3-dark",
      "icons": "Reversal-blue-dark",
      "cursor": "auto",
      "cursorSize": 24,
      "font": "JetBrainsMono Nerd Font 11",
      "qt": false,
      "cleanGtk": true
    }

Each of these is also editable in Settings (open it from the control center).

## GTK, Chrome, Spotify and the cursor

A downloaded GTK theme draws everything with its own fixed colours, so the palette never shows. The shell needs a theme that reads named colours: **adw-gtk3** (Arch package `adw-gtk-theme`).

With `theming.system.enabled` the shell then:
- writes `~/.config/gtk-3.0/settings.ini` and `gtk-4.0/settings.ini`,
- sets GSettings (`gtk-theme`, `icon-theme`, `cursor-theme`, `cursor-size`, `font-name`, `color-scheme`) which Chrome, Electron apps and libadwaita read,
- makes `gtk.css` import `shell-colors.css` and removes symlinks a downloaded theme left behind (with `cleanGtk`, `gtk-dark.css` and `assets` are moved to `shell-backup/`),
- sets the cursor and tells Hyprland (`hyprctl setcursor`).

**Spotify cursor vanished?** The cursor theme must be set in GSettings as well as in `settings.ini`. Apps that start reading GSettings otherwise fall back to a cursor theme that may not be installed. The system script sets both.

**Chrome:** in Chrome open Settings, Appearance and choose the GTK theme option (not Classic). Chrome then takes its frame and toolbar colours from the GTK theme, so it shows the palette once adw-gtk3 is active. Restart Chrome after the first run.

**Cursor colours:** a cursor theme is a set of pre-drawn images, so a palette cannot recolour it on the fly. Catppuccin ships one cursor theme per accent colour (`catppuccin-mocha-peach-cursors`, `catppuccin-mocha-blue-cursors`, ...), so each Catppuccin palette names its matching cursor in its `system` block and `"cursor": "auto"` picks it. Install the whole set once (AUR `catppuccin-cursors-mocha`). Palettes without a `system.cursor` keep your current cursor. To pin one cursor whatever the palette, set `cursor` to its name. Recolouring arbitrary cursors would mean re-rendering them from SVG sources, which is possible later.

## Removing the old themes

Once the system script is on, the downloaded themes are no longer used. You can remove them:
- GTK theme: `pacman -Rns` the package you installed it with, or delete `~/.themes/catppuccin-*` and `~/.local/share/themes/catppuccin-*`.
- Kvantum: not needed if you use Fusion through qt6ct (below). `kvantummanager` and its themes can go.
- Keep the cursor theme and icon theme, those are still used.
Your old `gtk.css`, `gtk-dark.css` and `assets` are backed up in `~/.config/gtk-4.0/shell-backup/`.

## Qt and Kvantum

A Kvantum theme is a `.kvconfig` plus an `.svg` with every widget colour baked in, so a palette cannot recolour it. To follow the palette instead:
- install `qt6ct` (and `qt5ct`), set `QT_QPA_PLATFORMTHEME=qt6ct` in Hyprland's environment, and remove `QT_STYLE_OVERRIDE=kvantum` if you set it,
- set `theming.system.qt` to `true`. The shell then configures qt6ct for the Fusion style with the palette (`templates/qt6ct.conf`, add a target writing it to `~/.config/qt6ct/colors/shell.conf`).
Widgets are plainer than Kvantum but always match. This export is experimental.

## tmux

`templates/tmux.conf` writes the variables your tmux setup reads (`WINDOW_BG`, `INDICATOR_ACTIVE_BG`, ...). Active windows use the accent, inactive ones use `{{contrast}}`, a colour far from the accent in hue, so the two are easy to tell apart. `source-file` it before your formats; the reload command refreshes running sessions.

## Neovim

`templates/nvim.lua` writes `_G.COLORS` with the same names your highlight setup uses (`fg`, `fg_bright`, `fg_dim`, `fg_dimmer`, `bg_dark`, `surface`, `surface_light`, `red`, `red_alt`, `orange`, `green`, `blue`, `cyan`, `foam`, `purple`, `magenta`, `error`, `warning`, `info`, `hint`, `none`) plus `diff_add`, `diff_change`, `diff_delete`, `diff_text`. Load it before your fallback table:

    pcall(require, "shell-colors")
    local c = vim.tbl_extend("keep", _G.COLORS or {}, fallback)

To update open Neovim windows when the palette changes, watch the file and re-apply:

    local path = vim.fn.stdpath("config") .. "/lua/shell-colors.lua"
    local w = vim.uv.new_fs_event()
    w:start(path, {}, vim.schedule_wrap(function()
        package.loaded["shell-colors"] = nil
        pcall(require, "shell-colors")
        apply_highlights(vim.tbl_extend("keep", _G.COLORS or {}, fallback))
    end))

## Firefox

`templates/firefox-chrome.css` colours the Firefox interface. In `about:config` set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true` and restart Firefox. The `*` in the target path finds your profile folder. Firefox changes its internal styling now and then, so treat this as best-effort.

## Hyprland (Lua)

`templates/hyprland.lua` writes `_G.COLORS = { ... }` with Material-style names (`primary`, `outline`, `error`, ...) and the shell's own names, as `"rgb(rrggbb)"` strings. Load it with `dofile(os.getenv("HOME") .. "/.config/hypr/colors.lua")` before you use `COLORS`.

## Adding another app

1. Copy any file in `templates/`, rename it, and write the app's format using the placeholders.
2. Add an entry to `theming.targets`.
3. Run `qsctl theme apply`.

`colors.json` is exported too (to `~/.local/state/qs-shell/colors.json`), so any script can read the current colours.

## Honest limits

- Colours only: shapes, spacing and fonts stay with each app.
- Not every running app reloads live. Terminals and tmux usually do, GTK and Qt apps often need a restart.
- Apps that want 16 terminal colours get derived ones.
