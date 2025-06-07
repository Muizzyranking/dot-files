return {
  "williamboman/mason.nvim",
  cmd = "Mason",
  keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
  build = ":MasonUpdate",
  opts_extend = { "ensure_installed" },
  opts = {
    ensure_installed = { "stylua" },
  },
  config = function(_, opts)
    local mason = require("mason")
    local mr = require("mason-registry")
    local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
    mason.setup(opts)

    -- Trigger lazy events after successful package installation
    mr:on("package:install:success", function()
      vim.defer_fn(function()
        require("lazy.core.handler.event").trigger({
          event = "FileType",
          buf = vim.api.nvim_get_current_buf(),
        })
      end, 100)
    end)

    local all_tools = {}
    local installed_tools_set = {}
    -- Add tools to a consolidated list, avoiding duplicates
    ---@param entries string[]|string List of tools to add
    local function add_tools(entries)
      entries = Utils.ensure_list(entries)
      for _, tool in ipairs(entries) do
        if not installed_tools_set[tool] then
          all_tools[#all_tools + 1] = tool
          installed_tools_set[tool] = true
        end
      end
    end
    -- Populate a list of tools to be installed
    -- Combines tools from various conform and nvim-lint
    ---@param ... table[] List of tool definitions from plugins
    local function populate_ensure_installed(...)
      ---@param entries table A collection of tools grouped by filetype
      local function process_entries(entries)
        for _, group in pairs(entries) do
          -- local flat_group = vim.tbl_flatten(group)
          local flat_group = vim.iter(group):flatten():totable()
          for _, tool in ipairs(flat_group) do
            -- stylua: ignore
            if pcall(function() return mr.get_package(tool) end) then
              add_tools( tool )
            end
          end
        end
      end

      for _, entries in ipairs({ ... }) do
        process_entries(entries)
      end
    end

    -- Gather tools from conform.nvim and nvim-lint plugins
    populate_ensure_installed(
      Utils.get_opts("conform.nvim").formatters_by_ft or {},
      Utils.get_opts("nvim-lint").linters_by_ft or {}
    )

    add_tools(opts.ensure_installed)

    -- Add Prettier tools if the use_prettier_biome option is set
    if #Utils.get_opts("conform.nvim").use_prettier_biome > 0 then
      add_tools({ "prettierd", "biome" })
    end

    -- Ensure all tools in the list are installed
    local function ensure_installed()
      for _, tool in ipairs(all_tools) do
        local p = mr.get_package(tool)
        if not p:is_installed() then
          p:install()
        end
      end
    end

    -- Helper: Clean up unneeded tools
    local function remove_unused_tools()
      local installed_packages = mr.get_installed_packages()
      local lsp_to_package_map = {}
      local installed_lsp_servers = {}

      if mason_lspconfig_ok then
        installed_lsp_servers = mason_lspconfig.get_installed_servers() or {}
        lsp_to_package_map = require("mason-lspconfig").get_mappings().lspconfig_to_package
      end

      local valid_tools_set = {}
      for _, tool in ipairs(all_tools) do
        valid_tools_set[tool] = true
      end

      for _, lsp in ipairs(installed_lsp_servers) do
        valid_tools_set[lsp_to_package_map[lsp] or lsp] = true
      end

      for _, package in ipairs(installed_packages) do
        if not valid_tools_set[package.name] then
          package:uninstall()
        end
      end
    end

    Utils.map.set_keymap({
      "<leader>cM",
      remove_unused_tools,
      desc = "Mason: Remove unused tools",
      icon = { icon = " ", color = "red" },
    })

    Utils.autocmd.on_user_event("LazyUpdate", remove_unused_tools)

    -- Trigger installation of tools, refreshing the registry if needed
    mr.refresh(function()
      ensure_installed()
    end)
  end,
}
