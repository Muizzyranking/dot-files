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
	mason.setup({
		ensure_installed = Settings.get("servers", {}),
	})
	mr:on("package:install:success", function()
		vim.schedule(function()
			vim.api.nvim_exec_autocmds("FileType", {
				group = "filetypedetect",
				buffer = vim.api.nvim_get_current_buf(),
			})
		end)
	end)

	local tools = Settings.get("servers", {})
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
end, "mason.nvim")
