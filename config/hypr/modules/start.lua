local Scripts = "$HOME/.config/hypr/scripts"

hl.exec_cmd("/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1")
hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
hl.exec_cmd("dbus-update-activation-environment --systemd --all")
hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
hl.exec_cmd("systemctl --user start hyprland-session.target")
hl.exec_cmd("systemctl --user start xdg-desktop-portal-hyprland.service")

hl.exec_cmd("wl-paste --watch cliphist store")
hl.exec_cmd("udiskie &")
hl.exec_cmd("hypridle &")
hl.exec_cmd("swww-daemon &")
hl.exec_cmd(Scripts .. "/theme/init.sh")

hl.dsp.exec_cmd("kitty", { workspace = "1", silent = true })
