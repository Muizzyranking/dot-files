# Setting this up on a machine

This repo is one person's setup (Arch + Hyprland + Quickshell). It is not a
framework and the scripts are written for this machine — read them before
running anything. This page explains what the scripts do, which files are
generated rather than stored here, and what a fresh machine needs by hand.

## The two scripts

`install.sh` (Arch only):

1. installs pacman/AUR packages (`scripts/packages.sh`) — includes
   `quickshell`, `adw-gtk-theme`, `fzf`, `qt5ct`/`qt6ct`, `spicetify-cli` and
   the Nerd Fonts,
2. post-install setup: TPM, zsh as default shell (`scripts/setup.sh`),
3. enables the user services (`scripts/services.sh`),
4. links the dot files with `link.sh all`,
5. enables the Quickshell user service,
6. points spicetify at the shell theme (`spicetify config current_theme
   qs-shell color_scheme qs-shell` + `spicetify apply`).

`link.sh` symlinks `config/<name>` → `~/.config/<name>` (whole directories,
backing up whatever is already there), mirrors `local/` into `~/.local` leaf
by leaf, links `home/.zshrc`, and `--prune` removes dangling links into the
repo. Run a single task with `./link.sh <name>`.

After install, log out and back in (shell change, groups). On the first
Quickshell start the shell re-renders every palette target, so all generated
files appear without you doing anything.

## Files that are NOT in this repo — they are generated

Several configs here import files that do not exist in the repo, because
Quickshell writes them from the current palette. They are gitignored, and on a
new system they appear on the first shell start (or run
`qsctl theme apply`). If you copy one app out of this repo, you need its
template plus its entry in `theming.targets`:

| Generated file | Written from | Who reads it |
|---|---|---|
| `~/.config/hypr/colors.lua` | `templates/hypr.lua` | Hyprland Lua (`dofile` in `env.lua`) |
| `~/.config/nvim/colors.lua` | `templates/nvim.lua` | Neovim (`reload_shell_theme()`) |
| `~/.config/kitty/themes/colors.conf` | `templates/kitty.conf` | kitty `include` |
| `~/.config/tmux/themes/colors.conf` | `templates/tmux.conf` | sourced by `tmux.conf` |
| `~/.config/gtk-3.0/colors.css`, `gtk-4.0/colors.css` | `templates/gtk.css`, `gtk4-colors.css` | `@import`ed by the static `gtk.css` |
| `~/.config/fzf/colors.sh` | `templates/fzf.sh` | sourced by `zsh/env.zsh`, exported as `FZF_DEFAULT_OPTS` |
| `~/.config/oh-my-posh/colors.json` | `templates/oh-my-posh.json` | `~/.local/bin/omp-reload` merges it into `config.omp.json` |
| `~/.config/qt6ct/colors/shell.conf` | `templates/qt6ct.conf` | qt6ct (live via inode watch) |
| `~/.mozilla/firefox/*/chrome/userChrome.css` | `templates/firefox-chrome.css` | Firefox at start |
| `~/.config/spicetify/Themes/qs-shell/color.ini` | `templates/spicetify-color.ini` | spicetify `apply` + restart Spotify |
| `~/.config/opencode/themes/qs-shell.json` | `templates/opencode-theme.json` | opencode at TUI start |
| `~/.config/gtk-*/settings.ini` | written by `extras/system-theme.sh` | GTK |

`~/.config/oh-my-posh/config.omp.json` is also rebuilt on every palette change
(merge of `base.omp.json` + the palette), but it is tracked anyway so a fresh
clone works before the first apply.

## Apps that pick up a palette change

Live, no action: the shell itself, kitty, tmux (and fzf inside tmux, via the
server environment), Neovim, oh-my-posh, qt6ct.

After a restart of the app: GTK 3/4 apps, Chrome, Firefox, opencode, Spotify
(`spicetify apply` runs by itself; restart Spotify). There is no live channel
for these — opencode, for example, reads its theme once at TUI start and
watches nothing (checked the running TUI), so a restart is the only way.

## One-time manual bits a fresh machine needs

- **Chrome**: chrome://settings → Appearance → *Use GTK*, or it paints its own
  fixed dark scheme on every palette.
- **Qt**: `QT_QPA_PLATFORMTHEME=qt6ct` in the environment and
  `theming.system.qt: true` (Hyprland's `env.lua` already sets it).
- **Firefox**: enable `toolkit.legacyUserProfileCustomizations.stylesheets` in
  about:config.
- **Lock screen**: uses PAM; the service file ships with the shell unit.
- Anything not in this repo (browser profile, SSH keys, `~/.local/share`
  data) is outside its scope — back those up with your own tooling.
