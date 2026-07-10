-- Settings tag
hl.window_rule({ match = { title = "^(ROG Control)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(gnome-disks|wihotspot(-gui)?)$" }, tag = "+settings" })
hl.window_rule({ match = { title = "(Kvantum Manager)" }, tag = "+settings" })
hl.window_rule({ match = { class = "(nwg-look)" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(file-roller|org.gnome.FileRoller)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(nm-applet|nm-connection-editor|blueman-manager)$" }, tag = "+settings" })
hl.window_rule({
	match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },
	tag = "+settings",
})
hl.window_rule({ match = { class = "^(qt5ct|qt6ct)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "(xdg-desktop-portal-gtk)" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(org.kde.polkit-kde-authentication-agent-1)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^([Rr]ofi)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(btrfs-assistant)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(timeshift-gtk)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^(com.network.manager)$" }, tag = "+settings" })
hl.window_rule({ match = { class = "^thunar$", title = "^(Rename.*)$" }, tag = "+settings" })

-- Projects tag
hl.window_rule({ match = { class = "^(codium|codium-url-handler|VSCodium)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(VSCode|code|code-url-handler)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(jetbrains-.+)$" }, tag = "+projects" })
hl.window_rule({ match = { class = "^(dev.zed.Zed|antigravity)$" }, tag = "+projects" })

-- Browser tags
hl.window_rule({
	match = { class = "^([Ff]irefox|org.mozilla.firefox|[Ff]irefox-esr|[Ff]irefox-bin)$" },
	tag = "+browser",
})
hl.window_rule({ match = { class = "^([Gg]oogle-chrome(-beta|-dev|-unstable)?)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(chrome-.+-Default)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Cc]hromium)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^([Mm]icrosoft-edge(-stable|-beta|-dev|-unstable))$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(Brave-browser(-beta|-dev|-unstable)?)$" }, tag = "+browser" })
hl.window_rule({ match = { class = "^(zen-alpha|zen)$" }, tag = "+browser" })

-- Terminal tags
hl.window_rule({ match = { class = "^(Alacritty|kitty|kitty-dropterm)$" }, tag = "+terminal" })

-- IM tags
hl.window_rule({ match = { class = "^([Dd]iscord|[Ww]ebCord|[Vv]esktop)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ff]erdium)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^([Ww]hatsapp-for-linux)$" }, tag = "+im" })
hl.window_rule({ match = { class = "^(org.telegram.desktop|io.github.tdesktop_x64.TDesktop)$" }, tag = "+im" })

-- File-manager tags
hl.window_rule({ match = { class = "^([Tt]hunar|org.gnome.Nautilus|[Pp]cmanfm-qt)$" }, tag = "+file-manager" })

-- Multimedia-video tags
hl.window_rule({ match = { class = "^([Mm]pv|vlc)$" }, tag = "+multimedia_video" })

-- ============================================
-- FLOATING & POSITIONING
-- ============================================

hl.window_rule({ match = { title = "^(Authentication Required)$" }, float = true, center = true })

hl.window_rule({
	match = { class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" },
	float = true,
})

hl.window_rule({
	match = { title = "^(Add Folder to Workspace)$" },
	float = true,
	size = { "monitor_w*0.7", "monitor_h*0.6" },
	center = true,
})

hl.window_rule({
	match = { title = "^(Save As)$" },
	float = true,
	size = { "monitor_w*0.7", "monitor_h*0.6" },
	center = true,
})

hl.window_rule({ match = { initial_title = "(Open Files)" }, float = true, size = { "monitor_w*0.7", "monitor_h*0.6" } })

hl.window_rule({
	match = { title = "^(SDDM Background)$" },
	float = true,
	center = true,
	size = { "monitor_w*0.16", "monitor_h*0.12" },
})

-- Tag-based floating
hl.window_rule({ match = { tag = "settings" }, float = true, center = true })
hl.window_rule({ match = { class = "^kitty$" }, opacity = "1.0 1.0" })
hl.window_rule({ match = { tag = "viewer" }, float = true, center = true })
hl.window_rule({ match = { tag = "KooL-Settings" }, float = true, center = true })

hl.window_rule({ match = { class = "([Zz]oom|onedriver|onedriver-launcher)" }, float = true })
hl.window_rule({ match = { class = "(org.gnome.Calculator|qalculate-gtk)" }, float = true })
hl.window_rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" }, float = true })
hl.window_rule({ match = { class = "^([Qq]alculate-gtk)$" }, float = true })

-- Missing File Dialogs
hl.window_rule({ match = { title = "^(Open|Choose Files|Save As|Library)$" }, float = true })
hl.window_rule({ match = { title = "^(File Upload|Choose wallpaper)(.*)$" }, float = true })
hl.window_rule({ match = { title = "^(Confirm to replace files)$" }, float = true })
hl.window_rule({ match = { title = "^(.*dialog.*)$" }, float = true })
hl.window_rule({ match = { class = "^(.*dialog.*)$" }, float = true })

hl.window_rule({ match = { tag = "multimedia_video" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia_video" }, opacity = 1.0 })
hl.window_rule({ match = { tag = "multimedia" }, no_blur = true })
hl.window_rule({ match = { tag = "multimedia" }, opacity = 1.0 })

hl.window_rule({
	match = { initial_title = "((?i)(?:[a-z0-9-]+\\.)*youtube\\.com_/|app\\.zoom\\.us_/wc/home)" },
	opacity = "1.0 1.0",
})

hl.window_rule({
	match = { class = "^(pavucontrol|org.pulseaudio.pavucontrol|com.saivert.pwvucontrol)$" },
	center = true,
})

hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { fullscreen = 1 }, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { class = "^(*)$" }, idle_inhibit = "fullscreen" })
hl.window_rule({ match = { title = "^(*)$" }, idle_inhibit = "fullscreen" })

hl.window_rule({
	match = { title = "^(Picture-in-Picture)$" },
	float = true,
	move = { "72%", "7%" },
	opacity = "0.95 0.75",
	pin = true,
	keep_aspect_ratio = true,
	size = { "monitor_w*0.3", "monitor_h*0.3" },
})

hl.window_rule({
	match = { class = "^(thunar)$", title = "^(File Operation Progress)$" },
	float = true,
	center = true,
	size = { "monitor_w*0.26", "monitor_h*0.18" },
})

hl.window_rule({
	match = { class = "^(kitty)$", title = "^(top|btop|htop)$" },
	float = true,
})

hl.window_rule({
	match = { class = "^(hyprland-share-picker)$" },
	float = true,
	center = true,
	size = { "monitor_w*0.4", "monitor_h*0.4" },
})

hl.window_rule({ match = { title = "^(HyprEmoji)$" }, float = true })

hl.window_rule({
	match = { class = "^([Ss]potify)$" },
	workspace = 7,
})

hl.window_rule({
	match = { class = "^(slack|Slack|discord|chrome-web\\.whatsapp\\.com__-Default|org\\.telegram\\.desktop)$" },
	workspace = 8,
})

hl.layer_rule({
	match = { namespace = "^dms:bar$" },
	xray = true,
})

hl.workspace_rule({ workspace = "1", layout = "scrolling" })
hl.workspace_rule({ workspace = "2", layout = "scrolling" })
hl.workspace_rule({ workspace = "8", layout = "scrolling" })
