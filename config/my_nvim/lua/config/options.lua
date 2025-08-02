local opt, o = vim.opt, vim.o


opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.fillchars= {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}
