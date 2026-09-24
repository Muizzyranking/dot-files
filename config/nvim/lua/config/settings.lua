-- bunch of custom settings
---@class Settings
local M = {}

M.lsp = {
	python = { server = "ty" },
	typescript = { server = "tsgo" },
}

M.parsers = {
	"c",
	"cpp",
	"vim",
	"vimdoc",
	"query",
	"python",
	"toml",
	"rst",
	"regex",
	"yaml",
	"diff",
	"jsdoc",
	"luadoc",
	"lua",
	"luadoc",
	"luap",
	"python",
	"ninja",
	"rst",
	"htmldjango",
	"vim",
	"xml",
	"puppet",
	"typescript",
	"javascript",
	"tsx",
	"bash",
	"rasi",
	"git_config",
	"cpp",
	"go",
	"gomod",
	"gowork",
	"gosum",
	"gdscript",
	"html",
	"css",
	"http",
	"graphql",
	"json",
	"json5",
	"jsonc",
	"rust",
	"ron",
	"php",
	"phpdoc",
	"qml",
	"qmldir",
	"qmljs",
	"dockerfile",
	"vue",
}

M.servers = {
	"basedpyright",
	"bash-language-server",
	"clangd",
	"emmet-language-server",
	"eslint-lsp",
	"html-lsp",
	"css-lsp",
	"json-lsp",
	"lua-language-server",
	"ruff",
	"tailwindcss-language-server",
	"tsgo",
	"vtsls",
	"lua-language-server",
	"djlint",
	"prettierd",
	"biome",
	"stylua",
	"shfmt",
	"jq",
	"stylua",
	"ty",
	"rust-analyzer",
	"codelldb",
	"bacon",
	"kulala-fmt",
	"vue-language-server",
	"goimports",
	"gofumpt",
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
