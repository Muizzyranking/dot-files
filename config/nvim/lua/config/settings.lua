-- bunch of custom settings
---@class Settings
local M = {}

M.lsp = {
	python = { server = "ty" },
	typescript = { server = "tsgo" },
}

local function load_local_overrides()
	local cwd = vim.fn.getcwd()
	local local_config = vim.fn.glob(cwd .. "/.nvim.lua")
	if local_config ~= "" then
		local ok, overrides = pcall(dofile, local_config)
		if ok and type(overrides) == "table" then
			M = vim.tbl_deep_extend("force", M, overrides)
		end
	end
end

load_local_overrides()

return M
