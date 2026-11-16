# Palettes

Set `"palette"` in `config.json` to any name below, save, and the shell updates live.
Each one is a file in `palettes/` that holds the 16 colours used everywhere in the shell.

| Name | Style |
|---|---|
| `catppuccin-mocha` | Default. Dark, soft, blue accent. |
| `catppuccin-mocha-mauve` | Mocha with a purple accent. |
| `catppuccin-mocha-peach` | Mocha with a warm peach accent. |
| `catppuccin-macchiato` | Slightly lighter and bluer dark. |
| `catppuccin-frappe` | Muted mid-dark. |
| `catppuccin-latte` | Light theme. The island stays dark. |
| `tokyo-night` | Deep blue-black, electric blue accent. |
| `rose-pine` | Dusky purple, lilac accent. |
| `gruvbox-dark` | Warm retro, yellow accent. |
| `nord` | Cool grey-blue, icy accent. |
| `dracula` | Vivid purple accent. |
| `everforest-dark` | Calm forest green. |
| `kanagawa` | Ink-wash blue and gold. |
| `solarized-dark` | Teal-black, classic blue accent. |
| `oled-black` | Pure black, for OLED screens. |
| `ember-warm` | Warm brown-black with a peach accent. |

## Override one colour

    "palette": "nord",
    "colors": { "accent": "#ebcb8b" }

## Light palettes

For a light palette like `catppuccin-latte`, raise `bar.opacity` and `panels.opacity` to about 0.95 so text stays readable over busy wallpapers.

## Later: one theme for the whole system

These palette files are meant to be the single source of truth. A later phase can read the same file to generate GTK, terminal, Hyprland border and launcher themes, so changing `palette` restyles everything at once.
