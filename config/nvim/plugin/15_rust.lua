Pack.add({
	{ src = "Saecki/crates.nvim" },
	{ src = "mrcjkb/rustaceanvim" },
})

Pack.on_ft("rust", function()
	local opts = {
		server = {
			on_attach = function(_, bufnr)
				vim.keymap.set("n", "<leader>cR", function()
					vim.cmd.RustLsp("codeAction")
				end, { desc = "Code Action", buffer = bufnr })
				vim.keymap.set("n", "<leader>dr", function()
					vim.cmd.RustLsp("debuggables")
				end, { desc = "Rust Debuggables", buffer = bufnr })
			end,
			default_settings = {
				["rust-analyzer"] = {
					cargo = {
						allFeatures = true,
						loadOutDirsFromCheck = true,
						buildScripts = {
							enable = true,
						},
					},
					checkOnSave = true,
					diagnostics = { enable = true },
					procMacro = { enable = true },
					files = {
						exclude = {
							".direnv",
							".git",
							".jj",
							".github",
							".gitlab",
							"bin",
							"node_modules",
							"target",
							"venv",
							".venv",
						},
						watcher = "client",
					},
				},
			},
		},
	}
	if Pack.has("mason.nvim") then
		local codelldb = vim.fn.exepath("codelldb")
		local codelldb_lib_ext = io.popen("uname"):read("*l") == "Linux" and ".so" or ".dylib"
		local library_path = vim.fn.expand("$MASON/opt/lldb/lib/liblldb" .. codelldb_lib_ext)
		opts.dap = {
			adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb, library_path),
		}
	end
	vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
	if vim.fn.executable("rust-analyzer") == 0 then
		Utils.notify.error(
			"**rust-analyzer** not found in PATH, please install it.\nhttps://rust-analyzer.github.io/",
			{ title = "rustaceanvim" }
		)
	end
end, "rustaceanvim")

vim.api.nvim_create_autocmd("BufRead", {
	pattern = "Cargo.toml",
	once = true,
	desc = "[pack] on_event for crates.nvim",
	callback = function()
		Pack.now(function()
			require("crates").setup({
				completion = {
					crates = { enabled = true },
				},
				lsp = { enabled = true, actions = true, completion = true, hover = true },
			})
		end, "crates.nvim")
	end,
})
