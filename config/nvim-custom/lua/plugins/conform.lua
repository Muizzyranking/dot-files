return { -- Autoformat
	"stevearc/conform.nvim",
	event = "BufWritePre",
	opts = {
		notify_on_error = true,
		format_on_save = {
			timeout_ms = 500,
			lsp_fallback = true,
		},
		formatters_by_ft = {
			lua = { "stylua" },
			-- python = { "black" },
		},
	},
}
