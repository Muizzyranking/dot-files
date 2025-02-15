return {
  "folke/snacks.nvim",
  lazy = false,
  priority = 1000,
  init = function()
    -- enter vim.ui in normal mode
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.ui.select = function(...)
      local result = Snacks.picker.select(...)
      -- start the picker in normal mode
      vim.schedule(function()
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
      end)
      return result
    end
  end,
  opts = {
    input = {},
    bigfile = {
      enabled = true,
      size = vim.g.big_file,
    },
    notifier = { enabled = true },
    quickfile = { enabled = true },
    statuscolumn = { enabled = false },
    words = { enabled = true },
    scroll = { enabled = true },
    lazygit = {
      win = {
        bo = {
          filetype = "lazygit",
        },
      },
      config = {
        git = { overrideGpg = true },
      },
    },
  },
  keys = {
    {
      "<leader>.",
      function()
        Snacks.scratch()
      end,
      desc = "Toggle Scratch Buffer",
    },
    {
      "<leader>S",
      function()
        Snacks.scratch.select()
      end,
      desc = "Select Scratch Buffer",
    },
    {
      "<leader>cs",
      function()
        Snacks.picker.lsp_symbols({
          layout = { preset = "vscode", preview = "main" },
          on_show = function()
            vim.cmd("stopinsert")
          end,
        })
      end,
      desc = "Lsp Symbols",
    },
  },
  config = function(_, opts)
    local notify = vim.notify
    require("snacks").setup(opts)
    if Utils.has("noice.nvim") then
      vim.notify = notify
    end
  end,
}
