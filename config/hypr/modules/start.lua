local Scripts = "$HOME/.config/hypr/scripts"

local cmds = {
	"/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",
	"dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
	"dbus-update-activation-environment --systemd --all",
	"systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE HYPRLAND_INSTANCE_SIGNATURE",
	"systemctl --user start hyprland-session.target",
	"systemctl --user start xdg-desktop-portal-hyprland.service",
	"wl-paste --watch cliphist store",
	"udiskie &",
	"systemctl --user start hypridle.service",
	"systemctl --user start quickshell.service",
	Scripts .. "/theme/init.sh",
}

hl.on("hyprland.start", function()
	for _, cmd in ipairs(cmds) do
		hl.exec_cmd(cmd)
	end
	hl.exec_cmd("kitty", { workspace = "1" })
end)
