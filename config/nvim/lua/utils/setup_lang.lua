---@class utils.setup_lang
local M = {}

local function set_buf_option(buf, option, value)
  pcall(function()
    vim.bo[buf][option] = value
  end)
end

---@alias create_autocmd fun(event: string|string[], opts: autocmd.Create): nil
-----------------------------------------------------------------
-- Create an augroup for language-specific autocommands
---@param config_name string # Name of the language configuration
---@return create_autocmd # create_grouped_autocmd Function to create autocmds in this group
-----------------------------------------------------------------
local function create_autocmd_group(config_name)
  local group_name = string.format("language_setup_%s", config_name)
  local augroup = Utils.autocmd.augroup(group_name, { clear = true })
  ---@param event string|string[]
  ---@param opts? table
  return function(event, opts)
    opts = opts or {}
    opts.group = augroup
    Utils.autocmd.on_very_lazy(function()
      Utils.autocmd.create(event, opts)
    end)
  end
end

-----------------------------------------------------------------
---@param config setup_lang.add_ft
---@param create_autocmd create_autocmd
-----------------------------------------------------------------
function M.add_filetype(config, create_autocmd)
  local ft_configs = config.add_ft
  if not ft_configs then return end
  local filetype_config = {}
  for _, detect_type in ipairs({ "extension", "filename", "pattern" }) do
    if ft_configs[detect_type] then filetype_config[detect_type] = ft_configs[detect_type] end
  end
  if LazyLoad then
    local loaded = false
    create_autocmd("BufReadPre", {
      callback = function()
        if not loaded then
          vim.filetype.add(filetype_config)
          loaded = true
        end
      end,
      once = true,
    })
  else
    vim.filetype.add(filetype_config)
  end
  if ft_configs.filetype then
    for orig, target in pairs(ft_configs.filetype) do
      create_autocmd("FileType", {
        callback = function(event)
          local buf = event.buf
          if vim.bo[buf].filetype == orig then set_buf_option(buf, "filetype", target) end
        end,
      })
    end
  end
end

---@param config setup_lang.config
---@param autocmd_create function
function M.autocmds(config, autocmd_create)
  local autocmds = config.autocmds
  if not autocmds then return end
  if type(autocmds) ~= "table" or type(autocmds[1]) ~= "table" then
    Utils.notify.error("autocmds must be a table")
    return
  end

  for _, autocmd in ipairs(autocmds) do
    local group = autocmd.group
    autocmd.group = nil
    local autocmd_creator = group and create_autocmd_group(group) or autocmd_create
    local events = autocmd.events or "FileType"
    autocmd.events = nil
    local autocmd_opts = {}
    local pattern = autocmd.pattern or config.ft
    autocmd.pattern = nil
    autocmd_opts.pattern = pattern
    for key, value in pairs(autocmd) do
      autocmd_opts[key] = value
    end

    autocmd_creator(events, autocmd_opts)
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
  config.ft = Utils.ensure_list(config.ft or config.name) --[[@as string]]

  local plugins = {}
  local create_autocmd = create_autocmd_group(config.name)

  -- Setup filetype detection
  if config.add_ft then M.add_filetype(config, create_autocmd) end

  -- Setup custom autocmds
  if config.autocmds then M.autocmds(config, create_autocmd) end

  -- LSP Configuration
  if config.lsp then
    local servers = config.lsp.servers or {}
    for server_name, server_conf in pairs(servers) do
      if type(server_conf) == "function" then servers[server_name] = server_conf(config) end
    end
    config.lsp.servers = servers
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
        ensure_installed = Utils.ensure_list(config.tools),
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
      local pb = fmt.use_prettier_biome
      fmt_opts.use_prettier_biome = pb == true and Utils.ensure_list(config.ft) or Utils.ensure_list(pb)
    end
    table.insert(plugins, {
      "stevearc/conform.nvim",
      optional = true,
      opts = fmt_opts,
    })
    if Utils.evaluate(fmt.format_on_save, true) then
      create_autocmd("FileType", {
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
      optional = true,
      opts = config.linting,
    })
  end

  -- Treesitter Configuration
  if config.highlighting then
    local hl = config.highlighting
    local parsers = hl.parsers or vim.islist(hl) and hl or {}
    parsers = Utils.ensure_list(parsers)
    table.insert(plugins, {
      "nvim-treesitter/nvim-treesitter",
      opts = function(_, opts)
        opts.ensure_installed = opts.ensure_installed or {}
        vim.list_extend(opts.ensure_installed, parsers)
        -- for _, parser in ipairs(parsers) do
        --   table.insert(opts.ensure_installed, parser)
        -- end
        if hl.custom_parsers then
          local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
          for name, info in pairs(hl.custom_parsers) do
            parser_config[name] = info
            local ft = info.filetype or { name }
            vim.treesitter.language.register(name, ft)
            if not vim.tbl_contains(parsers, name) then table.insert(opts.ensure_installed, name) end
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
          if icons[type] then opts[type] = icons[type] end
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
      table.insert(plugins, Utils.ensure_list(plugin))
    end
  end

  -- Setup filetype-specific keymaps
  if config.keys then
    create_autocmd("FileType", {
      pattern = config.ft,
      callback = function(event)
        Utils.map.set_keymaps(config.keys, { buffer = event.buf })
      end,
    })
  end

  -- Setup filetype-specific options
  if config.options then
    create_autocmd("FileType", {
      pattern = config.ft,
      callback = function(event)
        local buf = event.buf
        for option, value in pairs(config.options) do
          set_buf_option(buf, option, value)
        end
      end,
    })
  end

  if config.root_patterns then Utils.root.add_patterns(config.root_patterns) end

  return plugins
end

M._registered = {}
-----------------------------------------------------------------
-- adds a language to the setup.
---@param langs string|string[]
---@return table[]
-----------------------------------------------------------------
function M.add_lang(langs)
  langs = (langs and Utils.ensure_list(langs)) or { "lua" }
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
