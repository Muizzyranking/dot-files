return {
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = {
      formatters = {
        ["markdown-toc"] = {
          condition = function(_, ctx)
            for _, line in ipairs(vim.api.nvim_buf_get_lines(ctx.buf, 0, -1, false)) do
              if line:find("<!%-%- toc %-%->") then
                return true
              end
            end
          end,
        },
        ["markdownlint-cli2"] = {
          condition = function(_, ctx)
            local diag = vim.tbl_filter(function(d)
              return d.source == "markdownlint"
            end, vim.diagnostic.get(ctx.buf))
            return #diag > 0
          end,
        },
      },
      formatters_by_ft = {
        ["markdown"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
        ["markdown.mdx"] = { "prettier", "markdownlint-cli2", "markdown-toc" },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = { ensure_installed = { "markdownlint-cli2", "markdown-toc" } },
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        marksman = {},
      },
    },
  },
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "markdown",
        "markdown_inline",
      },
    },
  },
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
    opts = function()
      return {
        checkboxes = {
          enable = true,
          checked = {
            text = "",
            hl = "MarkviewCheckboxChecked",
            scope_hl = "MarkviewCheckboxStriked",
          },
          unchecked = {
            text = "",
            hl = "MarkviewCheckboxUnchecked",
          },
          custom = {
            {
              match_string = "-",
              text = "",
              hl = "MarkviewCheckboxPending",
            },
            {
              match_string = "~",
              text = "",
              hl = "MarkviewCheckboxProgress",
            },
            {
              match_string = "o",
              text = "",
              hl = "MarkviewCheckboxCancelled",
            },
          },
          ---_
        },
        headings = {
          enable = true,
          shift_width = 0,

          heading_1 = {
            style = "label",
            sign = "󰌕 ",
            sign_hl = "MarkviewHeading1Sign",

            padding_left = " ",
            padding_right = " ",
            icon = "󰼏  ",
            hl = "MarkviewHeading1",
          },
          heading_2 = {
            style = "label",
            sign = "󰌖 ",
            sign_hl = "MarkviewHeading2Sign",

            padding_left = " ",
            padding_right = " ",
            icon = "󰎨  ",
            hl = "MarkviewHeading2",
          },
          heading_3 = {
            style = "label",

            padding_left = " ",
            padding_right = " ",
            icon = "󰼑  ",
            hl = "MarkviewHeading3",
          },
          heading_4 = {
            style = "label",

            padding_left = " ",
            padding_right = " ",
            icon = "󰎲  ",
            hl = "MarkviewHeading4",
          },
          heading_5 = {
            style = "label",

            padding_left = " ",
            padding_right = " ",
            icon = "󰼓  ",
            hl = "MarkviewHeading5",
          },
          heading_6 = {
            style = "label",

            padding_left = " ",
            padding_right = " ",
            icon = "󰎴  ",
            hl = "MarkviewHeading6",
          },
          ---_
        },
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
          enable = true,
          icons = "internal",
          style = "language",
          hl = "CursorLine",
          info_hl = "CursorLine",
          min_width = 40,
          pad_amount = 3,
          pad_char = " ",
          language_direction = "right",
          sign = true,
          sign_hl = nil,
        },
      }
    end,
  },
}
