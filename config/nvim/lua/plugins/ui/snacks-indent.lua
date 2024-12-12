return {
  "folke/snacks.nvim",
  opts = {
    indent = {
      indent = {
        enabled = true,
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
        enabled = false,
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
