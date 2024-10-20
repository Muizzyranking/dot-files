return {
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      {
        "<leader>cp",
        ft = "markdown",
        "<cmd>MarkdownPreviewToggle<cr>",
        desc = "Markdown Preview",
      },
    },
    config = function()
      vim.cmd([[do FileType]])
    end,
  },
  {
    "OXY2DEV/markview.nvim",
    ft = { "markdown", "norg", "rmd", "org" },
    opts = {
      checkboxes = { enable = false },
      links = {
        inline_links = {
          hl = "@markup.link.label.markown_inline",
          icon = " ",
          icon_hl = "@markup.link",
        },
        images = {
          hl = "@markup.link.label.markown_inline",
          icon = " ",
          icon_hl = "@markup.link",
        },
      },
      code_blocks = {
        style = "minimal",
        pad_amount = 0,
      },
      list_items = {
        shift_width = 2,
        marker_minus = { text = "●", hl = "@markup.list.markdown" },
        marker_plus = { text = "●", hl = "@markup.list.markdown" },
        marker_star = { text = "●", hl = "@markup.list.markdown" },
        marker_dot = {},
      },
      inline_codes = { enable = false },
      headings = {
        heading_1 = {
          hl = "@markup.heading.1.markdown",
          -- corner_right = "",
          corner_right = nil,
          style = "label",
          shift_char = "",
          shift_hl = nil,
          sign = nil,
          sign_hl = nil,
          corner_left = nil,
          corner_left_hl = nil,
          padding_left = " ",
          padding_left_hl = nil,
          padding_right = " ",
          padding_right_hl = nil,
          corner_right_hl = nil,
        },
        heading_2 = {
          style = "label",
          hl = "@markup.heading.2.markdown",
          shift_char = "",
          shift_hl = nil,
          sign = nil,
          sign_hl = nil,
          corner_left_hl = nil,
          corner_left = nil,
          padding_left = " ",
          padding_left_hl = nil,
          padding_right = " ",
          padding_right_hl = nil,
          corner_right = nil,
          corner_right_hl = nil,
        },
        heading_3 = {
          style = "label",
          hl = "@markup.heading.3.markdown",
          shift_char = "",
          shift_hl = nil,
          sign = nil,
          sign_hl = nil,
          corner_left = nil,
          corner_left_hl = nil,
          padding_left = " ",
          padding_left_hl = nil,
          padding_right = " ",
          padding_right_hl = nil,
          corner_right = nil,
          corner_right_hl = nil,
        },
        heading_4 = {
          style = "label",
          hl = "@markup.heading.4.markdown",
          shift_char = "",
          shift_hl = nil,
          sign = nil,
          sign_hl = nil,
          corner_left = nil,
          corner_left_hl = nil,
          padding_left = " ",
          padding_left_hl = nil,
          padding_right = " ",
          padding_right_hl = nil,
          corner_right = nil,
          corner_right_hl = nil,
        },
        heading_5 = {
          style = "label",
          hl = "@markup.heading.5.markdown",
          shift_char = "",
          shift_hl = nil,
          sign = nil,
          sign_hl = nil,
          corner_left = nil,
          corner_left_hl = nil,
          padding_left = " ",
          padding_left_hl = nil,
          padding_right = " ",
          padding_right_hl = nil,
          corner_right = nil,
          corner_right_hl = nil,
        },
        heading_6 = {
          style = "label",
          hl = "@markup.heading.6.markdown",
          shift_char = "",
          shift_hl = nil,
          sign = nil,
          sign_hl = nil,
          corner_left = nil,
          corner_left_hl = nil,
          padding_left = " ",
          padding_left_hl = nil,
          padding_right = " ",
          padding_right_hl = nil,
          corner_right = nil,
          corner_right_hl = nil,
        },
      },
    },
  },
}
