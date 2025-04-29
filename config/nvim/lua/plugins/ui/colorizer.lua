return {
  "catgoose/nvim-colorizer.lua",
  event = "BufReadPre",
  opts = {
    filetypes = {
      "*",
      html = {},
      css = {},
      javascript = {},
      javascriptreact = {},
    },
    user_default_options = {
      names = false,
      hooks = {
        disable_line_highlight = function(line, _, bufnr)
          local function is_comment(left_comment, right_comment)
            if line:match("^%s*//") then
              return true
            end
            if line:match("{%s*/%*") and line:match("%*/%s*}") then
              return true
            end
            local trimmed_line = vim.trim(line)
            if right_comment then
              return trimmed_line:sub(1, #left_comment) == left_comment
                or trimmed_line:sub(-#right_comment) == right_comment
            else
              return trimmed_line:sub(1, #left_comment) == left_comment
            end
          end
          local comment_string = vim.api.nvim_get_option_value("commentstring", { buf = bufnr })
          local left_comment, right_comment = comment_string:match("^(.-)%s*%%s%s*(.-)%s*$")
          left_comment = vim.trim(left_comment or comment_string)
          right_comment = vim.trim(right_comment or "")
          return is_comment(left_comment, right_comment)
        end,
      },
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
    Utils.map.toggle_map({
      "<leader>uh",
      get_state = function(buf)
        return require("colorizer").is_buffer_attached(buf)
      end,
      change_state = function(state, buf)
        require("colorizer")[state and "detach_from_buffer" or "attach_to_buffer"](buf)
      end,
      name = "Color highlight",
    })
    opts = opts or {}
    for _, ft in ipairs({ "css", "html", "javascript", "javascriptreact", "jsx" }) do
      opts.filetypes[ft] = vim.tbl_extend("keep", {}, opts.filetypes[ft] or {}, {
        names = true,
        names_opts = {
          lowercase = true,
          uppercase = true,
          camelcase = true,
          strip_digits = false,
        },
        names_custom = {},
        tailwind = true,
      })
      opts.filetypes.htmldjango = opts.filetypes.html
    end
    require("colorizer").setup(opts)
  end,
}
