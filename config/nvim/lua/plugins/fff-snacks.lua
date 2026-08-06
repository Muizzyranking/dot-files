local M = {}

local opts = {
	max_results = 100,
	grep_modes = { "plain", "regex", "fuzzy" },
}

----------------------------------------------------------------------
-- Dependencies
----------------------------------------------------------------------
local fff = require("fff")
local fff_conf = require("fff.conf")
local file_picker = require("fff.file_picker")
local Snacks = require("snacks")

----------------------------------------------------------------------
-- Utils
----------------------------------------------------------------------
local function get_current_file(base_path)
	local buf = vim.api.nvim_get_current_buf()
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return nil
	end
	local file = vim.api.nvim_buf_get_name(buf)
	if file == "" then
		return nil
	end
	local stat = vim.uv.fs_stat(file)
	if not stat or stat.type ~= "file" then
		return nil
	end
	local abs = vim.fn.fnamemodify(file, ":p")
	local resolved_abs = vim.fn.resolve(abs)
	local resolved_base = vim.fn.resolve(base_path)
	local escaped = resolved_base:gsub("([%%^$()%.%[%]*+%-?])", "%%%1")
	local rel = resolved_abs:gsub("^" .. escaped .. "/", "")
	if rel == "" or rel == resolved_abs then
		return nil
	end
	return rel
end

----------------------------------------------------------------------
-- Git status helpers (for find_files formatting)
----------------------------------------------------------------------
local status_map = {
	untracked = "untracked",
	modified = "modified",
	deleted = "deleted",
	renamed = "renamed",
	staged_new = "added",
	staged_modified = "modified",
	staged_deleted = "deleted",
	ignored = "ignored",
	unknown = "untracked",
}

local staged_status = {
	staged_new = true,
	staged_modified = true,
	staged_deleted = true,
	renamed = true,
}

local function format_file_git_status(item)
	local ret = {}
	local s = item.status
	local hl
	if s.unmerged then
		hl = "SnacksPickerGitStatusUnmerged"
	elseif s.staged then
		hl = "SnacksPickerGitStatusStaged"
	else
		hl = "SnacksPickerGitStatus" .. s.status:sub(1, 1):upper() .. s.status:sub(2)
	end

	local text_icon = s.status == "untracked" and "?" or s.status == "ignored" and "!" or s.status:sub(1, 1):upper()
	ret[#ret + 1] = {
		col = 0,
		virt_text = { { text_icon, hl }, { " " } },
		virt_text_pos = "right_align",
		hl_mode = "combine",
	}
	return ret
end

----------------------------------------------------------------------
-- Sources
----------------------------------------------------------------------

local function ensure_file_picker()
	if not file_picker.is_initialized() then
		if not file_picker.setup() then
			vim.notify("Failed to initialize file picker", vim.log.levels.ERROR)
			return false
		end
	end
	return true
end

-- Find files
local find_files_source = {
	title = "Files",
	live = true,
	finder = function(picker_opts, ctx)
		local cwd = picker_opts.cwd or vim.fn.getcwd()
		local current_file = get_current_file(cwd)

		local result = fff.file_search(ctx.filter.search, {
			max_results = picker_opts.limit or opts.max_results,
			current_file = current_file,
			cwd = cwd,
		})

		local items = {}
		for idx, fff_item in ipairs(result.items) do
			items[#items + 1] = {
				idx = idx,
				cwd = cwd,
				file = fff_item.relative_path,
				score = fff_item.total_frecency_score,
				text = fff_item.name,
				status = status_map[fff_item.git_status] and {
					status = status_map[fff_item.git_status],
					staged = staged_status[fff_item.git_status] or false,
					unmerged = fff_item.git_status == "unmerged",
				} or nil,
			}
		end
		return items
	end,
	format = function(item, picker)
		local ret = {}
		if item.status then
			vim.list_extend(ret, format_file_git_status(item))
		end
		vim.list_extend(ret, Snacks.picker.format.filename(item, picker))
		if item.line then
			Snacks.picker.highlight.format(item, item.line, ret)
			table.insert(ret, { " " })
		end
		return ret
	end,
	on_show = function()
		ensure_file_picker()
	end,
}

-- Live grep helpers
local function get_grep_modes(picker_opts)
	return picker_opts.grep_mode or vim.tbl_get(fff_conf.get(), "grep", "modes") or opts.grep_modes
end

local live_grep_source = {
	title = "Grep",
	format = "file",
	live = true,
	finder = function(picker_opts, ctx)
		if ctx.filter.search == "" then
			return {}
		end

		local cwd = picker_opts.cwd or vim.fn.getcwd()
		local modes = get_grep_modes(picker_opts)

		local result = fff.content_search(ctx.filter.search, {
			mode = modes[1],
			cwd = cwd,
		})

		local items = {}
		for idx, fff_item in ipairs(result.items) do
			local pos, end_pos
			if not fff_item.match_ranges or #fff_item.match_ranges == 0 then
				pos = { fff_item.line_number, 0 }
			else
				pos = { fff_item.line_number, fff_item.match_ranges[1][1] }
				end_pos = { fff_item.line_number, fff_item.match_ranges[1][2] }
			end

			local positions = {}
			if fff_item.match_ranges then
				for _, range in ipairs(fff_item.match_ranges) do
					for i = range[1] + 1, range[2] do
						positions[#positions + 1] = i
					end
				end
			end

			items[#items + 1] = {
				idx = idx,
				cwd = cwd,
				file = fff_item.relative_path,
				line = fff_item.line_content,
				pos = pos,
				end_pos = end_pos,
				positions = positions,
				score = fff_item.total_frecency_score,
				text = ("%s:%d:%d:%s"):format(fff_item.relative_path, pos[1], pos[2], fff_item.line_content),
			}
		end
		return items
	end,
	toggles = {
		_is_grep_mode_plain = { icon = "plain", value = true },
		_is_grep_mode_regex = { icon = "regex", value = true },
		_is_grep_mode_fuzzy = { icon = "fuzzy", value = true },
	},
	on_show = function(picker)
		ensure_file_picker()
		local modes = get_grep_modes(picker.opts)
		picker.opts.grep_mode = modes
		picker.opts._is_grep_mode_plain = modes[1] == "plain"
		picker.opts._is_grep_mode_regex = modes[1] == "regex"
		picker.opts._is_grep_mode_fuzzy = modes[1] == "fuzzy"
	end,
	actions = {
		cycle_grep_mode = function(picker)
			local modes = vim.deepcopy(get_grep_modes(picker.opts))
			local first = table.remove(modes, 1)
			modes[#modes + 1] = first

			picker.opts.grep_mode = modes
			picker.opts._is_grep_mode_plain = modes[1] == "plain"
			picker.opts._is_grep_mode_regex = modes[1] == "regex"
			picker.opts._is_grep_mode_fuzzy = modes[1] == "fuzzy"

			picker:refresh()
		end,
	},
	win = {
		input = {
			keys = {
				["<S-Tab>"] = { "cycle_grep_mode", mode = { "n", "i" }, nowait = true },
			},
		},
	},
}

function M.files(user_opts)
	Snacks.picker.pick(vim.tbl_deep_extend("force", find_files_source, user_opts or {}))
end

function M.grep(user_opts)
	Snacks.picker.pick(vim.tbl_deep_extend("force", live_grep_source, user_opts or {}))
end

function M.grep_word(user_opts)
	local picker_opts = vim.tbl_deep_extend("force", live_grep_source, user_opts or {})
	picker_opts.search = function(picker)
		return picker:word()
	end
	Snacks.picker.pick(picker_opts)
end

return M
