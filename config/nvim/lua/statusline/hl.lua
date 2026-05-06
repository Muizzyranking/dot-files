local p = {
	fg = "#c0caf5",
	fg_dim = "#9aa5ce",
	fg_dimmer = "#565f89",
	bg_dark = "#1a1b26",
	surface = "#24283b",
	red = "#f7768e",
	orange = "#ff9e64",
	green = "#9ece6a",
	blue = "#7aa2f7",
	cyan = "#7dcfff",
	purple = "#bb9af7",
	warning = "#e0af68",
	error = "#db4b4b",
	info = "#0db9d7",
	hint = "#1abc9c",
}

local highlights = {
	Statusline = { fg = p.fg_dim, bg = p.bg_dark },
	StatuslineNC = { fg = p.fg_dimmer, bg = p.bg_dark },
	StatuslineSep = { fg = p.fg_dimmer, bg = p.bg_dark },

	-- Mode pills
	StatuslineModeNormal = { fg = p.bg_dark, bg = p.blue, bold = true },
	StatuslineModeInsert = { fg = p.bg_dark, bg = p.green, bold = true },
	StatuslineModeVisual = { fg = p.bg_dark, bg = p.purple, bold = true },
	StatuslineModeReplace = { fg = p.bg_dark, bg = p.orange, bold = true },
	StatuslineModeCommand = { fg = p.bg_dark, bg = p.cyan, bold = true },
	StatuslineModeTerminal = { fg = p.bg_dark, bg = p.green, bold = true },

	StatuslineSlantNormal = { fg = p.blue, bg = p.bg_dark },
	StatuslineSlantInsert = { fg = p.green, bg = p.bg_dark },
	StatuslineSlantVisual = { fg = p.purple, bg = p.bg_dark },
	StatuslineSlantReplace = { fg = p.orange, bg = p.bg_dark },
	StatuslineSlantCommand = { fg = p.cyan, bg = p.bg_dark },
	StatuslineSlantTerminal = { fg = p.green, bg = p.bg_dark },

	-- File
	StatuslineFilename = { fg = p.fg, bg = p.bg_dark, bold = true, italic = true },
	StatuslineFilenameModified = { fg = p.warning, bg = p.bg_dark, bold = true, italic = true },
	StatuslineFilenameExec = { fg = p.green, bg = p.bg_dark, bold = true, italic = true },

	-- Git
	StatuslineBranch = { fg = p.fg_dim, bg = p.bg_dark, italic = true },
	StatuslineDiffAdd = { fg = p.green, bg = p.bg_dark },
	StatuslineDiffChange = { fg = p.warning, bg = p.bg_dark },
	StatuslineDiffDelete = { fg = p.red, bg = p.bg_dark },

	-- Diagnostics
	StatuslineDiagError = { fg = p.error, bg = p.bg_dark },
	StatuslineDiagWarn = { fg = p.warning, bg = p.bg_dark },
	StatuslineDiagInfo = { fg = p.info, bg = p.bg_dark },
	StatuslineDiagHint = { fg = p.hint, bg = p.bg_dark },

	-- LSP
	StatuslineLsp = { fg = p.green, bg = p.bg_dark, italic = true },

	-- Copilot
	StatuslineCopilotOk = { fg = p.green, bg = p.bg_dark },
	StatuslineCopilotWarn = { fg = p.warning, bg = p.bg_dark },
	StatuslineCopilotError = { fg = p.red, bg = p.bg_dark },

	-- Buffers
	StatuslineBuffers = { fg = p.fg_dim, bg = p.bg_dark },
	StatuslineBuffersDirty = { fg = p.warning, bg = p.bg_dark, bold = true },

	-- Misc
	StatuslineMacro = { fg = p.red, bg = p.bg_dark, bold = true },
	StatuslineSearch = { fg = p.cyan, bg = p.bg_dark, bold = true },
	StatuslinePosition = { fg = p.fg_dimmer, bg = p.bg_dark },
}

local function setup_highlights()
	for name, opts in pairs(highlights) do
		vim.api.nvim_set_hl(0, name, opts)
	end
end

return {
	setup = function(augroup)
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = augroup,
			callback = setup_highlights,
		})
            end,
}
