local buf = Utils.fn.ensure_buf()

vim.bo[buf].shiftwidth = 2
vim.bo[buf].tabstop = 2

local django_root = Utils.root.find_pattern_root(buf, {
	"manage.py",
	"settings.py",
	"urls.py",
})

if django_root ~= nil then
	vim.bo[buf].filetype = "htmldjango"
	return
end

local fastapi_root = Utils.root.find_pattern_root(buf, {
	"main.py",
	"app.py",
	"pyproject.toml",
	"requirements.txt",
})

if fastapi_root ~= nil then
	local markers = { "pyproject.toml", "requirements.txt", "main.py", "app.py" }
	local is_fastapi = false

	for _, marker in ipairs(markers) do
		local path = fastapi_root .. "/" .. marker
		if vim.fn.filereadable(path) == 1 then
			local content = table.concat(vim.fn.readfile(path), "\n"):lower()
			if content:match("fastapi") then
				is_fastapi = true
				break
			end
		end
	end

	if is_fastapi then
		vim.bo[buf].filetype = "htmldjango"
	end
end
