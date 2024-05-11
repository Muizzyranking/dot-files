return { -- Autocompletion
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    {
      "L3MON4D3/LuaSnip",
      build = (function()
        if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
          return
        end
        return "make install_jsregexp"
      end)(),
    },
    "saadparwaiz1/cmp_luasnip",

    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-path",
    "zbirenbaum/copilot-cmp",
  },
  config = function()
    -- See `:help cmp`
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    local defaults = require("cmp.config.default")()
    luasnip.config.setup({})

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = { completeopt = "menu,menuone,noinsert" },

      mapping = cmp.mapping.preset.insert({
        -- Select the [n]ext item
        ["<C-n>"] = cmp.mapping.select_next_item(),
        -- Select the [p]revious item
        ["<C-p>"] = cmp.mapping.select_prev_item(),

        -- Accept ([y]es) the completion.
        ["<Cr>"] = cmp.mapping.confirm({ select = true }),

        -- Manually trigger a completion from nvim-cmp.
        ["<C-Tab>"] = cmp.mapping.complete({}),

        -- <c-l> will move you to the right of each of the expansion locations.
        -- <c-h> is similar, except moving you backwards.
        ["<C-l>"] = cmp.mapping(function()
          if luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          end
        end, { "i", "s" }),

        ["<C-h>"] = cmp.mapping(function()
          if luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          end
        end, { "i", "s" }),
      }),
      sources = {
        { name = "nvim_lsp" },
        { name = "lspconfig" },
        { name = "luasnip" },
        { name = "path" },
        {
          name = "copilot",
          group_index = 1,
          priority = 100,
        },
      },
      sorting = {
        defaults.sorting,
        comparators = { require("clangd_extensions.cmp_scores") },
      },
      window = {
        completion = {
          winhighlight = "Normal:Pmenu,FloatBorder:Pmenu,Search:None",
          border = "rounded",
          col_offset = 0,
          side_padding = 0,
        },
        documentation = {
          border = "rounded",
          winhighlight = "Normal:CmpDoc,FloatBorder:CmpDoc,Search:None",
          max_width = 80,
          max_height = 12,
        },
      },
      auto_bracket = {},
      formatting = {
        format = function(_, item)
          local icons = require("config.util").icons.kinds
          if icons[item.kind] then
            item.kind = icons[item.kind]
          end
          return item
        end,
      },
    })
  end,
}