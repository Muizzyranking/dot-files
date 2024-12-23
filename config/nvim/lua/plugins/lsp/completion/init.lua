return {
  { import = ("plugins.lsp.completion.%s"):format(should_use_blink() and "blink" or "nvim-cmp") },
}
