return {
  "folke/noice.nvim",
  event = "VeryLazy",
  lazy = true,
  opts = {
    lsp = {
      progress = {
        enabled = true,
        view = "mini",
      },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
        ["vim.lsp.util.stylize_markdown"] = true,
        ["cmp.entry.get_documentation"] = true,
      },
      signature = { enabled = true },
    },
    routes = {
      {
        filter = {
          event = "msg_show",
          any = {
            { find = "%d+L, %d+B" },
            { find = "; after #%d+" },
            { find = "; before #%d+" },
          },
        },
      },
      {
        filter = {
          event = "notify",
          find = "No information available",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          find = "No items, skipping git ignored/status lookups",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          find = "not attached to buffer",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          find = "Toggling hidden files",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          find = "Neo-tree INFO",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          find = "fewer lines;",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          find = "more line;",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "notify",
          kind = "",
          find = "fewer lines;",
        },
        opts = { skip = true },
      },
      {
        filter = {
          event = "msg_show",
          kind = "",
          find = "fewer lines;",
        },
        opts = { skip = true },
      },
      { filter = { find = "fewer line;" }, opts = { skip = true } },
      { filter = { find = "more lines;" }, opts = { skip = true } },
      { filter = { find = "less;" }, opts = { skip = true } },
      { filter = { find = "Already at newest" }, view = "mini" },
      { filter = { find = "Already at oldest" }, view = "mini" },
      { filter = { find = "change;" }, opts = { skip = true } },
      { filter = { find = "changes;" }, opts = { skip = true } },
      { filter = { find = "indent" }, opts = { skip = true } },
      { filter = { find = "move" }, opts = { skip = true } },

      -- Disable "search messages"
      {
        filter = { event = "msg_show", kind = "wmsg", find = "search hit BOTTOM, continuing at TOP" },
        opts = { skip = true },
      },
      {
        filter = { event = "msg_show", kind = "wmsg", find = "search hit TOP, continuing at BOTTOM" },
        opts = { skip = true },
      },
      {
        filter = { event = "msg_show", find = "written" },
        opts = { skip = true },
      },
    },
    views = {
      cmdline_popup = {
        border = {
          style = "rounded",
        },
        filter_options = {},
        win_options = {
          winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder",
        },
      },
      mini = {
        win_options = {
          winblend = 0,
        },
      },
    },
    presets = {
      bottom_search = true,
      command_palette = true,
      long_message_to_split = true,
      inc_rename = true,
      lsp_doc_border = true,
    },
  },
  keys = {
    {
      "<c-f>",
      function()
        if not require("noice.lsp").scroll(4) then
          return "<c-f>"
        end
      end,
      silent = true,
      expr = true,
      desc = "Scroll forward",
      mode = { "n" },
    },
    {
      "<c-b>",
      function()
        if not require("noice.lsp").scroll(-4) then
          return "<c-b>"
        end
      end,
      silent = true,
      expr = true,
      desc = "Scroll backward",
      mode = { "n" },
    },
  },
}
