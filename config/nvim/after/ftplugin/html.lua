local buf = Utils.fn.ensure_buf()
local root = Utils.root.find_pattern_root(buf, {
  "manage.py",
  "urls.py",
  "settings.py",
  "templates/",
})
if root ~= nil then
  vim.bo[buf].filetype = "htmldjango"
end
