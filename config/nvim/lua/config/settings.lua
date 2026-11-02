-- bunch of custom settings
---@class Settings
local M = {}

M.lsp = {
	python = { server = "ty" },
	typescript = { server = "tsc" },
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

---@param path string|string[]
---@param default any
---@return any
function M.get(path, default)
	if type(path) == "string" then
		path = vim.split(path, ".", { plain = true })
	end

	local current = M
	for _, key in ipairs(path) do
		if type(current) ~= "table" then
			return default
		end
		current = current[key]
		if current == nil then
			return default
		end
	end
	return current
end

return M
