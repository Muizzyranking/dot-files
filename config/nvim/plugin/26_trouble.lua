Pack.add({ src = "folke/trouble.nvim" })

Pack.on_key({
	{ "<leader>xX", "Trouble diagnostics toggle", desc = "Diagnostics (Trouble)" },
	{ "<leader>xx", "Trouble diagnostics toggle filter.buf=0", desc = "Buffer Diagnostics (Trouble)" },
	{ "<leader>xq", "Trouble quickfix toggle", desc = "Diagnostics (Trouble)" },
	{ "<leader>xL", "Trouble loclist toggle", desc = "Location List (Trouble)" },
	{ "<leader>xQ", "Trouble qflist toggle", desc = "Quickfix List (Trouble)" },
	{
		"[q",
		function()
			if require("trouble").is_open() then
				---@diagnostic disable-next-line: missing-fields, missing-parameter
				require("trouble").prev({ skip_groups = true, jump = true })
			else
				local ok, err = pcall(vim.cmd.cprev)
				if not ok then
					Utils.notify.error(err, { title = "Trouble" })
				end
			end
		end,
		desc = "Previous Trouble/Quickfix Item",
	},
	{
		"]q",
		function()
			if require("trouble").is_open() then
				---@diagnostic disable-next-line: missing-fields, missing-parameter
				require("trouble").next({ skip_groups = true, jump = true })
			else
				local ok, err = pcall(vim.cmd.cnext)
				if not ok then
					Utils.notify.error(err, { title = "Trouble" })
				end
			end
		end,
		desc = "Next Trouble/Quickfix Item",
	},
}, function()
	require("trouble").setup({
		use_diagnostic_signs = true,
		modes = {
			symbols = {
				desc = "document symbols",
				mode = "lsp_document_symbols",
				focus = false,
				win = { position = "left" },
			},
		},
	})
end, "trouble.nvim")
