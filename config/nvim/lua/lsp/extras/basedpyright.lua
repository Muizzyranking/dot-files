---@type LspExtras
return {
	enabled = true,
	keys = {
		{
			"<leader>ci",
			function()
				vim.lsp.buf.code_action({
					filter = function(a)
						return a.title:find("import") ~= nil and a.kind == "quickfix"
					end,
					apply = true,
				})
			end,
			desc = "Auto import word under cursor",
			icon = { icon = "󰋺 ", color = "blue" },
		},
	},
	on_attach = function(client, bufnr)
		local root = Utils.root(bufnr)
		local venv = Utils.python.detect_and_activate_venv(root)
		if venv and venv.python_path then
			local new_settings = vim.tbl_deep_extend("force", client.config.settings or {}, {
				python = { pythonPath = venv.python_path },
			})

			client.config.settings = new_settings
			client:notify("workspace/didChangeConfiguration", { settings = new_settings })
		end
		local augroup = vim.api.nvim_create_augroup("basedpyright_config_" .. bufnr, { clear = true })
		vim.api.nvim_create_autocmd("BufWritePost", {
			group = augroup,
			pattern = "pyrightconfig.json",
			callback = function()
				Utils.lsp.restart("basedpyright")
				vim.cmd("stopinsert")
				vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
			end,
		})
	end,
}
