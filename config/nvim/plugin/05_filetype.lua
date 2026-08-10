vim.filetype.add({
	extension = { rasi = "rasi", rofi = "rasi", wofi = "rasi", sh = "sh", env = "sh" },
	filename = {
		[".env"] = "sh",
		["vifmrc"] = "vim",
		[".gitconfig"] = "gitconfig",
		[".gitignore"] = "gitignore",
		[".gitignore_global"] = "gitignore",
	},
	pattern = {
		[".*/waybar/config"] = "jsonc",
		[".*/kitty/.+%.conf"] = "bash",
		[".*/hypr/.+%.conf"] = "hyprlang",
		["%.env%.[%w_.-]+"] = "sh",
		[".*git/config.*"] = "gitconfig",
		[".*git/ignore.*"] = "gitignore",
		[".*gitconfig.*"] = "gitconfig",
		[".*gitignore.*"] = "gitignore",
	},
})
