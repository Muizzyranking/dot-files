# Theming every app from one palette

Your palette is a set of colours. Every app wants colours in its own format, so the shell turns the palette into each format, writes the file where that app looks for it, and tells the app to reload (or leaves the restart to you, where an app cannot reload). A second step sets the system-wide GTK theme, cursor and Qt style.

Switch palettes from the control center (Palette tile), from Settings, with `qsctl theme set <name>`, or by editing `palette` in `config.json`.

The rendered files (`colors.lua`, `colors.css`, `themes/colors.conf`, ...) are generated, so they are gitignored. Adopting one app's theming from here means copying that app's template, adding its entry to `theming.targets`, and making the small change in the app's own config that the section below describes.

## How it works

1. `palettes/<name>.json` holds the colours (plus an optional `system` block with the matching cursor and icon theme and wallpaper).
2. `templates/` has one file per format with placeholders like `{{accent}}`.
3. `theming.targets` in `config.json` says which template goes to which path, and how to reload the app.
4. `theming.system` controls the GTK theme, icons, cursor and Qt style (runs `extras/system-theme.sh`).
5. With `"theming.enabled": true`:
   - when the palette changes, every target is rewritten; files that already match are left untouched,
   - at startup everything is re-rendered once (cheap when it already matches), so files left stale by a crash or a hung render are healed on the next boot,
   - `qsctl theme apply` rewrites everything on demand.
   A target that is a symlink is replaced by a real file, so a downloaded theme is never modified. A target path may contain `*` (used for the Firefox profile folder).

## Placeholders

`{{bg}} {{panel}} {{surface}} {{surfaceHi}} {{island}} {{fg}} {{fgBright}} {{fgDim}} {{fgFaint}} {{accent}} {{onAccent}} {{good}} {{warn}} {{warm}} {{bad}} {{redAlt}} {{info}} {{blue}} {{purple}} {{magenta}} {{cyan}} {{foam}} {{diffAdd}} {{diffChange}} {{diffDelete}} {{diffText}} {{contrast}}`

- Add `.hex` for the value without `#` (`{{accent.hex}}`) or `.rgb` for `r, g, b`.
- `{{name}}` is the palette name, `{{mode}}` is `dark` or `light`.
- `{{cursor}}` is the resolved cursor theme name (see below), `{{cursorSize}}` its size. `templates/hypr.lua` exports both as `_G.CURSOR`, so the Hyprland config starts new apps with the right cursor after a reboot.
- `{{contrast}}` is the palette colour whose hue is furthest from the accent. It is used where "active" and "inactive" must never look alike.
- A palette that does not define `blue`, `purple`, `magenta`, `cyan` or `foam` gets them derived. The Catppuccin palettes define all of them.

## Targets

A target says which template goes to which path, and how to reload the app (empty reload = restart the app yourself). The full list lives in `config.json` and, with the reader of each file, in [`setup.md`](setup.md). A few as they appear there:

    { "template": "tmux.conf", "out": "~/.config/tmux/themes/colors.conf", "reload": "tmux source-file ~/.config/tmux/tmux.conf" },
    { "template": "nvim.lua", "out": "~/.config/nvim/colors.lua", "reload": "for s in \"$XDG_RUNTIME_DIR\"/nvim.*; do ... done" },
    { "template": "firefox-chrome.css", "out": "~/.mozilla/firefox/*.default*/chrome/userChrome.css", "reload": "" },
    { "template": "hypr.lua", "out": "~/.config/hypr/colors.lua", "reload": "hyprctl reload" }

Each target may set `"timeout"` (seconds, default 10): how long the reload command may run. Set it higher for reloads that restart a whole app, like `spicetify apply` (~7s, timeout 40).

and the system block:

    "system": {
      "enabled": true,
      "gtkTheme": "adw-gtk3",
      "gtkThemeDark": "adw-gtk3-dark",
      "icons": "auto",
      "iconsFallback": "Reversal-dark",
      "cursor": "auto",
      "cursorFallback": "breeze_cursors",
      "cursorSize": 24,
      "font": "JetBrainsMono Nerd Font 10",
      "qt": true
    }

`gtkTheme`/`gtkThemeDark` are the **base** GTK themes (installed with the `adw-gtk-theme` package). The palette never changes the name; only colours.css changes.

Each of these is also editable in Settings (open it from the control center).

## GTK, Chrome, Qt: restart apps after a palette change

A downloaded GTK theme draws everything with its own fixed colours, so the palette never shows. The base theme needs to read named colours: **adw-gtk3** (Arch package `adw-gtk-theme`).

Palette colours are NOT baked into a theme anymore — they are plain user CSS, and apps are simply restarted after a palette change:

- the shell renders the colours to `~/.config/gtk-3.0/colors.css` and `~/.config/gtk-4.0/colors.css` (generated, gitignored). Two templates: the GTK3 one is plain `@define-color`s; the GTK4 one adds the libadwaita `:root` accent block, because libadwaita ≥ 1.6 resolves the accent from `:root` — and GTK3 cannot parse `:root` at all, so it must never see it,
- the static `~/.config/gtk-3.0/gtk.css` and `gtk-4.0/gtk.css` are plain `@import url("colors.css")`; the GTK4 file also imports adw-gtk3's own `gtk-4.0/gtk.css` by absolute path, because libadwaita apps ignore `gtk-theme-name`,
- `theming.system.gtkTheme`/`gtkThemeDark` set GSettings `gtk-theme` and `settings.ini` to the **base** theme name (`adw-gtk3` / `adw-gtk3-dark`); it never changes between palettes.

Put hand-written tweaks (shapes, timings, extra rules) in the static `gtk.css` files, below the import. Anything colour-related belongs in the template, not there.

**Restart to see the change:** open GTK apps (and Chrome) keep the palette they started with — that is a GTK limitation, not something the shell fights. When you switch palettes, restart the few apps you care about.

**Chrome:** in Chrome open Settings, Appearance and choose the GTK theme option (not Classic). Chrome then follows the GSettings theme. Restart Chrome after a palette change.

**Qt:** install `qt6ct` (and `qt5ct`), keep `QT_QPA_PLATFORMTHEME=qt6ct` in the environment (your Hyprland `env.lua` already sets it), remove `QT_STYLE_OVERRIDE=kvantum` if you set one, and set `theming.system.qt` to `true`. The qt6ct scheme file (`templates/qt6ct.conf`) is written **in place, keeping its inode**: the Qt platform theme watches that inode with QFileSystemWatcher, so already open Qt apps recolour live. Widgets are plainer than Kvantum but always match.

## The cursor

A cursor theme is a set of pre-drawn images, so a palette cannot recolour it on the fly; it can only switch between installed themes. `theming.system.cursor` decides which:

- `"auto"` (default): the palette's `system.cursor` (or, for the active palette, the `palettes.<name>.cursor` override in `config.json`) is used; Catppuccin ships one cursor per accent (`catppuccin-mocha-blue-cursors`, `catppuccin-mocha-mauve-cursors`, ...) so install the matching package (`catppuccin-cursors-mocha` covers every mocha accent).
- a palette with no cursor entry, and `"auto"` with no match, uses **`cursorFallback`** (`breeze_cursors` by default, installed almost everywhere). Empty leaves the cursor unchanged.
- a pinned name (not `"auto"`) overrides every palette. That is why a pin stops palette switching from working — leave it on `"auto"` unless you want one cursor everywhere.

The cursor is applied through GSettings **and** `settings.ini` (apps that start reading GSettings otherwise fall back to a theme that may not exist and the pointer disappears) and `hyprctl setcursor` for what is on screen right now. After a reboot the Hyprland config needs the name again: `templates/hypr.lua` exports `_G.CURSOR`, and the Hyprland `env.lua` loads `colors.lua` (with a `breeze_cursors` fallback for first boot) before it exports `XCURSOR_*`/`HYPRCURSOR_*`.

## Spotify (spicetify)

The palette is rendered into a spicetify theme: `templates/spicetify-color.ini` goes to `~/.config/spicetify/Themes/qs-shell/color.ini`. Once, switch to it:

    spicetify config current_theme qs-shell color_scheme qs-shell
    spicetify apply

On a palette change the target's reload runs `spicetify apply`, so the installed theme is up to date. **Restart Spotify** to see the new colours; the open client does not reload its theme. `local/share/applications/spotify.desktop` is a plain override that only forces the Wayland backend — no debugging port, no live push.

## Firefox

`templates/firefox-chrome.css` colours the Firefox interface. In `about:config` set `toolkit.legacyUserProfileCustomizations.stylesheets` to `true` and restart Firefox. The `*` in the target path finds your profile folder. Firefox reads `userChrome.css` only at startup, so it does not reload live. Firefox changes its internal styling now and then, so treat this as best-effort.

## tmux

`templates/tmux.conf` writes the palette colours as tmux **user options** (`set -g @WINDOW_BG`, `@INDICATOR_ACTIVE_BG`, ...), and your `~/.config/tmux/themes/custom.conf` reads them in its formats as `#{@WINDOW_BG}`. Formats expand at draw time, so a single `source-file` always shows the current palette — for the automated reload and for running it by hand.

(The previous shell-style assignments (`WINDOW_BG="..."` read as `$WINDOW_BG`) were one reload behind on tmux 3.4+: a config file's `$vars` are expanded before a nested `source-file` runs, so the colours applied lagged one palette switch. If you reference the colours anywhere else, use the `#{@NAME}` form.)

Active windows use the accent, inactive ones use `{{contrast}}`, a colour far from the accent in hue, so the two are easy to tell apart. `source-file ~/.config/tmux/tmux.conf` (or just `themes/custom.conf`) refreshes running sessions.

The template also sets the server's global `FZF_DEFAULT_OPTS` (`set-environment -g`): fzf inside tmux (sessionx and friends) inherits the server environment, which is frozen at server start. Updating it with the palette is what lets sessionx popups change colours without restarting the tmux server.

## Neovim

`templates/nvim.lua` writes `_G.COLORS` with the same names your highlight setup uses (`fg`, `fg_bright`, `fg_dim`, `fg_dimmer`, `bg_dark`, `surface`, `surface_light`, `red`, `red_alt`, `orange`, `green`, `blue`, `cyan`, `foam`, `purple`, `magenta`, `error`, `warning`, `info`, `hint`, `none`) plus `diff_add`, `diff_change`, `diff_delete`, `diff_text`, to `~/.config/nvim/colors.lua`. The colourscheme (`colors/custom.lua`) loads it with `dofile` and falls back to its own table when the file does not exist yet (first boot before the shell has rendered once):

    pcall(dofile, vim.fn.stdpath("config") .. "/colors.lua")
    local c = vim.tbl_extend("keep", _G.COLORS or {}, fallback)

The file also defines `reload_shell_theme()`. The target's reload command calls it over `--remote-expr` in every running instance, so open Neovim windows recolour on a palette change.

## opencode

`templates/opencode-theme.json` is a full opencode V2 theme: every visible colour comes straight from the palette, rendered to `~/.config/opencode/themes/qs-shell.json`. `~/.config/opencode/cli.json` selects it (`"theme": { "name": "qs-shell", "mode": "system" }` — with one mode in the file, `system` always uses it). opencode reads its theme when the TUI starts, so an open session needs a restart after a palette change.

## Hyprland (Lua)

`templates/hypr.lua` writes `_G.COLORS = { ... }` with Material-style names (`primary`, `outline`, `error`, ...) and the shell's own names, as `"rgb(rrggbb)"` strings, plus `_G.CURSOR = { theme, size }`. Load it with `dofile(os.getenv("HOME") .. "/.config/hypr/colors.lua")` before you use `COLORS` (the Hyprland `env.lua` in this repo already does, with a fallback).

## fzf

`templates/fzf.sh` exports `FZF_DEFAULT_OPTS` with palette colours to `~/.config/fzf/colors.sh`. `~/.config/zsh/env.zsh` sources it, so every new shell has it. The reload (`extras/fzf-reload.sh`) sends `USR1` to the registered interactive shells — the same registry the prompt's reload uses — and `config/zsh/oh_my_posh.zsh` re-sources the file in its trap, so open shells pick up a palette change on the next redraw.

## Adding another app

1. Copy any file in `templates/`, rename it, and write the app's format using the placeholders.
2. Add an entry to `theming.targets`.
3. Run `qsctl theme apply`.

`colors.json` is exported too (to `~/.local/state/qs-shell/colors.json`), so any script can read the current colours.

## Honest limits

- Colours only: shapes, spacing and fonts stay with each app (put shapes in the static `~/.config/gtk-3.0/gtk.css`, below the import).
- Firefox reloads on restart only.
- Apps that want 16 terminal colours get derived ones.
- The GTK theme-name flip makes already open GTK apps repaint, but apps that hard-cache (some Electron dialogs) may need a restart once.
