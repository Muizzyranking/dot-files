---@class mdview.config
local M = {}

---@alias mdview.ImageRootFn fun(buf: integer): string|nil

---@class mdview.Config
---@field enabled boolean|fun(): boolean
---@field browser string
---@field filetypes string[]
---@field keymap string|false
---@field render_debounce integer
---@field image_root string|mdview.ImageRootFn|nil
---@field max_image_bytes integer

---@type mdview.Config
M.defaults = {
	enabled = true,
	browser = "google-chrome-stable",
	filetypes = { "markdown", "markdown.pandoc", "markdown.mdx" },
	keymap = "<leader>mp",
	render_debounce = 250,
	-- nil means "the markdown file's directory". Return the git root to allow ../assets/x.png.
	image_root = nil,
	max_image_bytes = 20 * 1024 * 1024,
}

---@type mdview.Config
M.options = vim.deepcopy(M.defaults)

---@param opts? table<string, any>
function M.setup(opts)
	M.options = vim.tbl_extend("force", M.defaults, opts or {}) --[[@as mdview.Config]]
end

---@return boolean
function M.is_enabled()
	local e = M.options.enabled
	if type(e) == "function" then
		return e() == true
	end
	return e == true
end

return M
