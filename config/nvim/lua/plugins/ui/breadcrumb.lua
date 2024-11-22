return {
  "Bekaboo/dropbar.nvim",
  event = "LazyFile",
  enabled = not vim.g.neovide,
  opts = {
    bar = {
      hover = true,
      sources = function(buf, _)
        local utils = require("dropbar.utils")
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
      end,
    },
  },
}