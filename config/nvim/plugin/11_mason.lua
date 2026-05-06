local ensure_installed = {
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
}

Pack.on_changed("mason.nvim", function()
	vim.cmd("MasonUpdate")
end, "update")

Pack.add({ src = "mason-org/mason.nvim" })

Pack.lazy("mason.nvim", {
	lazy_file = true,
	keys = {
		{
			"<leader>cm",
			function()
				vim.cmd("Mason")
			end,
			desc = "Mason",
		},
	},
	config = function()
		local mason = require("mason")
		local mr = require("mason-registry")
		mason.setup({
			ensure_installed = ensure_installed,
		})
		mr:on("package:install:success", function()
			vim.schedule(function()
				vim.api.nvim_exec_autocmds("FileType", {
					group = "filetypedetect",
					buffer = vim.api.nvim_get_current_buf(),
				})
			end)
		end)

		local tools = ensure_installed
		local function ensure_install()
			for _, tool in ipairs(tools) do
				local p = mr.get_package(tool)
				if not p:is_installed() then
					p:install()
				end
			end
		end

		mr.refresh(function()
			ensure_install()
		end)
	end,
})
