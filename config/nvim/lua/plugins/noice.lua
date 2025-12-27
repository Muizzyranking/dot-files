return {
  "folke/noice.nvim",
  event = "VeryLazy",
  opts = {
    lsp = {
      progress = { enabled = true, view = "mini" },
      override = {
        ["vim.lsp.util.convert_input_to_markdown_lines"] = false,
        ["vim.lsp.util.stylize_markdown"] = false,
        ["cmp.entry.get_documentation"] = false,
      },
      signature = {
        enabled = true,
        auto_open = { enabled = false, trigger = true },
      },
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
    },
    views = {
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
      lsp_doc_border = true,
      inc_rename = true,
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
