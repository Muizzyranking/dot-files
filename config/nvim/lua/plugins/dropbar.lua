return {
  "Bekaboo/dropbar.nvim",
  dependencies = {},
  event = { "LspAttach" },
  config = function()
    local dropbar = require("dropbar")
    local sources = require("dropbar.sources")
    local utils = require("dropbar.utils")
    dropbar.setup({
      bar = {
        sources = function(buf, _)
          if vim.bo[buf].ft == "markdown" then
            return { sources.markdown }
          end
          if vim.bo[buf].buftype == "terminal" then
            return { sources.terminal }
          end
          return {
            utils.source.fallback({ sources.lsp }),
          }
        end,
      },
    })
  end,
}
