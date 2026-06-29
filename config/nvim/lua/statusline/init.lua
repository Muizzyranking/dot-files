---@class Statusline
local M = {}
local C = require("statusline.components")
local utils = require("statusline.utils")

local DEFAULT_SEP = "%#StatuslineSep# │ %#StatuslineNC#"

---@param comp Statusline.Component
---@param is_first_left boolean
---@return string|nil body, string|nil left_sep, string|nil right_sep
local function render_one(comp, is_first_left)
	local ok, content = pcall(comp.render)
	if not ok or content == nil or content == "" then
		return nil
	end

	if comp.raw then
		return content, nil, nil
	end

	local fill_group = utils.fill_group(comp.hl, comp.fill)
	local body = utils.wrap(fill_group, content)

	if is_first_left then
		local right_sep = utils.render_sep(utils.config.default_fill_sep, fill_group)
		return body, nil, right_sep
	end

	local sep = comp.sep or {}
	local left_sep = utils.render_sep(sep.left, fill_group)
	local right_sep = utils.render_sep(sep.right, fill_group)
	return body, left_sep ~= "" and left_sep or nil, right_sep ~= "" and right_sep or nil
end

---@param components Statusline.Component[]
---@param is_left_section boolean  true for the `left` section
---@return string
local function render_section(components, is_left_section)
	local out = {}
	local pending_right_sep = nil

	for i, comp in ipairs(components) do
		local body, left_sep, right_sep = render_one(comp, is_left_section and i == 1)
		if body then
			if #out > 0 then
				if not pending_right_sep and not left_sep then
					table.insert(out, DEFAULT_SEP)
				else
					if pending_right_sep then
						table.insert(out, pending_right_sep)
					end
					if left_sep then
						table.insert(out, left_sep)
					end
				end
			end
			table.insert(out, body)
			pending_right_sep = right_sep
		end
	end

	if pending_right_sep then
		table.insert(out, pending_right_sep)
	end

	return table.concat(out)
end

-- ============================================================
-- Layouts
-- ============================================================

---@type Statusline.Layout
local default_layout = {
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

local hidden_ft = {
	dashboard = true,
	snacks_dashboard = true,
}

local function picker_title()
	local picker = Snacks and Snacks.picker and Snacks.picker.get()[1]
	return (picker and picker.title) or "Picker"
end

---@type table<string, Statusline.Layout>
local ft_layouts = {
	lazygit = {
		left = { C.label(" Lazygit"), C.branch },
		center = {},
		right = {},
	},

	snacks_picker_list = {
		left = {
			C.new({
				render = function()
					return string.format("🍿 %s", picker_title())
				end,
				fill = true,
			}),
			C.new({
				hl = "StatuslineBranch",
				render = function()
					return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
				end,
			}),
		},
		center = {},
		right = {
			C.new({
				hl = "StatuslinePosition",
				render = function()
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
			C.new({
				render = function()
					return string.format("🍿 %s", picker_title())
				end,
				fill = true,
			}),
			C.new({
				hl = "StatuslinePosition",
				render = function()
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

---@return string
function M.render()
	local buf = utils.stbuf()
	local ft = vim.bo[buf].filetype

	if hidden_ft[ft] then
		return ""
	end

	local layout = ft_layouts[ft] or default_layout
	local left = render_section(layout.left, true)
	local center = render_section(layout.center, false)
	local right = render_section(layout.right, false)

	return left .. "%=" .. center .. "%=" .. right .. " "
end

---Add or replace a per-filetype layout.
---@param ft string
---@param layout Statusline.Layout
function M.add_filetype(ft, layout)
	ft_layouts[ft] = layout
end

---@param section "left"|"center"|"right"
---@param comp Statusline.Component
---@param pos? integer
function M.add_component(section, comp, pos)
	local s = default_layout[section]
	if pos then
		table.insert(s, pos, comp)
	else
		table.insert(s, comp)
	end
end

function M.setup()
	C.setup()
	vim.o.laststatus = 3
	vim.o.cmdheight = 0
	local group = vim.api.nvim_create_augroup("custom.statusline", { clear = true })
	require("statusline.hl").setup(group)

	vim.api.nvim_create_autocmd({
		"ModeChanged",
		"RecordingEnter",
		"RecordingLeave",
		"CmdlineEnter",
		"CmdlineLeave",
		"CursorHold",
		"CursorHoldI",
		"WinScrolled",
	}, {
		group = group,
		callback = function()
			vim.schedule(function()
				vim.cmd.redrawstatus()
			end)
		end,
	})

	vim.o.statusline = "%!v:lua.require('statusline').render()"
end

return M
