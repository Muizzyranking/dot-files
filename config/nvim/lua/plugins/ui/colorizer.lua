return {
  -- "NvChad/nvim-colorizer.lua",
  "catgoose/nvim-colorizer.lua",
  event = "BufReadPre",
  opts = function()
    local bufnr = vim.api.nvim_get_current_buf()
    Utils.toggle_map({
      "<leader>uh",
      get_state = function()
        return require("colorizer").is_buffer_attached(bufnr) > 1
      end,
      change_state = function(state)
        require("colorizer")[state and "detach_from_buffer" or "attach_to_buffer"](bufnr)
      end,
      name = "Color highlight",
    })
    return {
      filetypes = { "*" },
      user_default_options = {
        names = true,
        RGB = true,
        RRGGBB = true,
        RRGGBBAA = false,
        AARRGGBB = false,
        rgb_fn = false,
        hsl_fn = false,
        css = false,
        css_fn = false,
        mode = "virtualtext",
        tailwind = "both",
        sass = { enable = false, parsers = { "css" } },
        virtualtext = "",
        virtualtext_inline = true,
        virtualtext_mode = "foreground",
        always_update = false,
      },
      buftypes = {},
      user_commands = true,
    }
  end,
}
