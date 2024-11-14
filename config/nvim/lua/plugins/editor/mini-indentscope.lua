return {
  "echasnovski/mini.indentscope",
  version = false,
  event = "LazyFile",
  opts = {
    -- symbol = "▏",
    symbol = "│",
    options = { try_as_border = true },
  },
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = {
        "help",
        "alpha",
        "dashboard",
        "neo-tree",
        "Trouble",
        "trouble",
        "lazy",
        "mason",
        "notify",
        "toggleterm",
        "lazyterm",
        "toggleterm",
        "lazygit",
      },
      callback = function()
        vim.b.miniindentscope_disable = true
      end,
    })
  end,
}
