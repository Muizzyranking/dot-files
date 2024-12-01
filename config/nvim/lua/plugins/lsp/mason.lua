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
    require("mason").setup(opts)
    local mr = require("mason-registry")

    -- Trigger lazy events after successful package installation
    mr:on("package:install:success", function()
      vim.defer_fn(function()
        require("lazy.core.handler.event").trigger({
          event = "FileType",
          buf = vim.api.nvim_get_current_buf(),
        })
      end, 100)
    end)

    local tools = {}
    -- Populate a list of tools to be installed
    -- Combines tools from various conform and nvim-lint
    ---@param ... table[] List of tool definitions from plugins
    local function populate_ensure_installed(...)
      ---@param entries table A collection of tools grouped by filetype
      local function process_entries(entries)
        for _, group in pairs(entries) do
          for _, item in ipairs(group) do
            -- Skip if the item is not available in mason-registry
            local ok = pcall(function()
              return mr.get_package(item)
            end)
            if ok then
              table.insert(tools, item)
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
      Utils.opts("conform.nvim").formatters_by_ft or {},
      Utils.opts("nvim-lint").linters_by_ft or {}
    )

    local all_tools = {}
    local installed_set = {}
    -- Add tools to a consolidated list, avoiding duplicates
    ---@param entries string[] List of tools to add
    local function add_tools(entries)
      for _, tool in ipairs(entries) do
        if not installed_set[tool] then
          table.insert(all_tools, tool)
          installed_set[tool] = true
        end
      end
    end

    add_tools(tools)
    add_tools(opts.ensure_installed)

    -- Add Prettier tools if the use_prettier option is set
    if #Utils.opts("conform.nvim").use_prettier > 0 then
      add_tools({ "prettier", "prettierd" })
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

    -- Trigger installation of tools, refreshing the registry if needed
    if mr.refresh then
      mr.refresh(ensure_installed)
    else
      ensure_installed()
    end
  end,
}
