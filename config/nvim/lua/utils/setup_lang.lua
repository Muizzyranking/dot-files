---@class utils.setup_lang

-----------------------------------------------------------------
--- Normalize a plugin configuration to ensure it has a filetype.
---@param plugin string|table Plugin configuration
---@return table Normalized plugin configuration
-----------------------------------------------------------------
local function normalize_plugin(plugin)
  if type(plugin) == "string" then
    return { plugin }
  end

  return plugin
end

-----------------------------------------------------------------
--- Normalize a value to ensure it’s always a list.
---@param value any Input value
---@return table Listified value
-----------------------------------------------------------------
local function ensure_list(value)
  if type(value) == "string" then
    return { value }
  end
  return value
end

-----------------------------------------------------------------
-- Create an autocmd with additional options.
---@param event string|string[]
---@param pattern string|string[]
---@param callback fun(event: table)
-----------------------------------------------------------------
local function create_autocmd(event, pattern, callback)
  local opts = {
    pattern = pattern,
    callback = callback,
  }
  vim.api.nvim_create_autocmd(event, opts)
end

-----------------------------------------------------------------
---@param config AddFt
---@return vim.filetype.add.filetypes
-----------------------------------------------------------------
local function setup_detection(config)
  local filetype_config = {}

  -- Simply copy over the detection configurations
  for _, detect_type in ipairs({ "extension", "filename", "pattern" }) do
    if config[detect_type] then
      filetype_config[detect_type] = config[detect_type]
    end
  end

  return filetype_config
end
-----------------------------------------------------------------
-- Setup a language configuration.
---@param config LanguageConfig
---@return table plugins
-----------------------------------------------------------------
local function setup_language(config)
  -- Set defaults
  assert(config.name, "LanguageConfig must have a 'name'")
  config.ft = ensure_list(config.ft or config.name) ---@type string[]

  local plugins = {}

  -- Setup filetype detection
  if config.add_ft then
    vim.filetype.add(setup_detection(config.add_ft))

    if config.add_ft.filetype then
      for orig, target in pairs(config.add_ft.filetype) do
        create_autocmd("FileType", orig, function(event)
          vim.api.nvim_buf_set_option(event.buf, "filetype", target)
        end)
      end
    end
  end

  -- Setup custom autocmds
  if config.autocmds then
    for _, autocmd in ipairs(config.autocmds) do
      local callback = autocmd.callback or function()
        vim.cmd(autocmd.command)
      end
      create_autocmd(autocmd.events or "FileType", autocmd.pattern or config.ft or {}, callback)
    end
  end

  -- LSP Configuration
  if config.lsp then
    table.insert(plugins, {
      "neovim/nvim-lspconfig",
      opts = config.lsp,
    })
  end

  -- Formatting Configuration
  if config.formatting then
    local conform_opts = {
      formatters = config.formatting.formatters or {},
      formatters_by_ft = config.formatting.formatters_by_ft or {},
    }

    if config.formatting.use_prettier then
      -- if use_prettier is a boolean, use it for all filetypes
      if type(config.formatting.use_prettier) == "boolean" and config.formatting.use_prettier == true then
        conform_opts.use_prettier = config.ft
      else
        conform_opts.use_prettier = config.formatting.use_prettier
      end
    end

    table.insert(plugins, {
      "stevearc/conform.nvim",
      opts = conform_opts,
    })

    if config.formatting.format_on_save and config.formatting.format_on_save ~= false then
      vim.api.nvim_create_autocmd("FileType", {
        pattern = config.ft,
        callback = function(event)
          vim.b[event.buf].autoformat = true
        end,
      })
    end
  end

  -- Linting Configuration
  if config.linting then
    table.insert(plugins, {
      "mfussenegger/nvim-lint",
      opts = config.linting,
    })
  end

  -- Treesitter Configuration
  if config.highlighting then
    local base_parsers = config.highlighting.parsers or {}
    local treesitter_opts

    if config.highlighting.custom_parsers then
      treesitter_opts = function(_, opts)
        -- Ensure opts.ensure_installed exists and is a table
        opts.ensure_installed = opts.ensure_installed or {}

        -- Add base parsers
        for _, parser in ipairs(base_parsers) do
          table.insert(opts.ensure_installed, parser)
        end

        -- Configure custom parsers
        local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
        for name, parser_info in pairs(config.highlighting.custom_parsers) do
          parser_config[name] = parser_info
          vim.treesitter.language.register(name, name)
          if not vim.tbl_contains(base_parsers, name) then
            table.insert(opts.ensure_installed, name)
          end
        end

        return opts
      end
    else
      treesitter_opts = {
        ensure_installed = base_parsers,
      }
    end
    table.insert(plugins, {
      "nvim-treesitter/nvim-treesitter",
      opts = treesitter_opts,
    })
  end

  -- Icons Configuration
  if config.icons then
    table.insert(plugins, {
      "echasnovski/mini.icons",
      opts = config.icons,
    })
  end

  -- Comments Configuration
  if config.commentstring then
    local opts = {}
    if type(config.commentstring) == "string" then
      ---@diagnostic disable-next-line: param-type-mismatch
      for _, ft in ipairs(config.ft) do
        opts[ft] = config.commentstring
      end
    elseif type(config.commentstring) == "table" then
      ---@type table<string, string>
      local comment_table = config.commentstring
      for ft, commentstring in pairs(comment_table) do
        opts[ft] = commentstring
      end
    end
    table.insert(plugins, {
      "folke/ts-comments.nvim",
      optional = true,
      opts = {
        lang = opts,
      },
    })
  end

  -- Add custom plugins
  if config.plugins then
    for _, plugin in ipairs(config.plugins) do
      table.insert(plugins, normalize_plugin(plugin))
    end
  end

  -- Setup filetype-specific keymaps
  if config.keys then
    create_autocmd("Filetype", config.ft, function(event)
      for _, mapping in ipairs(config.keys) do
        mapping.buffer = event.buf
      end
      Utils.map(config.keys)
    end)
  end

  -- Setup filetype-specific options
  if config.options then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = config.ft,
      callback = function(event)
        for option, value in pairs(config.options) do
          vim.bo[event.buf][option] = value
        end
      end,
    })
  end

  return plugins
end

return setup_language
