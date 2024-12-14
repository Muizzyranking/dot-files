local function should_use_blink()
  if vim.g.use_cmp then
    return false
  end
  if (vim.g.use_cmp == nil or vim.g.use_cmp ~= false) and vim.g.use_blink then
    return true
  end
  return false
end

return {
  { import = ("plugins.lsp.completion.%s"):format(should_use_blink() and "blink" or "nvim-cmp") },
}
