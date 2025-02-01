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
      hooks = {},
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
    local buf = vim.api.nvim_get_current_buf()
    Utils.map.toggle_map({
      "<leader>uh",
      get_state = function()
        return require("colorizer").is_buffer_attached(buf)
      end,
      change_state = function(state)
        require("colorizer")[state and "detach_from_buffer" or "attach_to_buffer"](buf)
      end,
      name = "Color highlight",
    })
    local function is_comment(line, left_comment, right_comment)
      -- First check standard line comments
      if line:match("^%s*//") then
        return true
      end

      -- Then check JSX-style block comments
      if line:match("{%s*/%*") and line:match("%*/%s*}") then
        return true
      end
      local trimmed_line = vim.trim(line)
      if right_comment then
        -- Check for block comments (e.g., /* ... */)
        return trimmed_line:sub(1, #left_comment) == left_comment or trimmed_line:sub(-#right_comment) == right_comment
      else
        -- Check for single-line comments (e.g., //, #, --)
        return trimmed_line:sub(1, #left_comment) == left_comment
      end
    end
    opts = opts or {}
    opts.filetypes = opts.filetypes or {}
    opts.user_default_options.hooks = opts.user_default_options.hooks or {}
    opts.user_default_options.hooks.disable_line_highlight = function(line, line_nr, bufnr)
      local comment_string = vim.api.nvim_buf_get_option(bufnr, "commentstring")

      local left_comment, right_comment = comment_string:match("^(.-)%s*%%s%s*(.-)%s*$")
      left_comment = vim.trim(left_comment or comment_string)
      right_comment = vim.trim(right_comment or "")
      return is_comment(line, left_comment, right_comment)
    end
    for _, ft in ipairs({ "css", "html", "javascript", "javascriptreact" }) do
      opts.filetypes[ft] = vim.tbl_extend("force", {}, opts.filetypes[ft] or {}, {
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
    end
    require("colorizer").setup(opts)
  end,
}
