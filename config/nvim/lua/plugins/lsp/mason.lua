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

    mr:on("package:install:success", function()
      vim.defer_fn(function()
        require("lazy.core.handler.event").trigger({
          event = "FileType",
          buf = vim.api.nvim_get_current_buf(),
        })
      end, 100)
    end)

    local tools = Utils.ensure_list(opts.ensure_installed)
    local function ensure_installed()
      for _, tool in ipairs(tools) do
        local p = mr.get_package(tool)
        if not p:is_installed() then p:install() end
      end
    end

    mr.refresh(function()
      ensure_installed()
    end)
  end,
}
