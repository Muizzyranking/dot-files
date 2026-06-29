local utils = require("statusline.utils")

local M = {}

local p = {
	fg = "#c0caf5",
	fg_dim = "#9aa5ce",
	fg_dimmer = "#565f89",
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
	rec = "#ff3333",
	rec_dim = "#552222",
}

M.groups = {
	Statusline = { fg = p.fg_dim },
	StatuslineNC = { fg = p.fg_dimmer },
	StatuslineSep = { fg = p.fg_dimmer },

	-- Mode
	StatuslineModeNormal = { fg = "BG", bg = p.blue, bold = true },
	StatuslineModeInsert = { fg = "BG", bg = p.green, bold = true },
	StatuslineModeVisual = { fg = "BG", bg = p.purple, bold = true },
	StatuslineModeReplace = { fg = "BG", bg = p.orange, bold = true },
	StatuslineModeCommand = { fg = "BG", bg = p.cyan, bold = true },
	StatuslineModeTerminal = { fg = "BG", bg = p.green, bold = true },

	-- File
	StatuslineFilename = { fg = p.fg, bold = true, italic = true },
	StatuslineFilenameModified = { fg = p.warning, bold = true, italic = true },
	StatuslineFilenameExec = { fg = p.green, bold = true, italic = true },

	-- Git
	StatuslineBranch = { fg = p.fg_dim, italic = true },
	StatuslineDiffAdd = { fg = p.green },
	StatuslineDiffChange = { fg = p.warning },
	StatuslineDiffDelete = { fg = p.red },

	-- Diagnostics
	StatuslineDiagError = { fg = p.error },
	StatuslineDiagWarn = { fg = p.warning },
	StatuslineDiagInfo = { fg = p.info },
	StatuslineDiagHint = { fg = p.hint },

	-- LSP / copilot
	StatuslineLsp = { fg = p.green, italic = true },
	StatuslineCopilotOk = { fg = p.green },
	StatuslineCopilotWarn = { fg = p.warning },
	StatuslineCopilotError = { fg = p.red },

	-- Buffers
	StatuslineBuffers = { fg = p.fg_dim },
	StatuslineBuffersDirty = { fg = p.warning, bold = true },

	-- Misc
	StatuslineRoot = { fg = p.fg_dim },
	StatuslineMacro = { fg = p.red, bold = true },
	StatuslineSearch = { fg = p.cyan, bold = true },
	StatuslinePosition = { fg = p.fg_dimmer },

	-- Recording dot
	StatuslineRecording = { fg = p.rec, bold = true },
	StatuslineRecordingDim = { fg = p.rec_dim },
}

local function resolve_spec(spec)
	local out = vim.tbl_extend("force", {}, spec)
	if out.fg == "BG" then
		out.fg = "#1a1b26"
	end
	if out.bg == nil then
		out.bg = utils.bg()
	end
	return out
end

function M.apply()
	for name, spec in pairs(M.groups) do
		vim.api.nvim_set_hl(0, name, resolve_spec(spec))
	end
	utils.reset_inline_cache()
end

function M.setup(augroup)
	M.apply()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = augroup,
		callback = function()
			M.apply()
			vim.schedule(function()
				vim.cmd.redrawstatus()
			end)
		end,
	})
end

return M
