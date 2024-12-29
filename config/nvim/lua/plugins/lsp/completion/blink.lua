return {
  {
    "nvim-cmp",
    optional = true,
    enabled = false,
  },
  {
    "saghen/blink.cmp",
    dependencies = {
      "rafamadriz/friendly-snippets",
      {
        "saghen/blink.compat",
        opts = {},
        version = "*",
      },
    },
    version = "v0.*",
    event = "InsertEnter",
    -- build = 'cargo build --release',
    opts_extend = {
      "sources.default",
      "sources.compat",
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
        ["<CR>"] = { "accept", "fallback" },
        ["<C-y>"] = { "select_and_accept" },
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        -- cmdline = {
        --   preset = "enter",
        --   ["<CR>"] = { "accept", "fallback" },
        --   ["<C-y>"] = { "select_and_accept" },
        --   ["<esc>"] = {
        --     "hide",
        --     "cancel",
        --     -- HACK:stop esc from exeuting commands in insert mode
        --     -- from https://github.com/Saghen/blink.cmp/issues/547
        --     function()
        --       if vim.fn.getcmdtype() ~= "" then
        --         vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-c>", true, true, true), "n", true)
        --         return
        --       end
        --     end,
        --   },
        -- },
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono",
        kind_icons = Utils.icons.kinds,
      },
      signature = { enabled = false },
      sources = {
        default = { "lsp", "snippets", "buffer", "path" },
        compat = {},
        -- disable for now, it is messing with tab completion
        -- TODO: try later
        cmdline = {},
      },
      completion = {
        accept = {
          auto_brackets = {
            enabled = true,
          },
        },
        menu = {
          border = "rounded",
          winblend = 0,
          draw = {
            treesitter = { "lsp" },
            columns = { { "kind_icon" }, { "label", "label_description" }, { "kind", gap = 1 } },
            components = {
              kind = {
                ellipsis = false,
                width = { fill = true },
                text = function(ctx)
                  return ("(%s)"):format(ctx.kind)
                end,
                highlight = function(ctx)
                  return (require("blink.cmp.completion.windows.render.tailwind").get_hl(ctx) or "BlinkCmpKind")
                    .. ctx.kind
                end,
              },
            },
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
      for _, source in ipairs(opts.sources.compat or {}) do
        opts.sources.providers[source] = vim.tbl_deep_extend(
          "force",
          { name = source, module = "blink.compat.source" },
          opts.sources.providers[source] or {}
        )
        if type(opts.sources.default) == "table" and not vim.tbl_contains(opts.sources.default, source) then
          table.insert(opts.sources.default, source)
        end
      end
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
