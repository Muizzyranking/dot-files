return {
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    version = "v0.*",
    event = "InsertEnter",
    -- build = 'cargo build --release',
    opts_extend = {
      "sources.default",
      "sources.completion.enabled_providers",
      "disable_ft",
    },
    opts = {
      -- custom props to disable blink in certain filetypes
      disable_ft = { "prompt" },
      snippets = {
        expand = function(snippet, _)
          return Utils.cmp.expand(snippet)
        end,
      },
      keymap = {
        preset = "enter",
        -- I use <c-e> to go to the end of the line in insert mode
        ["<C-e>"] = {},
        -- a as in abort makes sense to me
        ["<C-a>"] = { "hide", "fallback" },
        ["<C-y>"] = { "select_and_accept" },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
        kind_icons = Utils.icons.kinds,
      },
      signature = { enabled = false },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      -- i don't like command line completions
      cmdline = {
        enabled = false,
        sources = {},
      },
      completion = {
        list = { selection = { preselect = true, auto_insert = false } },
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          border = "rounded",
          auto_show = function(ctx)
            return ctx.mode ~= "cmdline" or not vim.tbl_contains({ "/", "?" }, vim.fn.getcmdtype())
          end,
          winblend = 0,
          draw = {
            treesitter = { "lsp" },
            columns = { { "kind_icon" }, { "label", "label_description" }, { "kind", gap = 1 } },
            components = {},
          },
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = {
            border = "rounded",
            winblend = 0,
          },
        },
        ghost_text = {
          enabled = false,
        },
      },
    },
    config = function(_, opts)
      local disabled_filetypes = opts.disable_ft or {}
      opts.enabled = function()
        -- will use to disable completions on certain filetypes
        return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype) and vim.b.completion ~= false
      end
      opts.sources.compat = nil
      opts.disable_ft = nil

      for _, provider in pairs(opts.sources.providers or {}) do
        if provider.kind then
          local CompletionItemKind = require("blink.cmp.types").CompletionItemKind
          local kind_idx = #CompletionItemKind + 1

          CompletionItemKind[kind_idx] = provider.kind
          CompletionItemKind[provider.kind] = kind_idx

          local transform_items = provider.transform_items
          provider.transform_items = function(ctx, items)
            items = transform_items and transform_items(ctx, items) or items
            for _, item in ipairs(items) do
              item.kind = kind_idx or item.kind
            end
            return items
          end
          provider.kind = nil
        end
      end
      require("blink.cmp").setup(opts)
    end,
  },
}
