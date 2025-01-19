return {
  "catgoose/nvim-colorizer.lua",
  event = "BufReadPre",
  opts = {
    filetypes = {
      "*",
      html = {
        names = true,
        names_opts = {
          lowercase = true,
          uppercase = true,
          camelcase = true,
          strip_digits = false,
        },
        names_custom = {},
        tailwind = true,
      },
      css = {},
      javascript = {},
      javascriptreact = {},
    },
    user_default_options = {
      names = false,
      names_custom = {},
      RGB = true,
      RRGGBB = true,
      RRGGBBAA = true,
      AARRGGBB = true,
      rgb_fn = true,
      hsl_fn = true,
      css = true,
      css_fn = true,
      mode = "background",
      sass = { enable = false, parsers = { "css" } },
      virtualtext = "",
      virtualtext_inline = true,
      virtualtext_mode = "foreground",
      always_update = false,
    },
    buftypes = {},
    user_commands = true,
    lazy_load = false,
  },
  config = function(_, opts)
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
    opts = opts or {}
    opts.filetypes = opts.filetypes or {}
    for _, ft in ipairs({ "css", "html", "javascript", "javascriptreact" }) do
      opts.filetypes[ft] = vim.tbl_extend("force", {}, opts.filetypes[ft] or {}, opts.filetypes.html or {})
    end
    require("colorizer").setup(opts)
  end,
}
