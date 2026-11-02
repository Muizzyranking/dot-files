local function is_native(bin)
	if vim.fn.executable(bin) ~= 1 then
		return false
	end
	local out = vim.system({ bin, "--version" }, { text = true }):wait()
	local version = vim.version.parse(out.stdout or "")
	return out.code == 0 and version ~= nil and version.major >= 7
end

return {
	cmd = function(dispatchers, config)
		local bin = "tsc"
		local root = (config or {}).root_dir
		local local_bin = root and vim.fs.joinpath(root, "node_modules/.bin/tsc")
		if local_bin and is_native(local_bin) then
			bin = local_bin
		end
		return vim.lsp.rpc.start({ bin, "--lsp", "--stdio" }, dispatchers)
	end,
	filetypes = {
		"javascript",
		"javascriptreact",
		"typescript",
		"typescriptreact",
	},
	root_dir = function(bufnr, on_dir)
		local markers = { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" }
		if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
			return
		end
		on_dir(vim.fs.root(bufnr, { markers, { ".git" } }) or vim.fn.getcwd())
	end,
	settings = {
		["js/ts"] = {
			inlayHints = {
				parameterNames = {
					enabled = "literals",
					suppressWhenArgumentMatchesName = true,
				},
				parameterTypes = { enabled = true },
				variableTypes = { enabled = false },
				propertyDeclarationTypes = { enabled = true },
				functionLikeReturnTypes = { enabled = false },
				enumMemberValues = { enabled = true },
			},
			referencesCodeLens = {
				enabled = true,
				showOnAllFunctions = true,
			},
			implementationsCodeLens = {
				enabled = true,
				showOnInterfaceMethods = true,
				showOnAllClassMethods = true,
			},
		},
	},
}
