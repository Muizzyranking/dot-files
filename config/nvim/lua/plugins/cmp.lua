local notify = require("utils.notify")
return { -- Autocompletion
  "hrsh7th/nvim-cmp",
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
    "zbirenbaum/copilot-cmp",
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
  config = function()
    vim.api.nvim_set_hl(0, "CmpGhostText", { link = "Comment", default = true })
    local cmp = require("cmp")
    -- local defaults = require("cmp.config.default")()
    cmp.setup({
      snippet = {
        expand = function(args)
          local snippet = args.body
          local function snippet_preview(s)
            local ok, parsed = pcall(vim.lsp._snippet_grammar.parse, s)
            if ok then
              return tostring(parsed)
            else
              return s:gsub("%${%d+:(.-)}", "%1"):gsub("%$%d+", ""):gsub("%$0", "")
            end
          end

          -- Helper function to fix snippet format
          local function snippet_fix(s)
            local texts = {}
            return s:gsub("%$%b{}", function(m)
              local n, name = m:match("^%${(%d+):(.+)}$")
              if n then
                texts[n] = texts[n] or snippet_preview(name)
                return "${" .. n .. ":" .. texts[n] .. "}"
              end
              return m
            end)
          end

          -- Store the current snippet session
          local session = vim.snippet.active() and vim.snippet._session or nil

          -- Attempt to expand the snippet
          local ok, err = pcall(vim.snippet.expand, snippet)

          if not ok then
            -- If expansion fails, try to fix the snippet and expand again
            local fixed = snippet_fix(snippet)
            ok = pcall(vim.snippet.expand, fixed)

            -- Prepare notification message
            local msg = ok and "Failed to parse snippet, but was able to fix it automatically."
              or ("Failed to parse snippet.\n" .. err)

            -- Notify the user
            notify[ok and "warn" or "error"](
              ([[%s
                ```%s
                %s
                ```]]):format(msg, vim.bo.filetype, snippet),
              { title = "vim.snippet" }
            )
          end

          -- Restore the original snippet session if necessary
          if session then
            vim.snippet._session = session
          end
        end,
      },
      completion = {
        completeopt = "menu,menuone,noinsert",
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<Cr>"] = cmp.mapping.confirm({ select = true }),
        ["<C-y>"] = cmp.mapping.complete(),
        ["<C-Tab>"] = cmp.mapping.complete({}),
      }),
      sources = {
        {
          name = "copilot",
          group_index = 1,
          priority = 100,
        },
        { name = "nvim_lsp" },
        { name = "path" },
        { name = "buffer" },
        { name = "snippets" },
        { name = "lazydev", group_index = 0 },
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
      auto_bracket = {},
      experimental = {
        ghost_text = {
          hl_group = "CmpGhostText",
        },
      },
      formatting = {
        format = function(entry, item)
          local kind = item.kind
          local icons = require("utils.icons").kinds
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
    })
  end,
}
