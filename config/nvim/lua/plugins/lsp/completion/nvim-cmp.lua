return {
  {
    "saghen/blink.cmp",
    optional = true,
    enabled = false,
  },
  {
    -- "hrsh7th/nvim-cmp",
    "iguanacucumber/magazine.nvim",
    name = "nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      {
        "garymjr/nvim-snippets",
        opts = {
          friendly_snippets = true,
        },
        dependencies = { "rafamadriz/friendly-snippets" },
      },
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
    },
    opts_extend = {
      "disable_ft",
    },
    keys = {
      {
        "<Tab>",
        function()
          return vim.snippet.active({ direction = 1 }) and "<cmd>lua vim.snippet.jump(1)<cr>" or "<Tab>"
        end,
        expr = true,
        silent = true,
        mode = { "i", "s" },
      },
      {
        "<S-Tab>",
        function()
          return vim.snippet.active({ direction = -1 }) and "<cmd>lua vim.snippet.jump(-1)<cr>" or "<S-Tab>"
        end,
        expr = true,
        silent = true,
        mode = { "i", "s" },
      },
    },
    opts = function()
      vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
      local cmp = require("cmp")
      return {
        disbale_ft = { "prompt" },
        snippet = {
          expand = function(args)
            Utils.cmp.expand_snippet(args.body)
          end,
        },
        completion = {
          completeopt = "menu,menuone,noinsert",
        },
        auto_bracket = {
          "python",
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
          ["<C-a>"] = cmp.mapping.abort(),
          ["<Cr>"] = cmp.mapping.confirm({ select = true }),
          ["<C-y>"] = cmp.mapping.complete(),
          ["<C-Tab>"] = cmp.mapping.complete({}),
        }),
        sources = {
          { name = "nvim_lsp" },
          { name = "snippets" },
          { name = "path" },
          { name = "buffer" },
        },
        window = {
          completion = {
            border = "rounded",
            col_offset = 0,
            side_padding = 0,
          },
          documentation = {
            border = "rounded",
            max_width = 80,
            max_height = 12,
          },
        },
        -- experimental = { ghost_text = { hl_group = "CmpGhostText" } },
        formatting = {
          format = function(entry, item)
            local kind = item.kind
            local icons = Utils.icons.kinds
            local kind_hl_group = ("CmpItemKind%s"):format(kind)

            if icons[item.kind] then
              item.kind = icons[item.kind]
            end

            local source = entry.source.name
            if source == "nvim_lsp" or source == "path" then
              item.menu_hl_group = kind_hl_group
            else
              item.menu_hl_group = "Comment"
            end
            item.menu = kind

            if source == "buffer" then
              item.menu_hl_group = nil
              item.menu = nil
            end

            local half_win_width = math.floor(vim.api.nvim_win_get_width(0) * 0.5)
            if vim.api.nvim_strwidth(item.abbr) > half_win_width then
              item.abbr = ("%s…"):format(item.abbr:sub(1, half_win_width))
            end

            if item.menu then
              item.abbr = ("%s "):format(item.abbr)
              item.menu = "(" .. item.menu .. ")"
            end

            return item
          end,
          fields = { "kind", "abbr", "menu" },
        },
      }
    end,
    config = function(_, opts)
      opts = opts or {}
      local disabled_filetypes = opts.disable_ft or {}
      opts.enabled = function()
        return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype) and vim.b.completion ~= false
      end
      opts.disable_ft = nil
      require("cmp").setup(opts)
    end,
  },
}
