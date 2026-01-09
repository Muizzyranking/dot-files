local hooks = require("config.lsp.hooks")

vim.diagnostic.config({
  underline = true,
  update_in_insert = false,
  virtual_text = false,
  float = {
    border = "single",
    source = true,
    max_width = 100,
  },
  severity_sort = true,
  signs = (function()
    local signs = { text = {}, numhl = {} }
    for name, icon in pairs(Utils.icons.diagnostics) do
      local severity = vim.diagnostic.severity[name:upper()]
      signs.text[severity] = icon
      signs.numhl[severity] = "DiagnosticSign" .. name
    end
    return signs
  end)(),
})

vim.lsp.config("*", {
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
        relativePatternSupport = true,
      },
      fileOperations = {
        didRename = true,
        willRename = true,
      },
    },
  },
})

Utils.lsp.setup()
hooks.run()
