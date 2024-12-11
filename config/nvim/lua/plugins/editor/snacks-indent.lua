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
    "snacks_dashboard",
  },
  callback = function()
    Snacks.indent.disable()
  end,
})
return {
  "folke/snacks.nvim",
  opts = {
    indent = {
      indent = {
        enabled = true, -- enable indent guides
        char = "│",
        blank = " ",
        only_scope = false,
        only_current = false,
        hl = "SnacksIndent",
      },
      animate = {
        enabled = vim.fn.has("nvim-0.10") == 1,
        style = "out",
        easing = "linear",
        duration = {
          step = 20,
          total = 500,
        },
      },
      scope = {
        enabled = true,
        char = "│",
        underline = false,
        only_current = false,
        hl = "SnacksIndentScope",
      },
      chunk = {
        enabled = true,
        only_current = true,
        hl = "SnacksIndentChunk",
        char = {
          -- corner_top = "┌",
          -- corner_bottom = "└",
          corner_top = "╭",
          corner_bottom = "╰",
          horizontal = "─",
          vertical = "│",
          arrow = ">",
        },
      },
      blank = {
        char = " ",
        hl = "SnacksIndentBlank",
      },
      -- filter for buffers to enable indent guides
      filter = function(buf)
        return vim.g.snacks_indent ~= false and vim.b[buf].snacks_indent ~= false and vim.bo[buf].buftype == ""
      end,
      priority = 200,
    },
  },
}
