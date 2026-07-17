local M = {}

local C = require("statusline.components")

local function make_transparent()
	vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
	vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
end

local layout = {
	left = {
		C.mode,
		C.branch,
		C.root,
		C.diff,
		C.macro,
		C.showcmd,
	},
	center = {
		C.filepath,
	},
	right = {
		C.searchcount,
		C.buffers,
		C.diagnostics,
		C.copilot,
		C.lsp,
		C.position,
	},
}

local function picker_title()
	local picker = Snacks and Snacks.picker and Snacks.picker.get()[1]
	return (picker and picker.title) or "Picker"
end

local ft_layout = {
	lazygit = {
		left = { C.label(" Lazygit"), C.branch },
		center = {},
		right = {},
	},

	snacks_picker_list = {
		left = {
			C.label(string.format("🍿 %s", picker_title())),
			C.new({
				hl = { fg = "fg_dim", italic = true },
				value = function()
					return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
				end,
			}),
		},
		center = {},
		right = {
			C.new({
				hl = { fg = "fg_dimmer" },
				value = function()
					local picker = Snacks and Snacks.picker and Snacks.picker.get()[1]
					if not picker then
						return ""
					end
					return string.format("%d items", #picker:items())
				end,
			}),
		},
	},

	snacks_picker_input = {
		left = {
			C.label(string.format("🍿 %s", picker_title())),
			C.new({
				hl = { fg = "fg_dimmer" },
				value = function()
					local picker = Snacks and Snacks.picker and Snacks.picker.get()[1]
					if not picker then
						return ""
					end
					return string.format("%d results", #picker:items())
				end,
			}),
		},
		center = {},
		right = {},
	},

	oil = { left = { C.label("  Oil") }, center = {}, right = {} },
	pack_ui = { left = { C.label("📦 Pack") }, center = {}, right = {} },
	mason = { left = { C.label("󰏗 Mason") }, center = {}, right = {} },
	trouble = { left = { C.label("󰛩 Trouble") }, center = {}, right = {} },
	man = { left = { C.label("Man") }, center = { C.filepath }, right = {} },
}

function M.setup()
	local colors = require("statusline.colors")
	local highlights = require("statusline.highlights")
	local config = require("statusline.config")
	C.setup()

	highlights.setup_mode_highlights()
	config.setup({
		fg = "fg",
		bg = "NONE",
		layout = layout,
		ft = ft_layout,
		disable_ft = { "dashboard", "snacks_dashboard" },
	})

	vim.o.laststatus = 3
	vim.o.cmdheight = 0
	vim.o.statusline = "%{%v:lua.require'status.render'.render()%}"

	make_transparent()

	local group = vim.api.nvim_create_augroup("statusline.core", { clear = true })

	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = function()
			colors.clear_cache()
			highlights.clear_static_cache()
			highlights.setup_mode_highlights()
			config.reresolve_all()
			make_transparent()
			vim.cmd.redrawstatus()
		end,
	})

	vim.api.nvim_create_autocmd("ModeChanged", {
		group = group,
		callback = function()
			vim.schedule(function()
				vim.cmd.redrawstatus()
			end)
		end,
	})
end

return M
