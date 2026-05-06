---@class utils.format
local M = setmetatable({}, {
	__call = function(m, opts)
		return m.format(opts)
	end,
})

local api = vim.api
----------------------------------------------------
-- Check if autoformat is enabled for the given buffer
---@param buf? number The buffer to check. Defaults to the current buffer if nil.
---@return boolean Whether autoformat is enabled for the buffer.
----------------------------------------------------
function M.enabled(buf)
	buf = Utils.fn.ensure_buf(buf)
	local gaf = vim.g.autoformat
	local baf = vim.b[buf].autoformat

	if baf ~= nil then
		return baf
	end

	return gaf == nil or gaf
end

local function notify(buf)
	local global_af = vim.g.autoformat == nil or vim.g.autoformat
	local buf_af = vim.b[buf].autoformat
	local enabled = M.enabled(buf)

	local lines = {
		"# Status",
		("- [%s] global **%s**"):format(global_af and "x" or " ", global_af and "enabled" or "disabled"),
		("- [%s] buffer **%s**"):format(
			enabled and "x" or " ",
			buf_af == nil and "inherit" or buf_af and "enabled" or "disabled"
		),
	}

	Utils.notify[enabled and "info" or "warn"](
		lines,
		{ title = "AutoFormat (" .. (enabled and "enabled" or "disabled") .. ")" }
	)
end

----------------------------------------------------
--- Toggle autoformat for a buffer or globally
--- @param buf? number Buffer number to toggle (optional)
--- @param enable? boolean Explicitly enable or disable (optional)
----------------------------------------------------
function M.toggle(buf, enable)
	local current_buf = Utils.fn.ensure_buf(buf)
	local gaf = vim.g.autoformat == nil or vim.g.autoformat
	local baf = vim.b[current_buf].autoformat

	if buf then
		if enable == nil then
			enable = not M.enabled(current_buf)
		end
		vim.b[current_buf].autoformat = enable
	else
		if enable == nil then
			if baf == true and not gaf then
				enable = true
			else
				enable = not gaf
			end
		end

		vim.g.autoformat = enable
		if not enable then
			vim.b[current_buf].autoformat = nil
		end
	end

	notify(current_buf)
end

----------------------------------------------------
--- Format the current buffer using Conform or LSP
---@param opts? table Options for formatting
---@see conform.format
---@see vim.lsp.buf.format
----------------------------------------------------
function M.format(opts)
	if Pack.has("conform.nvim") then
		-- ensure conform is loaded
		Pack.load("conform.nvim")
		local ok, conform = pcall(require, "conform")
		if ok then
			conform.format(opts)
			return
		end
	end
	vim.lsp.buf.format(opts)
end

function M.setup()
	api.nvim_create_autocmd("BufWritePre", {
		group = api.nvim_create_augroup("utils.format", { clear = true }),
		callback = function(event)
			if M.enabled() then
				M.format({ bufnr = event.buf, force = true })
			end
		end,
	})
end

return M
