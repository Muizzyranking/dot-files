return {
  -- "NvChad/nvim-colorizer.lua",
  "catgoose/nvim-colorizer.lua",
  event = "BufReadPre",
  opts = function()
    local bufnr = vim.api.nvim_get_current_buf()
    Utils.toggle_map({
      "<leader>uh",
      get_state = function()
        return require("colorizer").is_buffer_attached(bufnr)
      end,
      change_state = function(state)
        require("colorizer")[state and "detach_from_buffer" or "attach_to_buffer"](bufnr)
      end,
      name = "Color highlight",
    })
    return {
      filetypes = {
        "*",
        html = { names = true },
        css = { names = true },
        javascript = { names = true },
        javascriptreact = { names = true },
      },
      user_default_options = {
        names = false,
        RGB = true,
        RRGGBB = true,
        RRGGBBAA = true,
        AARRGGBB = true,
        rgb_fn = true,
        hsl_fn = true,
        css = true,
        css_fn = true,
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
