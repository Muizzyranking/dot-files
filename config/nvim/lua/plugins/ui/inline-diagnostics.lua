return {
  {
    "rachartier/tiny-inline-diagnostic.nvim",
    event = "LazyFile",
    priority = 1000,
    opts = {
      preset = "modern",
      transparent_bg = false,
      hi = {
        error = "InlineDiagnosticError",
        warn = "InlineDiagnosticWarn",
        info = "InlineDiagnosticInfo",
        hint = "InlineDiagnosticHint",
      },

      options = {
        use_icons_from_diagnostic = true,
        show_all_diags_on_cursorline = false,
        -- Custom format function for diagnostic messages
        -- Example:
        -- format = function(diagnostic)
        --     return diagnostic.message .. " [" .. diagnostic.source .. "]"
        -- end
        format = nil,
      },
      disabled_ft = {},
    },
  },
}
