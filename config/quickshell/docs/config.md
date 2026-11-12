# config.md

`config.json` is the only config file. Edit it, save, and the running shell updates by itself.
If you save a syntax error (a missing comma, say), the shell keeps the last good values and prints a warning.
Do not delete keys: the shell reads every key listed here, so a missing one will cause errors.

## Install and run

    cp -r ./* ~/.config/quickshell/
    qs                      # run the default config
    qs -p ./shell.qml       # or run from this folder

Optional tools, each only needed for its own feature:
`brightnessctl` (brightness and keyboard light), `grim` `slurp` `wl-clipboard` `libnotify` (screenshots), `satty` (annotation), `wf-recorder` (recording), `cliphist` (clipboard history), `libpulse` and `sound-theme-freedesktop` (sounds).

`slurp` is no longer needed: regions are picked with the shell's own selector.

Needs: Quickshell (tested against 0.3.2), the Inter font, Material Symbols Rounded, NetworkManager (nmcli), UPower, PipeWire, BlueZ.

## Sizes

Every size below is a base number. The whole UI is multiplied by `scale`, so use `scale` to shrink or grow everything at once.

| Key | Default | Meaning |
|---|---|---|
| `scale` | 1.0 | Global size multiplier. 0.85 makes everything smaller, 1.2 bigger. |

## font

| Key | Default | Meaning |
|---|---|---|
| `font.family` | JetBrainsMono Nerd Font | Text font. |
| `font.iconFamily` | Material Symbols Rounded | Icon font. |
| `font.size` | 12 | Text size. |
| `font.iconSize` | 16 | Icon size. |
| `font.iconFill` | 0 | Material Symbols fill axis. 0 is outline, 1 is solid icons. |
| `font.iconWeight` | 400 | Material Symbols stroke weight, 100 (thin) to 700 (bold). |

Icon looks to try, no extra install needed if you have the variable font:
- Thin and elegant: `"iconFamily": "Material Symbols Outlined", "iconWeight": 300`
- Solid and friendly: `"iconFamily": "Material Symbols Rounded", "iconFill": 1`
- Sharp and technical: `"iconFamily": "Material Symbols Sharp", "iconWeight": 500`

## bar

| Key | Default | Meaning |
|---|---|---|
| `bar.height` | 38 | Bar height. |
| `bar.opacity` | 0.88 | Bar background opacity, 0 (invisible) to 1 (solid). |
| `bar.radius` | 18 | Bottom corner radius. 0 for square corners. |
| `bar.marginX` | 0 | Space left and right of the bar. Above 0 makes it float. |
| `bar.marginY` | 0 | Space above the bar. When above 0 the bar and the island both float with rounded tops. |
| `bar.outerPadding` | 14 | Space between the bar edge and the first or last item. |
| `bar.spacing` | 8 | Space between pills. |
| `bar.pill.height` | 26 | Pill height. |
| `bar.pill.padding` | 11 | Space inside a pill, left and right. |
| `bar.pill.spacing` | 10 | Space between items in a pill. |
| `bar.pill.opacity` | 1.0 | Pill background opacity. |
| `bar.pill.border` | 1 | Pill outline width. 0 removes it. |

For a blurred bar on Hyprland, add `layerrule = blur, qs-bar` and `layerrule = ignorealpha 0.1, qs-bar` to your Hyprland config (newer versions use `layerrule = blur on, match:namespace qs-bar`).

## workspaces

| Key | Default | Meaning |
|---|---|---|
| `workspaces.label` | index | `"index"` shows 1, 2, 3. `"name"` shows the workspace name. Only workspaces that exist are shown. |
| `workspaces.activeExtra` | 16 | Extra width given to the focused workspace. The highlight slides between workspaces using `animation.normal`. |

## hyprland

| Key | Default | Meaning |
|---|---|---|
| `hyprland.lua` | true | Hyprland 0.55 and newer use a Lua config, and workspace switching must be sent as Lua. Set to `false` only on older Hyprland with a `hyprland.conf`. |

## panels

Panels hang from the bar. Click the wifi, bluetooth, volume, battery or vitals item to open one. Click outside or press Escape to close. Keep `panels.opacity` equal to `bar.opacity` and `colors.panel` equal to `colors.barBg` so the panel blends into the bar.

| Key | Default | Meaning |
|---|---|---|
| `panels.width` | 320 | Panel width. |
| `panels.vitalsWidth` | 500 | Width of the system vitals panel. |
| `panels.controlWidth` | 520 | Width of the control center (the expanded island). |
| `panels.networkWidth` | 400 | Width of the Wi-Fi and Bluetooth panels. |
| `panels.maxHeight` | 740 | Tallest a panel or the expanded island can be. The bar window always has this much room below the bar (it is see-through and does not catch clicks). Resizing it live caused flicker, so it stays fixed. Lower it to use a little less memory. |
| `panels.radius` | 22 | Bottom corner radius. |
| `panels.opacity` | 0.88 | Panel background opacity. |
| `panels.padding` | 14 | Space inside the panel. |
| `panels.openMs` | 220 | Time to unroll from the bar. |
| `panels.closeMs` | 140 | Time to roll back up. Switching panels closes the open one first, then opens the new one. |

Extra bar gestures on the volume icon: right click mutes, scroll changes the volume.

## sounds

Needs `libpulse` (for `paplay`) and `sound-theme-freedesktop`. Set any path to `""` to silence just that event.

| Key | Meaning |
|---|---|
| `sounds.enabled` | Master switch. The Volume panel also has a temporary "System sounds" toggle. |
| `sounds.volume` | 0 to 1. |
| `sounds.chargerPlug`, `sounds.chargerUnplug` | Played when the charger is connected or removed. |
| `sounds.usbAdd`, `sounds.usbRemove` | Played when a USB device is plugged in or removed (needs `udevadm`). |
| `sounds.lowBattery` | Played once when the battery drops to `battery.low`. |
| `sounds.notification` | Played when a notification arrives, unless do not disturb is on. Critical notifications still play. |

Use any `.oga`, `.ogg`, `.wav` or `.flac` file path. No sounds play for the first 3 seconds after start.

## island

| Key | Default | Meaning |
|---|---|---|
| `island.idleWidth` | 132 | Width when showing eyes or playing music. |
| `island.idleHeight` | 28 | Height when showing eyes. |
| `island.bottomRadius` | 16 | Bottom corner radius while small. The top is always flat against the screen edge. |
| `island.expandedRadius` | 26 | Bottom corner radius while expanded. |
| `island.toastWidth`, `island.toastHeight` | 420, 46 | Size of a toast. It is a wide, one-line snippet. |
| `island.toastFullWidth` | 460 | Width of an opened notification. Its height follows its content, with body text limited by `toasts.maxBodyLines`. |
| `island.musicFullWidth`, `island.musicFullHeight` | 380, 150 | Size of the expanded music player. |
| `island.morphMs` | 320 | How long the island takes to change size. |
| `island.scrollSpeed` | 22 | How fast long music titles scroll, in pixels per second. |
| `island.color` | island | Island fill. A colour name from `colors` or a hex value. |
| `island.border` | 1 | Island outline width. 0 removes it. |
| `island.borderColor` | accent | Outline colour, a colour name or hex value. |
| `island.borderOpacity` | 0.4 | Outline strength. Raise it to make the island stand out more. |

### How the island behaves

| State | What you see | Click |
|---|---|---|
| Nothing happening | Eyes | Opens the control center |
| Music playing | Equalizer bars and the scrolling title and artist, same size as the eyes | Expands to art, progress and controls |
| Notification arrives | Grows into a toast | Expands to the full notification |
| Music paused | Back to eyes | |

Right click always opens the control center. Click outside the island or press Escape to collapse it. A toast you open is removed from the island afterwards but stays in the notifications panel. The equalizer bars are animated for effect, they do not analyse the audio.

## toasts and media

| Key | Default | Meaning |
|---|---|---|
| `toasts.enabled` | true | Show notifications on the island. |
| `toasts.timeoutMs` | 5000 | How long a toast stays. It stays while the mouse is over it. |
| `toasts.expandedTimeoutMs` | 15000 | How long an opened notification stays with no mouse over it. |
| `toasts.maxBodyLines` | 3 | Lines of body text in an opened notification. The rest is in the notifications panel. |
| `media.exclude` | [] | Players to ignore. Matches the player name, desktop entry or D-Bus name, ignoring case. Example: `["chrome", "firefox"]`. |
| `media.excludeTitles` | [] | Ignore any track whose title or artist contains one of these words. |

Do not disturb hides toasts and silences sounds. Critical notifications still get through.

## audio

| Key | Default | Meaning |
|---|---|---|
| `audio.maxVolume` | 2.0 | Highest output volume. 2.0 is 200%. A mark shows where 100% is, and the bar turns yellow above it. |
| `audio.maxInput` | 1.0 | Highest microphone volume. |
| `audio.step` | 0.03 | How much one scroll step on the volume icon changes. |

## session (power menu)

Commands run by the power and lock buttons in the control center. Edit them to match your setup, for example to use your own lock screen.

| Key | Default |
|---|---|
| `session.lock` | "" (empty) |
| `session.suspend` | `systemctl suspend` |
| `session.hibernate` | `systemctl hibernate` |
| `session.logout` | `loginctl terminate-session $XDG_SESSION_ID` |
| `session.reboot` | `systemctl reboot` |
| `session.poweroff` | `systemctl poweroff` |

An empty `session.lock` uses the shell's own lock screen. Put a command there to use something else. Log out, reboot and power off ask for a second click to confirm in the control center.

## capture and clipboard

| Key | Default | Meaning |
|---|---|---|
| `capture.screenshotDir` | ~/Pictures/Screenshots | Where screenshots are saved. They are also copied to the clipboard. |
| `capture.recordDir` | ~/Videos | Where recordings are saved. |
| `capture.audio` | "" | Recording sound. `""` is silent, `"default"` records the default microphone, or give a device name (a monitor source records what you hear: find names with `pactl list short sources`). |
| `capture.annotate` | satty ... | Command that receives the screenshot on stdin for annotation. `$f` is the output file. |
| `clipboard.maxItems` | 30 | History entries shown. |
| `clipboard.manageWatcher` | false | Let the shell run the `wl-paste` watchers. Leave false if your Hyprland config already does. |

Clipboard history needs entries to be stored. Add these to your Hyprland config, or set `clipboard.manageWatcher` to true:

    exec-once = wl-paste --type text --watch cliphist store
    exec-once = wl-paste --type image --watch cliphist store

While recording, a red timer appears in the bar. Click it to stop.

## eyes

| Key | Default | Meaning |
|---|---|---|
| `eyes.color` | onIsland | Eye colour. A colour name from `colors` (like `text` or `accent`) or a hex value. |
| `eyes.width`, `eyes.height` | 11, 13 | Size of each eye. |
| `eyes.gap` | 12 | Space between the eyes. |
| `eyes.drift` | 2.5 | How far the eyes wander, in pixels. |
| `eyes.driftEnabled` | true | Turn random wandering on or off. |
| `eyes.blinkMinMs`, `eyes.blinkMaxMs` | 2500, 6500 | Random time between blinks. |
| `eyes.blinkOnHover` | true | Blink when the mouse enters the island. |
| `eyes.mood` | auto | `auto` picks the mood from the rules below, or force one: `neutral`, `happy`, `playful`, `sleepy`, `moody`, `tired`, `sad`, `angry`, `scared`. |
| `eyes.moodIntervalMs` | 5000 | How often the mood is re-checked. |
| `eyes.stableSamples` | 2 | A new mood must hold for this many checks before the eyes change, so they do not flicker. |
| `eyes.nightStart`, `eyes.nightEnd` | 22, 6 | Hours that count as night. |
| `eyes.moodyBattery`, `eyes.happyBattery` | 35, 60 | Battery percent for moody (below), and for happy (at or above). `battery.low` is the sad/tired level. |
| `eyes.cpuHigh`, `eyes.memHigh`, `eyes.panic` | 85, 85, 95 | CPU and memory together above the first two is angry. Either one above `panic` is scared. |
| `eyes.offlineMoody` | true | Moody when there is no network. |
| `eyes.moodColors` | | Colour name per mood, from `colors`. |

**Mood rules, first match wins:** high CPU and memory is angry (scared if the battery is also low); one value maxed is scared; low battery is tired at night and sad by day; medium-low battery is moody; offline is moody; weekend night is playful; night is sleepy; day with a good battery is happy. Test one with `qsctl mood set angry`, go back with `qsctl mood auto`.

The eyes never follow the cursor.

## clock

| Key | Default | Meaning |
|---|---|---|
| `clock.timeFormat` | h:mm AP | Qt format. Use `HH:mm` for 24-hour time. |
| `clock.dateFormat` | ddd d MMM | Qt format. Gives `Sun 8 Nov`. |

## animation

`animation.fast`, `animation.normal`, `animation.slow`: durations in milliseconds (120, 220, 400).

## vitals

| Key | Default | Meaning |
|---|---|---|
| `vitals.intervalMs` | 2000 | How often memory, swap and CPU refresh. |
| `vitals.diskIntervalMs` | 30000 | How often disk usage refreshes. |
| `vitals.stops` | text, warn, warm, bad | List of `[percent, colour]`. Each colour is a name from `colors` or a hex value. Colours blend smoothly between stops. |

## battery and network

| Key | Default | Meaning |
|---|---|---|
| `battery.low` | 20 | At or below this percent the battery is red. |
| `battery.medium` | 50 | At or below this percent it is yellow. Above it is green. |
| `network.intervalMs` | 5000 | How often Wi-Fi and Ethernet status refresh. |

The battery hides itself on machines without one.

## modules, notifications, calendar

| Key | Default | Meaning |
|---|---|---|
| `modules.idleInhibitor` | false | Shows the keep-awake button in the bar and the Keep awake tile in the control center. Off by default. |
| `notifications.dnd` | false | Start with do not disturb on. |
| `notifications.maxLines` | 3 | Lines of body text shown per notification. |
| `calendar.firstDay` | 1 | 0 starts weeks on Sunday, 1 on Monday. |

## Using the bar

| Item | Left click | Right click |
|---|---|---|
| Time and date | Calendar | |
| Bell | Notifications panel | Toggle do not disturb |
| Recording timer | Stop recording | |
| Island | Control center | Control center |
| Wi-Fi, Bluetooth | Their panels | |
| Volume | Volume panel | Mute |
| Volume (scroll) | Change volume | |
| Vitals, battery | Their panels | |

In the control center, right click the Wi-Fi, Bluetooth or Do not disturb tile to open its full panel.

## profile

| Key | Default | Meaning |
|---|---|---|
| `profile.name` | "" | Name shown at the top of the control center. Empty uses the computer's host name. |
| `profile.avatar` | "" | Path to a picture, like `~/Pictures/me.png`. Empty shows the first letter of the name. |

## wallpaper

The wallpaper is drawn by the shell itself. It cross-fades between images and decodes them at screen size, so large images stay light on memory. The window is see-through until you pick an image, so another wallpaper tool keeps working until then.

| Key | Default | Meaning |
|---|---|---|
| `wallpaper.enabled` | true | Let the shell draw the wallpaper. |
| `wallpaper.dir` | ~/Pictures/Wallpapers | Folder with your images (jpg, png, webp, bmp). Subfolders are included. |
| `wallpaper.default` | "" | Image used the first time. Empty uses the first one found. |
| `wallpaper.fit` | crop | `crop` fills the screen, `fit` shows the whole image, `stretch` stretches it. |
| `wallpaper.transitionMs` | 700 | Cross-fade time. |
| `wallpaper.intervalMin` | 0 | Change wallpaper every N minutes. 0 turns it off. |
| `wallpaper.random` | false | With a timer: pick randomly instead of in order. |

Open the picker from the Wallpaper tile in the control center or with `qs ipc call wallpaper picker`. Your choice is remembered in `~/.local/state/qs-shell/wallpaper`.

## widgets

Desktop widgets sit on the wallpaper layer, under your windows.

| Key | Default | Meaning |
|---|---|---|
| `widgets.clock.enabled` | true | Show the digital clock. |
| `widgets.clock.position` | bottom-left | `top-left`, `top-center`, `top-right`, `center-left`, `center`, `center-right`, `bottom-left`, `bottom-center`, `bottom-right`. |
| `widgets.clock.margin` | 56 | Distance from the screen edge. |
| `widgets.clock.timeFormat` | h:mm | Qt time format. `HH:mm` for 24-hour. |
| `widgets.clock.dateFormat` | dddd, d MMMM | Qt date format. Empty hides the date. |
| `widgets.clock.seconds` | false | Show seconds. Updates every second instead of every minute. |
| `widgets.clock.size`, `widgets.clock.dateSize` | 88, 20 | Text sizes. |
| `widgets.clock.color` | text | A colour name from `colors` or a hex value. |
| `widgets.clock.opacity` | 0.9 | Text opacity. |
| `widgets.clock.shadow` | true | Soft shadow so it reads on any wallpaper. |

## launcher

A full-screen app grid, like GNOME. Open it with the apps button in the bar or `qs ipc call launcher toggle`. Type to search, arrow keys or Tab to move, Enter to launch, Esc to close. Apps you use most come first. For a blurred background on Hyprland, add a layer rule for the namespace `qs-launcher`.

| Key | Default | Meaning |
|---|---|---|
| `launcher.columns` | 7 | Apps per row. |
| `launcher.iconSize` | 64 | Icon size. |
| `launcher.cellWidth`, `launcher.cellHeight` | 150, 120 | Size of each app cell. |
| `launcher.dim` | 0.9 | How solid the background is, 0 to 1. |

## lock screen

The shell has its own lock screen: wallpaper, time, your picture and name, a password box, the playing media, and wifi, bluetooth, volume and battery in the top corner. It uses the Wayland session-lock protocol, so if the shell crashes while locked, the screen stays locked.

Lock with `qs ipc call lock lock`, the lock buttons in the control center, or `qs ipc call session lock`.

To lock on idle and before sleep, point hypridle at it (`~/.config/hypr/hypridle.conf`):

    general {
        lock_cmd = qs ipc call lock lock
        before_sleep_cmd = loginctl lock-session
        after_sleep_cmd = hyprctl dispatch dpms on
    }
    listener {
        timeout = 300
        on-timeout = loginctl lock-session
    }

`loginctl lock-session` then runs `lock_cmd`, so everything that locks (idle, suspend, the buttons) ends up in the shell's lock screen.

| Key | Default | Meaning |
|---|---|---|
| `lock.pamConfig` | login | PAM service used to check your password. `login` exists on most systems. If your password is rejected, try `system-auth` (Arch) or `common-auth` (Debian, Ubuntu). |
| `lock.wallpaper` | "" | Picture for the lock screen. Empty uses the current wallpaper. |
| `lock.blur` | 0.7 | Blur strength, 0 to 1. 0 turns blur off. |
| `lock.dim` | 0.35 | How dark the wallpaper is, 0 to 1. |
| `lock.timeFormat`, `lock.dateFormat` | h:mm, dddd, d MMMM | Qt formats. |
| `lock.showMedia` | true | Show the playing media under the password box. |

**Before you rely on it:** test it while you have another way in. Open a second terminal on another TTY (Ctrl+Alt+F3), then run `qs ipc call lock lock` and unlock with your password. If the password is never accepted, check `lock.pamConfig`. If you get stuck, from the TTY run `loginctl unlock-session` or restart your session. Installing `hyprlock` as a spare is a good safety net.

## theming (one palette for every app)

See `theming.md`. In short: `theming.enabled` turns on exporting. Each entry in `theming.targets` has a `template` from `templates/`, an `out` path, and an optional `reload` command. When the palette changes (or you run `qs ipc call theme apply`) every template is rendered with the palette's colours.

## IPC commands (keybinds)

Run any of these from a keybind or a terminal as `qs ipc call <target> <function> [argument]`. List everything the running shell understands with `qs ipc show`.

| Target | Function | What it does |
|---|---|---|
| `control` | `toggle`, `open`, `close` | Control center (the expanded island) on the focused screen. |
| `panel` | `toggle <name>`, `close` | A bar panel. Names: `wifi`, `bluetooth`, `volume`, `battery`, `vitals`, `calendar`, `notifications`. They open centered under the island. |
| `notifications` | `toggle`, `dnd`, `dndOn`, `dndOff`, `clear`, `dismissToast` | Notifications panel, do not disturb, clear all, close the current toast. |
| `clipboard` | `toggle`, `close` | The clipboard popup window. It is its own window, not part of the bar. |
| `capture` | `screenshot <region\|screen\|annotate>`, `record <screen\|region>`, `toggleRecord`, `stopRecord` | Screenshots and recording on the focused screen. |
| `volume` | `up`, `down`, `mute`, `set <percent>`, `micMute` | Output volume (up to `audio.maxVolume`) and microphone mute. |
| `brightness` | `up`, `down`, `set <percent>`, `kbdUp`, `kbdDown` | Screen and keyboard backlight. |
| `media` | `playPause`, `next`, `previous`, `expand` | Control the playing player. `expand` opens or closes the island player. |
| `island` | `collapse` | Close whatever the island has open. |
| `session` | `lock`, `suspend`, `hibernate`, `logout`, `reboot`, `poweroff` | Runs the commands from `session`. These run immediately, with no confirmation. |
| `idle` | `toggle` | Keep awake on or off. |
| `wallpaper` | `picker`, `next`, `prev`, `random`, `set <path>`, `reload` | Wallpaper picker popup and changes. |
| `launcher` | `toggle`, `open`, `close` | The app launcher. |
| `theme` | `set <name>`, `next`, `get`, `list`, `apply` | Switch the palette. It edits `palette` in `config.json`, and the shell updates live. `apply` re-exports the colours to your apps. |
| `lock` | `lock`, `locked` | Lock the screen with the built-in lock screen. There is deliberately no unlock command. |

Examples:

    qs ipc call clipboard toggle
    qs ipc call volume up
    qs ipc call capture screenshot region
    qs ipc call panel toggle wifi
    qs ipc call theme set tokyo-night

## palette and colors

`palette` picks a ready-made colour set from the `palettes/` folder. To try one, change the name and save:

    "palette": "tokyo-night",

Anything you put in `colors` overrides the palette, so you can keep a palette and change one colour:

    "palette": "catppuccin-mocha",
    "colors": { "accent": "#cba6f7" }

See `palettes.md` for the list. Colour keys:

| Key | Used for |
|---|---|
| `barBg` | Bar background (see `bar.opacity`). |
| `panel` | Panel background (see `panels.opacity`). Keep equal to `barBg` so panels blend into the bar. |
| `surface`, `surfaceHi` | Pill background, and pill background on hover. |
| `island` | Island background. |
| `onIsland` | Eyes and text drawn on the island. |
| `text`, `textDim`, `textFaint` | Main text, secondary text, disabled items. |
| `accent`, `onAccent` | Highlight colour, and text drawn on top of it. |
| `good`, `warn`, `warm`, `bad`, `info` | Green, yellow, orange, red, blue status colours. |

If a `colors` block of yours is missing `panel`, `island`, `onIsland` or `warm`, the shell fills them in (from `barBg`, `barBg`, `text` and `warn`), so older colour blocks no longer produce black text.

To make your own palette, copy any file in `palettes/`, rename it, edit the colours, and use its name in `palette`.

## Icon names

Icons are Material Symbols ligature names, listed at fonts.google.com/icons.


## monitors

The bar appears on every monitor. Each bar only shows the workspaces that live on its own monitor, and the visible one is highlighted (accent colour when that monitor has focus, muted when it does not). Resolution, scale and position of monitors are set in Hyprland, not here.

| Key | Default | Meaning |
|---|---|---|
| `monitors.include` | [] | Only these monitors get a bar. Empty means all. Names come from `hyprctl monitors` (like `DP-1`). |
| `monitors.exclude` | [] | Monitors that never get a bar. |
| `monitors.primary` | "" | The primary monitor. Empty uses the first one. |
| `monitors.tray` | all | `all` shows the tray on every bar, `primary` only on the primary one. |
| `toasts.monitor` | focused | Where toasts appear: `focused` (the monitor you are using), `primary`, or `all`. |
| `widgets.clock.monitors` | all | `all` or `primary`. |

## island shape

| Key | Default | Meaning |
|---|---|---|
| `island.flare` | 8 | How far the sides go out at the top, in pixels. 0 makes the sides straight. Keep it small so it does not look like a triangle. |

Closing the island: click its top strip (where it sat when idle) to close it, or press Esc or click outside. Right click also closes the music player and an opened toast.

## lock screen look

| Key | Default | Meaning |
|---|---|---|
| `lock.clockStyle` | stacked | `stacked` (hours over minutes) or `inline`. |
| `lock.clockSize` | 130 | Clock size. |
| `lock.clockColor` | accent | Colour of the date and the minutes. |
| `lock.hourFormat`, `lock.minuteFormat` | HH, mm | Qt formats for the stacked clock. |
| `lock.restoreOnStart` | true | If the shell restarts while locked, it locks again at start so you can still unlock. |

## theming: Hyprland (Lua)

`templates/hyprland.lua` writes `_G.COLORS = { ... }` with Material-style names (`primary`, `outline`, `error`, `surface`, ...) and the shell's own names (`accent`, `bg`, `good`, ...). Values are `"rgb(rrggbb)"` strings. Add this target to `theming.targets`:

    { "template": "hyprland.lua", "out": "~/.config/hypr/colors.lua", "reload": "hyprctl reload" }

and load it in your Hyprland config before using `COLORS`: `dofile(os.getenv("HOME") .. "/.config/hypr/colors.lua")`.

When `theming.enabled` is true, every target whose file does not exist yet is created at start. Existing files are only rewritten when the palette changes. A target that is a symlink is replaced by a real file instead of being written through.

## service and qsctl

See `extras/README.md`: a systemd user service so the shell starts without Hyprland, and `qsctl`, a short command for all the IPC calls.
