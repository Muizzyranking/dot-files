local ls = require("luasnip")
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node

ls.add_snippets("python", {
  s("#!/usr", {
    t("#!/usr/bin/python3"),
  }),
})

ls.add_snippets("python", {
  s("#!/usr", {
    t("#!/usr/bin/env python3"),
  }),
})
