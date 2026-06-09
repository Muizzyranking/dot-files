local staged_status = {
	staged_new = true,
	staged_modified = true,
	staged_deleted = true,
	renamed = true,
}

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

local function get_current_file(base_path)
	local buf = vim.api.nvim_get_current_buf()
	if not (buf and vim.api.nvim_buf_is_valid(buf)) then
		return nil
	end
	local name = vim.api.nvim_buf_get_name(buf)
	if name == "" then
		return nil
	end
	local stat = vim.uv.fs_stat(name)
	if not stat or stat.type ~= "file" then
		return nil
	end
	local abs = vim.fn.resolve(vim.fn.fnamemodify(name, ":p"))
	local base = vim.fn.resolve(base_path)
	local escaped_base = base:gsub("([%%^$()%.%[%]*+%-?])", "%%%1")
	local rel = abs:gsub("^" .. escaped_base .. "/", "")
	if rel == "" or rel == abs then
		return nil
	end
	return rel
end

---@type snacks.picker.format
local function format_git_status(item, picker)
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
	local icon = picker.opts.icons.git[s.status]
	if s.staged then
		icon = picker.opts.icons.git.staged
	end
	local letter = s.status == "untracked" and "?" or s.status == "ignored" and "!" or s.status:sub(1, 1):upper()
	ret[#ret + 1] = { icon, hl }
	ret[#ret + 1] = { " ", virtual = true }
	ret[#ret + 1] = {
		col = 0,
		virt_text = { { letter, hl }, { " " } },
		virt_text_pos = "right_align",
		hl_mode = "combine",
	}
	return ret
end

return Snacks.picker({
	title = "FFFiles",
	live = true,
	finder = function(opts, ctx)
		local ok_fp, file_picker = pcall(require, "fff.file_picker")
		local ok_conf, conf_mod = pcall(require, "fff.conf")
		if not ok_fp or not ok_conf then
			return {}
		end

		if not file_picker.is_initialized() then
			if not file_picker.setup() then
				return {}
			end
		end

		local config = conf_mod.get() or {}
		local merged = vim.tbl_deep_extend("force", config, opts or {})
		local cwd = opts.cwd or vim.uv.cwd()
		if not cwd then
			return {}
		end

		local current_file = get_current_file(cwd)

		local results = file_picker.search_files(
			ctx.filter.search or "",
			current_file,
			opts.limit or merged.max_results,
			merged.max_threads,
			nil
		)

		local items = {}
		for _, f in ipairs(results) do
			items[#items + 1] = {
				text = f.name,
				file = f.relative_path,
				score = f.total_frecency_score,
				status = status_map[f.git_status] and {
					status = status_map[f.git_status],
					staged = staged_status[f.git_status] or false,
					unmerged = f.git_status == "unmerged",
				} or nil,
			}
		end
		return items
	end,

	format = function(item, picker)
		local ret = {}
		if item.label then
			ret[#ret + 1] = { item.label, "SnacksPickerLabel" }
			ret[#ret + 1] = { " ", virtual = true }
		end
		if item.status then
			vim.list_extend(ret, format_git_status(item, picker))
		else
			ret[#ret + 1] = { "  ", virtual = true }
		end
		vim.list_extend(ret, Snacks.picker.format.filename(item, picker))
		if item.line then
			require("snacks").picker.highlight.format(item, item.line, ret)
			table.insert(ret, { " " })
		end
		return ret
	end,

	formatters = { file = { filename_first = true } },
})
