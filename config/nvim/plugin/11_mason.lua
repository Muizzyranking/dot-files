local servers = {
	"basedpyright",
	"bash-language-server",
	-- "clangd",
	"emmet-language-server",
	"html-lsp",
	"css-lsp",
	"json-lsp",
	"lua-language-server",
	"ruff",
	"tailwindcss-language-server",
	"tsc",
	"lua-language-server",
	"djlint",
	"biome",
	"stylua",
	"shfmt",
	"jq",
	"ty",
	"rust-analyzer",
	"codelldb",
	"bacon",
	"kulala-fmt",
	-- "goimports",
	-- "gofumpt",
}

Pack.on_changed("mason.nvim", function()
	vim.cmd("MasonUpdate")
end, "update")

Pack.add({ "mason-org/mason.nvim" })

Pack.when({
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
}, function()
	local mason = require("mason")
	local mr = require("mason-registry")
	mason.setup({ ensure_installed = servers })
	mr:on("package:install:success", function()
		vim.schedule(function()
			vim.api.nvim_exec_autocmds("FileType", {
				group = "filetypedetect",
				buffer = vim.api.nvim_get_current_buf(),
			})
		end)
	end)

	mr.refresh(function()
		for _, tool in ipairs(servers) do
			local p = mr.get_package(tool)
			if not p:is_installed() then
				p:install()
			end
		end
	end)
end, "mason.nvim")
