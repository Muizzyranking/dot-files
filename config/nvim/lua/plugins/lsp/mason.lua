return {
  "mason-org/mason.nvim",
  cmd = "Mason",
  keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
  build = ":MasonUpdate",
  opts_extend = { "ensure_installed" },
  opts = { ensure_installed = {} },
  config = function(_, opts)
    local mason = require("mason")
    local mr = require("mason-registry")
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
    local get_tools = function()
      local all_tools = {}
      local tools = Utils.ensure_list(opts.ensure_installed)
      for _, tool in ipairs(tools) do
        if not vim.tbl_contains(all_tools, tool) then table.insert(all_tools, tool) end
      end
      return all_tools
    end
    local all_tools = get_tools()

    local function ensure_installed()
      for _, tool in ipairs(all_tools) do
        local p = mr.get_package(tool)
        if not p:is_installed() then p:install() end
      end
    end

    -- Helper: Clean up unneeded tools
    local function remove_unused_tools()
      local installed_packages = mr.get_installed_packages()
      for _, package in ipairs(installed_packages) do
        if not vim.tbl_contains(all_tools, package) then package:uninstall() end
      end
    end

    Utils.map.set_keymap({
      "<leader>cM",
      remove_unused_tools,
      desc = "Mason: Remove unused tools",
      icon = { icon = " ", color = "red" },
    })

    Utils.autocmd.on_user_event("LazyUpdate", function()
      remove_unused_tools()
    end)

    -- Trigger installation of tools, refreshing the registry if needed
    mr.refresh(function()
      ensure_installed()
    end)
  end,
}
