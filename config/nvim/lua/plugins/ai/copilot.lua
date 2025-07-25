return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "BufReadPost",
    opts = {
      should_attach = function()
        if vim.b.bigfile then
          return false
        end

        return true
      end,
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
        sh = function()
          local filename = vim.fs.basename(Utils.get_filename())
          if
            string.match(filename, "^%.env")
            or string.match(filename, "^%.secret.*")
            or string.match(filename, "^%id_rsa.*")
          then
            return false
          end
          return true
        end,
      },
    },
  },
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = { "giuxtaposition/blink-cmp-copilot" },
    opts = {
      sources = {
        default = { "copilot" },
        providers = {
          copilot = {
            name = "copilot",
            module = "blink-cmp-copilot",
            kind = "Copilot",
            score_offset = 100,
            async = true,
          },
        },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      local colors = {
        [""] = Utils.lualine.fg("Special"),
        ["Normal"] = Utils.lualine.fg("Special"),
        ["Warning"] = Utils.lualine.fg("DiagnosticError"),
        ["InProgress"] = Utils.lualine.fg("DiagnosticWarn"),
      }
      table.insert(opts.sections.lualine_y, 1, {
        function()
          local icon = Utils.icons.kinds.Copilot
          return icon
        end,
        cond = function()
          if not package.loaded["copilot"] then
            return
          end
          local ok, clients = pcall(Utils.lsp.get_clients, { name = "copilot", bufnr = 0 })
          if not ok then
            return false
          end
          return ok and #clients > 0
        end,
        color = function()
          if not package.loaded["copilot"] then
            return
          end
          local ok, status = pcall(function()
            return require("copilot.status").data
          end)
          if not ok or not status then
            return colors[""]
          end
          return colors[status.status] or colors[""]
        end,
      })
    end,
  },
}
