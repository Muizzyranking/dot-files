return {
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    build = ":Copilot auth",
    event = "BufReadPost",
    opts = {
      should_attach = function()
        if vim.b.bigfile then return false end

        return true
      end,
      suggestion = { enabled = false },
      panel = { enabled = false },
      filetypes = {
        markdown = true,
        help = true,
        sh = function()
          local filename = vim.fs.basename(Utils.get_filepath())
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
      local lualine_utils = Utils.plugins.lualine
      local colors = {
        [""] = lualine_utils.fg("Special"),
        ["Normal"] = lualine_utils.fg("Special"),
        ["Warning"] = lualine_utils.fg("DiagnosticError"),
        ["InProgress"] = lualine_utils.fg("DiagnosticWarn"),
        ["Error"] = lualine_utils.fg("DiagnosticError"),
      }
      local status_icons = {
        [""] = Utils.icons.kinds.Copilot,
        ["Normal"] = Utils.icons.kinds.Copilot,
        ["Warning"] = " ",
        ["InProgress"] = " ",
        ["Error"] = " ",
      }
      table.insert(opts.sections.lualine_y, 1, {
        function()
          if not package.loaded["copilot"] then return status_icons[""] end
          local ok, status = pcall(function()
            return require("copilot.status").data
          end)
          if not ok or not status then return status_icons[""] end
          return status_icons[status.status] or status_icons[""]
        end,
        cond = function()
          if not package.loaded["copilot"] then return end
          local ok, clients = pcall(Utils.lsp.get_clients, { name = "copilot", bufnr = 0 })
          if not ok then return false end
          return ok and #clients > 0
        end,
        color = function()
          if not package.loaded["copilot"] then return end
          local ok, status = pcall(function()
            return require("copilot.status").data
          end)
          if not ok or not status then return colors[""] end
          return colors[status.status] or colors[""]
        end,
      })
    end,
  },
}
