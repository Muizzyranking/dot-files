# My dot files

> [!WARNING]
> **This is my personal setup, written for one machine and one user: me.** It is not a framework, not a product, and not optimised for anyone else's use.
> Do not run `install.sh` or `link.sh` — they install Arch packages, replace files in `$HOME` and set up services the way *I* want.
> You are welcome to read [`docs/`](docs/) to understand how each piece works, and to copy whatever you like into your own setup.

## Showcase

![image](https://muizzyranking.github.io/images/dot_images/home.png)

<details>
<summary>Nvim</summary>

![image](https://muizzyranking.github.io/images/dot_images/nvim.png)

</details>

<details>
<summary>Spotify</summary>

![image](https://muizzyranking.github.io/images/dot_images/spotify.png)

</details>

<details>
<summary>Home Screen</summary>

![image](https://muizzyranking.github.io/images/dot_images/home_with_media.png)

</details>


## Used software

### Base

| Type               | Name                                                  |
| ------------------ | ----------------------------------------------------- |
| OS                 | [Arch (btw)](https://archlinux.org/)                  |
| Window Compositor  | [Hyprland](https://hyprland.org/)                     |
| Bar & Shell        | My own [Quickshell](https://quickshell.outfoxxed.me/) desktop shell ([config/quickshell](config/quickshell)) |
| Terminal           | [kitty](https://github.com/kovidgoyal/kitty)          |
| Shell              | zsh                                                   |
| ZSH Prompt         | [OH My Posh](https://ohmyposh.dev/)                   |

### UI

| Type       | Name                                                                |
| ---------- | ------------------------------------------------------------------- |
| GTK Theme  | [adw-gtk3](https://github.com/lassekongo83/adw-gtk3), recoloured by the shell |
| Icon Theme | [Reversal](https://github.com/yeyushengfan258/Reversal-icon-theme)  |
| Main Font  | [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads) |
| Kitty Font | [Maple Mono](https://github.com/subframe7536/maple-font)            |

### Other

| Type                               | Name                                                                             |
| ---------------------------------- | -------------------------------------------------------------------------------- |
| Text Editor                        | [Neovim](https://neovim.io/)                                                     |
| GTK File Manager                   | Thunar                                                                           |
| Better ls                          | [eza](https://github.com/eza-community/eza)                                      |
| Better cd                          | [zoxide](https://github.com/ajeetdsouza/zoxide)                                  |
| System Info                        | [fastfetch](https://github.com/fastfetch-cli/fastfetch)                          |
| Audio Visualizer                   | [cava](https://github.com/karlstav/cava)                                         |
| Idle Daemon                        | [hypridle](https://github.com/hyprwm/hypridle)                                   |

### Wallpapers

Check out my wallpapers [repository](https://github.com/muizzyranking/images)

## Theming

Everything is driven by hand-maintained palettes in [`config/quickshell/palettes`](config/quickshell/palettes). Switching a palette rewrites, in one go:

- the shell itself (bar, island, panels, launcher, lock screen)
- kitty, tmux and running Neovim windows (reloaded automatically)
- GTK 3/4 apps, Chrome, Qt apps and Spotify — files are rewritten and `spicetify apply` runs, but **these apps are restarted** to pick up a new palette
- the cursor theme and (optionally) icon theme — each palette can bring its own

The shell also exports palette colours to Hyprland, opencode and anything with a template. Guides for each app, why they work the way they do and what to remove if you don't want them: [`docs/theming.md`](docs/theming.md). Every config key is documented in [`docs/config.md`](docs/config.md), and [`docs/setup.md`](docs/setup.md) explains the scripts, which files are generated rather than stored here, and what a fresh machine needs by hand.

## Installation

Not supported, on purpose — see the warning at the top. The scripts exist for me: they install Arch packages, overwrite files in `$HOME` and enable services without asking. [`docs/setup.md`](docs/setup.md) documents what they do, which files are generated rather than stored here, and what a fresh machine needs by hand.
