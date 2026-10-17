--- Launches the Chrome app window, with a profile of its own for each session.
---@class mdview.browser
local M = {}

local uv = vim.uv

---@param url string
---@param profile string
---@param on_close fun()
---@return vim.SystemObj|nil
function M.open(url, profile, on_close)
	local util = require("plugins.mdview.util")
	local cfg = require("plugins.mdview.config").options

	if Utils.fn.is_executable(cfg.browser) then
		util.notify.warn(cfg.browser .. " not found, opening the default browser")
		vim.ui.open(url)
		return nil
	end

	vim.fn.mkdir(profile, "p")
	return vim.system({
		cfg.browser,
		"--app=" .. url,
		"--user-data-dir=" .. profile,
		"--no-first-run",
		"--no-default-browser-check",
	}, {}, function()
		vim.schedule(function()
			vim.fn.delete(profile, "rf")
			on_close()
		end)
	end)
end

function M.cleanup_stale()
	local util = require("plugins.mdview.util")
	local root = util.cache_dir() .. "/profiles"
	if vim.fn.isdirectory(root) == 0 then
		return
	end
	for name in vim.fs.dir(root) do
		local pid = tonumber(name:match("^(%d+)%-"))
		if pid and not uv.kill(pid, 0) then
			vim.fn.delete(root .. "/" .. name, "rf")
		end
	end
end

return M
