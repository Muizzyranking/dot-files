local buf = Utils.ensure_buf(0)
Utils.map.create_abbrevs({
  { "POST", { "post", "Post" } },
  { "GET", { "get", "Get" } },
  { "PATCH", { "patch", "Patch" } },
  { "PUT", { "put", "Put" } },
}, {
  buffer = buf,
  conds = { "lsp_keyword" },
})
