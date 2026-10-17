---@class mdview.api
local M = {}

local KEYMAP_GROUP = "MdViewKeymap"

---@param fn fun()
local function guard(fn)
	local ok, err = xpcall(fn, debug.traceback)
	if not ok then
		vim.api.nvim_echo({ { "mdview error:\n" .. tostring(err), "ErrorMsg" } }, true, {})
	end
end

function M.start()
	guard(function()
		require("plugins.mdview.session").start()
	end)
end

function M.stop()
	guard(function()
		require("plugins.mdview.session").stop()
	end)
end

function M.toggle()
	guard(function()
		require("plugins.mdview.session").toggle()
	end)
end

---@param buf? integer
---@return boolean
function M.is_active(buf)
	return require("plugins.mdview.session").is_active(buf)
end

---@return { buf: integer, port: integer, url: string }|nil
function M.status()
	return require("plugins.mdview.session").status()
end

---@param buf integer
local function map_buffer(buf)
	local config = require("plugins.mdview.config")
	local util = require("plugins.mdview.util")
	local keymap = config.options.keymap
	if not keymap or not util.is_markdown(buf) then
		return
	end
	Utils.map.set({
		{
			keymap,
			get = function()
				return require("plugins.mdview.session").is_active(buf)
			end,
			set = function(state)
				require("plugins.mdview.session").toggle()
				util.notify.info(("%s preview server"):format(state and "Stopped" or "Started"))
			end,
			desc = function(state)
				return ("%s preview server"):format(state and "Stop" or "Start")
			end,
			notify = false,
			buffer = buf,
		},
	})
end

---@param opts? table<string, any>  overrides for mdview.Config, see config.lua
function M.setup(opts)
	local config = require("plugins.mdview.config")
	config.setup(opts)
	local cfg = config.options

	vim.api.nvim_create_user_command("MdViewStart", M.start, { desc = "Start the markdown preview" })
	vim.api.nvim_create_user_command("MdViewStop", M.stop, { desc = "Stop the markdown preview" })
	vim.api.nvim_create_user_command("MdViewToggle", M.toggle, { desc = "Toggle the markdown preview" })

	local group = vim.api.nvim_create_augroup(KEYMAP_GROUP, { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = cfg.filetypes,
		callback = function(ev)
			map_buffer(ev.buf)
		end,
	})

	-- Buffers that are already open when setup runs.
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			map_buffer(buf)
		end
	end
end

return M
