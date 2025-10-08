local buf = Utils.ensure_buf()
local root = Utils.root.find_pattern_root(buf, {
  "manage.py",
  "urls.py",
  "settings.py",
  "templates/",
})
if root ~= nil then vim.bo[buf].filetype = "htmldjango" end

Utils.map.create_abbrevs({
  { "True", { "true", "ture" } },
  { "False", { "false", "flase" } },
  { "class", { "Class", "calss" } },
  { "None", { "none", "NONE", "nil", "Nil" } },
}, {
  buffer = buf,
  conds = { "lsp_keyword" },
})

Utils.word_cycle.add_filetype_cycles("python", {
  { "True", "False" },
  { "and", "or" },
  { "def", "class" },
  { "return", "yield" },
})
