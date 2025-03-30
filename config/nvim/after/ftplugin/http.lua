local buf = vim.api.nvim_get_current_buf()
Utils.map.create_abbrevs({
  { "post", "POST" },
  { "get", "GET" },
  { "patch", "PATCH" },
  { "put", "PUT" },
}, {
  buffer = buf,
  builtin = "lsp_keyword",
})
