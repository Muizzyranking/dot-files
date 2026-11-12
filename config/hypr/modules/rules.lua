---@alias WindowMatch table<string, string|number|boolean>

---@param tag string
---@param classes string[]
---@return nil
local function tag_classes(tag, classes)
	hl.window_rule({
		match = { class = "^(" .. table.concat(classes, "|") .. ")$" },
		tag = "+" .. tag,
	})
end

---@param match WindowMatch
---@param w? number
---@param h? number
---@return nil
local function popup(match, w, h)
	local rule = { match = match, float = true, center = true }
	if w and h then
		rule.size = { "monitor_w*" .. w, "monitor_h*" .. h }
	end
	hl.window_rule(rule)
end

-- Settings
tag_classes("settings", {
	"gnome-disks",
	"wihotspot(-gui)?",
	"nwg-look",
	"file-roller",
	"org.gnome.FileRoller",
	"nm-applet",
	"nm-connection-editor",
	"blueman-manager",
	"pavucontrol",
	"org.pulseaudio.pavucontrol",
	"com.saivert.pwvucontrol",
	"qt5ct",
	"qt6ct",
	"xdg-desktop-portal-gtk",
	"org.kde.polkit-kde-authentication-agent-1",
	"[Rr]ofi",
	"btrfs-assistant",
	"timeshift-gtk",
	"com.network.manager",
})
hl.window_rule({ match = { title = "^(ROG Control)$" }, tag = "+settings" })
hl.window_rule({ match = { title = "(Kvantum Manager)" }, tag = "+settings" })
hl.window_rule({ match = { class = "^thunar$", title = "^(Rename.*)$" }, tag = "+settings" })

-- Projects
tag_classes("projects", {
	"codium",
	"codium-url-handler",
	"VSCodium",
	"VSCode",
	"code",
	"code-url-handler",
	"jetbrains-.+",
	"dev.zed.Zed",
	"antigravity",
})

-- Browsers
tag_classes("browser", {
	"[Ff]irefox",
	"org.mozilla.firefox",
	"[Ff]irefox-esr",
	"[Ff]irefox-bin",
	"[Gg]oogle-chrome(-beta|-dev|-unstable)?",
	"chrome-.+-Default",
	"[Cc]hromium",
	"[Mm]icrosoft-edge(-stable|-beta|-dev|-unstable)",
	"Brave-browser(-beta|-dev|-unstable)?",
	"zen-alpha",
	"zen",
})

-- Others
tag_classes("terminal", { "Alacritty", "kitty", "kitty-dropterm" })
tag_classes("im", {
	"[Dd]iscord",
	"[Ww]ebCord",
	"[Vv]esktop",
	"[Ff]erdium",
	"[Ss]lack",
	"[Ww]hatsapp-for-linux",
	"chrome-web\\.whatsapp\\.com__-Default",
	"org\\.telegram\\.desktop",
	"io\\.github\\.tdesktop_x64\\.TDesktop",
})

hl.window_rule({ match = { tag = "im" }, workspace = 8 })

tag_classes("file-manager", { "[Tt]hunar", "org.gnome.Nautilus", "[Pp]cmanfm-qt" })
tag_classes("multimedia_video", { "[Mm]pv", "vlc" })

-- Tag-based floating
for _, t in ipairs({ "settings", "viewer" }) do
	popup({ tag = t })
end

popup({ title = "^(Authentication Required)$" })
popup({ class = "^firefox$", title = "^Sign in – Google accounts — Mozilla Firefox$" })
-- popup({ class = "^xdg-desktop-portal-gtk" })

popup({ title = "^(Add Folder to Workspace|Save As)$" }, 0.7, 0.6)
popup({ title = "^(SDDM Background)$" }, 0.16, 0.12)
popup({ class = "^(thunar)$", title = "^(File Operation Progress)$" }, 0.26, 0.18)
popup({ class = "^(thunar)$", title = "^(Thunar Preferences)$" }, 0.26, 0.18)
popup({ class = "^(hyprland-share-picker)$" }, 0.4, 0.4)
popup({ class = "^xdg-desktop-portal-gtk$", title = "^Open Folder$", float = true }, 0.6, 0.6)
popup({ initial_title = "(Open Files)" }, 0.7, 0.6)
popup({ class = "^DesktopEditors$", title = "^$", float = true })
popup({ title = "^(Open|Choose Files|Library|File Upload.*|Choose wallpaper.*|Confirm to replace files|.*dialog.*)$" })

hl.window_rule({ match = { class = "^org.kde.plasma.emojier$" }, float = true, size = { 800, 600 } })
hl.window_rule({
	match = { class = "(codium|codium-url-handler|VSCodium)", title = "negative:(.*codium.*|.*VSCodium.*)" },
	float = true,
})
hl.window_rule({ match = { title = "^(HyprEmoji)$" }, float = true })
hl.window_rule({ match = { class = "^(kitty)$", title = "^(top|btop|htop)$" }, float = true })

hl.window_rule({
	match = { class = "([Zz]oom|onedriver|onedriver-launcher|org.gnome.Calculator|[Qq]alculate-gtk)" },
	float = true,
})
hl.window_rule({ match = { class = "^(mpv|com.github.rafostar.Clapper)$" }, float = true })

hl.window_rule({ match = { class = "^(.*dialog.*)$" }, float = true })

hl.window_rule({
	match = { title = "^(Picture-in-Picture)$" },
	float = true,
	move = { "72%", "7%" },
	opacity = "0.95 0.75",
	pin = true,
	keep_aspect_ratio = true,
	size = { "monitor_w*0.3", "monitor_h*0.3" },
})

hl.window_rule({ match = { tag = "multimedia_video" }, no_blur = true, opacity = 10 })
hl.window_rule({
	match = { initial_title = "((?i)(?:[a-z0-9-]+\\.)*youtube\\.com_/|app\\.zoom\\.us_/wc/home)" },
	opacity = "1.0 1.0",
})
hl.window_rule({ match = { fullscreen = true }, idle_inhibit = "fullscreen" })

hl.window_rule({ match = { class = "^([Ss]potify)$" }, workspace = 7 })

hl.workspace_rule({ workspace = "1", default_name = "一", layout = "scrolling" })
hl.workspace_rule({ workspace = "2", default_name = "二", layout = "scrolling" })
hl.workspace_rule({ workspace = "3", default_name = "三" })
hl.workspace_rule({ workspace = "4", default_name = "四" })
hl.workspace_rule({ workspace = "5", default_name = "五" })
hl.workspace_rule({ workspace = "6", default_name = "六" })
hl.workspace_rule({ workspace = "7", default_name = "七" })
hl.workspace_rule({ workspace = "8", default_name = "八", layout = "scrolling" })
hl.workspace_rule({ workspace = "9", default_name = "九" })
hl.workspace_rule({ workspace = "10", default_name = "十" })

hl.layer_rule({ match = { namespace = "qs-bar" }, blur = true }):set_enabled(false)
