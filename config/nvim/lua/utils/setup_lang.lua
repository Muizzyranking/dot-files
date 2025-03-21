---@class utils.setup_lang
local M = {}

local api = vim.api
local schedule = vim.schedule
local create_augroup = api.nvim_create_augroup
local nvim_create_autocmd = api.nvim_create_autocmd
local set_buf_option = api.nvim_buf_set_option

-----------------------------------------------------------------
--- Normalize a value to ensure it’s always a list.
---@param value any # Input value
---@return table # Listified value
-----------------------------------------------------------------
local function ensure_list(value)
  return type(value) == "table" and value or { value }
end

-----------------------------------------------------------------
-- Create an augroup for language-specific autocommands
---@param config_name string # Name of the language configuration
---@return function # create_grouped_autocmd Function to create autocmds in this group
-----------------------------------------------------------------
local function create_autocmd_group(config_name)
  local group_name = string.format("language_setup_%s", config_name)
  local group = create_augroup(group_name, { clear = true })
  local lazy_load = vim.fn.argc(-1) == 0

  ---@param event string|string[]
  ---@param pattern string|string[]
  ---@param callback fun(event: table)
  ---@param opts? table
  return function(event, pattern, callback, opts)
    opts = vim.tbl_extend("force", {
      group = group,
      pattern = pattern,
      callback = callback,
    }, opts or {})
    local autocmd = function()
      nvim_create_autocmd(event, opts)
    end
    if not lazy_load then
      autocmd()
    else
      Utils.on_very_lazy(autocmd)
    end
  end
end

-----------------------------------------------------------------
---@param config setup_lang.add_ft
---@param create_autocmd function
-----------------------------------------------------------------
function M.add_filetype(config, create_autocmd)
  local ft_configs = config.add_ft
  if not ft_configs then
    return
  end
  local filetype_config = {}
  for _, detect_type in ipairs({ "extension", "filename", "pattern" }) do
    if ft_configs[detect_type] then
      filetype_config[detect_type] = ft_configs[detect_type]
    end
  end
  schedule(function()
    vim.filetype.add(filetype_config)
  end)
  if ft_configs.filetype then
    for orig, target in pairs(ft_configs.filetype) do
      create_autocmd("FileType", orig, function(event)
        vim.api.nvim_buf_set_option(event.buf, "filetype", target)
      end)
    end
  end
end

---@param config setup_lang.config
---@param autocmd_create function
function M.autocmds(config, autocmd_create)
  local autocmds = config.autocmds
  if not autocmds then
    return
  end
  if type(autocmds) ~= "table" or type(autocmds[1]) ~= "table" then
    Utils.notify.error("autocmds must be a table")
    return
  end
  for _, autocmd in ipairs(autocmds) do
    local callback = autocmd.callback or function()
      vim.cmd(autocmd.command)
    end
    local opts = autocmd.opts or {}
    local events = autocmd.events or "FileType"
    local create_autocmd = autocmd.group and create_autocmd_group(autocmd.group) or autocmd_create
    local pattern = autocmd.pattern or config.ft
    create_autocmd(events, pattern, callback, opts)
  end
end

-----------------------------------------------------------------
-- Setup a language configuration.
---@param config setup_lang.config
---@return table plugins
-----------------------------------------------------------------
function M.setup_language(config)
  -- Set defaults
  assert(config.name, "LanguageConfig must have a 'name'")
  config.ft = ensure_list(config.ft or config.name) --[[@as string]]

  local plugins = {}
  local create_autocmd = create_autocmd_group(config.name)

  -- Setup filetype detection
  if config.add_ft then
    M.add_filetype(config, create_autocmd)
  end

  -- Setup custom autocmds
  if config.autocmds then
    M.autocmds(config, create_autocmd)
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
    table.insert(plugins, {
      "williamboman/mason.nvim",
      optional = true,
      opts = {
        ensure_installed = ensure_list(config.tools),
      },
    })
  end

  if config.test then
    table.insert(plugins, {
      "nvim-neotest/neotest",
      optional = true,
      dependencies = config.test.dependencies or {},
      opts = { adapters = config.test.adapters or {} },
    })
  end

  -- Formatting Configuration
  if config.formatting then
    local fmt = config.formatting
    local fmt_opts = {
      formatters = fmt.formatters or {},
      formatters_by_ft = fmt.formatters_by_ft or {},
    }
    if fmt.use_prettier_biome then
      if fmt.use_prettier_biome == true then
        fmt_opts.use_prettier_biome = ensure_list(config.ft)
      else
        fmt_opts.use_prettier_biome = fmt.use_prettier_biome
      end
    end
    table.insert(plugins, {
      "stevearc/conform.nvim",
      optional = true,
      opts = fmt_opts,
    })
    if fmt.format_on_save == true then
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
    local hl = config.highlighting
    local parsers = hl.parsers or {}
    table.insert(plugins, {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        for _, parser in ipairs(parsers) do
          table.insert(opts.ensure_installed, parser)
        end
        if hl.custom_parsers then
          local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
          for name, info in pairs(hl.custom_parsers) do
            parser_config[name] = info
            local ft = info.filetype or { name }
            vim.treesitter.language.register(name, ft)
            if not vim.tbl_contains(parsers, name) then
              table.insert(opts.ensure_installed, name)
            end
          end
        end
      end,
    })
  end

  -- Icons Configuration
  if config.icons then
    local icons = config.icons
    local available = { "default", "directory", "extension", "file", "filetype", "lsp", "os" }
    table.insert(plugins, {
      "echasnovski/mini.icons",
      opts = function(_, opts)
        for _, type in ipairs(available) do
          if icons[type] then
            opts[type] = icons[type]
          end
        end
      end,
    })
  end

  -- commentstring Configuration
  if config.commentstring then
    local commentstring = config.commentstring
    table.insert(plugins, {
      "folke/ts-comments.nvim",
      optional = true,
      opts = function(_, opts)
        opts = opts or {}
        opts.lang = opts.lang or {}
        if type(commentstring) == "string" then
          for _, ft in ipairs(config.ft) do
            opts.lang[ft] = commentstring
          end
        elseif type(commentstring) == "table" then
          for ft, cs in pairs(commentstring) do
            opts.lang[ft] = cs
          end
        end
      end,
    })
  end

  -- Add custom plugins
  if config.plugins then
    for _, plugin in ipairs(config.plugins) do
      table.insert(plugins, ensure_list(plugin))
    end
  end

  -- Setup filetype-specific keymaps
  if config.keys then
    create_autocmd("Filetype", config.ft, function(event)
      Utils.map.set_keymaps(config.keys, { buffer = event.buf })
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

  if config.root_patterns then
    Utils.root.add_patterns(config.root_patterns)
  end

  return plugins
end

M._registered = {}
-----------------------------------------------------------------
-- adds a language to the setup.
---@param langs string|string[]
---@return table[]
-----------------------------------------------------------------
function M.add_lang(langs)
  langs = (type(langs) == "table" and langs or { langs }) or { "lua" }
  local results = {}
  for _, lang in ipairs(langs) do
    if M._registered[lang] then
      table.insert(results, M._registered[lang])
    else
      local ok, lang_config = pcall(require, "plugins.lang." .. lang)
      if ok then
        local lang_setup = M.setup_language(lang_config)
        M._registered[lang] = lang_setup
        table.insert(results, lang_setup)
      end
    end
  end
  return results
end

return M
