---@class utils.setup_lang

local api = vim.api
local schedule = vim.schedule
local create_augroup = api.nvim_create_augroup
local nvim_create_autocmd = api.nvim_create_autocmd
local set_buf_option = api.nvim_buf_set_option

-----------------------------------------------------------------
-- TODO: proper plugin handling
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
-- Create an augroup for language-specific autocommands
---@param config_name string Name of the language configuration
---@return function create_grouped_autocmd Function to create autocmds in this group
-----------------------------------------------------------------
local function create_autocmd_group(config_name)
  local group_name = string.format("language_setup_%s", config_name)
  local group = create_augroup(group_name, { clear = true })
  local lazy_load = vim.fn.argc(-1) == 0

  ---@param event string|string[]
  ---@param pattern string|string[]
  ---@param callback fun(event: table)
  return function(event, pattern, callback)
    if not lazy_load then
      nvim_create_autocmd(event, {
        group = group,
        pattern = pattern,
        callback = callback,
      })
    else
      schedule(function()
        nvim_create_autocmd(event, {
          group = group,
          pattern = pattern,
          callback = callback,
        })
      end)
    end
  end
end

-----------------------------------------------------------------
---@param config setup_lang.add_ft
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
---@param config setup_lang.config
---@return table plugins
-----------------------------------------------------------------
local function setup_language(config)
  -- Set defaults
  assert(config.name, "LanguageConfig must have a 'name'")
  config.ft = ensure_list(config.ft or config.name) ---@type string[]

  local plugins = {}
  local create_autocmd = create_autocmd_group(config.name)

  -- Setup filetype detection
  if config.add_ft then
    schedule(function()
      vim.filetype.add(setup_detection(config.add_ft))
    end)

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

  -- install tools
  if config.tools then
    local tools
    if type(config.tools) == "function" then
      tools = config.tools()
    elseif type(config.tools) == "string" then
      tools = { config.tools }
    else
      tools = config.tools
    end
    table.insert(plugins, {
      "williamboman/mason.nvim",
      optional = true,
      opts = {
        ensure_installed = tools,
      },
    })
  end

  if config.test then
    table.insert(plugins, {
      "nvim-neotest/neotest",
      optional = true,
      dependecies = config.test.dependencies or {},
      opts = {
        adapters = config.test.adapters or {},
      },
    })
  end

  -- Formatting Configuration
  if config.formatting then
    local conform_opts = {
      formatters = config.formatting.formatters or {},
      formatters_by_ft = config.formatting.formatters_by_ft or {},
    }

    if config.formatting.use_prettier_biome then
      -- if use_prettier_biome is a boolean, use it for all filetypes
      if type(config.formatting.use_prettier_biome) == "boolean" and config.formatting.use_prettier_biome == true then
        conform_opts.use_prettier_biome = config.ft
      else
        conform_opts.use_prettier_biome = config.formatting.use_prettier_biome
      end
    end

    table.insert(plugins, {
      "stevearc/conform.nvim",
      opts = conform_opts,
    })

    if config.formatting.format_on_save and config.formatting.format_on_save ~= false then
      create_autocmd("FileType", config.ft, function(event)
        vim.b[event.buf].autoformat = true
      end)
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
    local icons = {}
    for _, icon_type in ipairs({ "default", "directory", "extension", "file", "filetype", "lsp", "os" }) do
      if config.icons[icon_type] then
        icons[icon_type] = config.icons[icon_type]
      end
    end
    table.insert(plugins, {
      "echasnovski/mini.icons",
      opts = icons,
    })
  end

  -- commentstring Configuration
  if config.commentstring then
    local opts = {}
    if type(config.commentstring) == "string" then
      ---@diagnostic disable-next-line: param-type-mismatch
      for _, ft in ipairs(config.ft) do
        opts[ft] = config.commentstring
      end
    elseif type(config.commentstring) == "table" then
      ---@diagnostic disable-next-line: param-type-mismatch
      for ft, commentstring in pairs(config.commentstring) do
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
      Utils.map.set_keymaps(config.keys)
    end)
  end

  -- Setup filetype-specific options
  if config.options then
    create_autocmd("FileType", config.ft, function(event)
      local buf = event.buf
      for option, value in pairs(config.options) do
        local ok, err = pcall(set_buf_option, buf, option, value)
        if not ok then
          vim.notify(
            string.format("Error setting option %s = %s: %s", option, vim.inspect(value), err),
            vim.log.levels.ERROR
          )
        end
      end
    end)
  end

  return plugins
end

return setup_language
