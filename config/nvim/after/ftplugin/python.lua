local buf = Utils.ensure_buf()
Utils.map.set_keymaps({
  {
    "<leader>cb",
    [[<Cmd>normal! ggO#!/usr/bin/env python3<CR><Esc>]],
    icon = { icon = " ", color = "red" },
    desc = "Add shebang (env)",
    silent = true,
  },
  {
    "<leader>cB",
    [[<Cmd>normal! ggO#!/usr/bin/python3<CR><Esc>]],
    icon = { icon = " ", color = "red" },
    desc = "Add shebang",
    silent = true,
  },
  {
    "{",
    Utils.lang.python.handle_brace,
    mode = "i",
    desc = "Insert f-string brace",
    noremap = true,
    silent = true,
  },
}, { buffer = buf })

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

Utils.root.add_patterns({
  "manage.py",
  "Pipfile",
  "pyrightconfig.json",
})
