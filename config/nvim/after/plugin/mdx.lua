vim.filetype.add({ extension = { mdx = "markdown" } })

vim.treesitter.language.register("markdown", "mdx")

vim.api.nvim_create_autocmd("FileType", {
	pattern = "mdx",
	callback = function(args)
		vim.treesitter.start(args.buf, "markdown")
	end,
})
