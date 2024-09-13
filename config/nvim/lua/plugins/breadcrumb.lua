return {
  "Bekaboo/dropbar.nvim",
  event = "LazyFile",
  opts = {
    bar = {
      hover = true,
    },
  },
  config = function(_, opts)
    local utils = require("dropbar.utils")
    opts.bar = opts.bar or {}
    opts.bar.sources = function(buf, _)
      local sources = require("dropbar.sources")
      if vim.bo[buf].ft == "markdown" then
        return {
          sources.markdown,
        }
      end
      if vim.bo[buf].buftype == "terminal" then
        return {
          sources.terminal,
        }
      end
      return {
        utils.source.fallback({
          sources.lsp,
          sources.treesitter,
        }),
      }
    end
    require("dropbar").setup(opts)
  end,
}
