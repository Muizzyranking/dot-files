return Utils.setup_lang({
  name = "sql",
  lsp = {
    servers = {
      sqlls = {},
    },
  },
  formatting = {
    formatters = {
      sqlfluff = {
        args = { "format", "--dialect=ansi", "-" },
      },
    },
    formatters_by_ft = {
      ["sql"] = { "sqlfluff" },
      ["mysql"] = { "sqlfluff" },
      ["plsql"] = { "sqlfluff" },
    },
  },
  highlighting = {
    parsers = {
      "sql",
    },
  },
})
