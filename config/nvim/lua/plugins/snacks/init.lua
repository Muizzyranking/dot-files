local conf = require("plugins.snacks.config")

---@class snacks.picker
---@field fff fun(opts?: snacks.picker.Config|{}): snacks.Picker
---@field fff_live_grep fun(opts?: snacks.picker.Config|{}): snacks.Picker
---@field unsaved_buffers fun(opts?: snacks.picker.Config|{}): snacks.Picker

local has_fff = Utils.lazy.has("fff.nvim")

local function register_sources()
  Snacks.picker.sources.unsaved_buffers = require("plugins.snacks.pickers.unsaved_buffers")
  if has_fff then
    Snacks.picker.sources.fff = require("plugins.snacks.pickers.find_files")
    Snacks.picker.sources.fff_live_grep = require("plugins.snacks.pickers.live_grep")
  end
end

return {
  {
    "folke/snacks.nvim",
    lazy = false,
    priority = 2000,
    opts = {
      explorer = {
        on_show = function()
          Snacks.notifier.hide()
        end,
      },
      input = { enabled = true },
      indent = conf.indent,
      dashboard = conf.dashboard,
      notifier = conf.notifier,
      bigfile = { enabled = true },
      image = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = true },
      words = { enabled = true },
      scroll = { enabled = true },
      lazygit = {
        win = {
          bo = { filetype = "lazygit" },
          keys = {
            ["<C-h>"] = { "<c-s-w>", mode = { "i", "t" }, expr = true, desc = "delete word" },
          },
        },
        config = {
          git = { overrideGpg = true },
          promptToReturnFromSubprocess = false,
        },
      },
      styles = {
        input = {
          keys = {
            i_c_h = { "<c-h>", "<c-s-w>", mode = "i", expr = true },
          },
        },
      },
      picker = conf.picker,
    },
    keys = {
      -- stylua: ignore start
      { "<leader>n", function() Snacks.notifier.show_history() end, desc = "Notification History" },
      { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
      { "<leader>.", function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
      { "<leader>S", function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
      {
        "z=",
        function()
          Utils.picker.spelling({ on_show = function() vim.cmd("stopinsert") end })
        end,
        desc = "Spell suggestions",
      },
      {
        "<leader>fb",
        function()
          Utils.picker.buffers({ on_show = function() vim.cmd("stopinsert") end })
        end,
        desc = "Buffers",
      },
      { "<leader>fB", function() Utils.picker.unsaved_buffers() end, desc = "Unsaved Buffers" },
      { "<leader>ff", function() Utils.picker.files() end, desc = "Find Files (fff)" },
      { "<leader>fg", function() Utils.picker.grep() end, desc = "Live Grep (fff)" },
      { "<leader>sw", function() Utils.picker.grep_word() end, mode = { "n", "x" }, desc = "Search word" },
      { "<leader>fr", function() Utils.picker.recent() end, desc = "Recent files" },
      { "<leader>fR", function() Utils.picker.recent({ filter = { cwd = true } }) end, desc = "Recent files (cwd)" },
      { "<leader>fG", function() Utils.picker.grep_buffers() end, desc = "Grep in Open Buffers" },
      { "<leader>fd", function() Utils.picker.diagnostics() end, desc = "Diagnostics" },
      { "<leader>si", function() Utils.picker.icons() end, desc = "Icons" },
      { "<leader>sm", function() Utils.picker.man() end, desc = "Man Pages" },
      {
        "<leader>fc",
        function()
          Utils.picker.resume({ exclude = { "explorer", "notifications" } })
        end,
        desc = "Continue from last search",
      },
      { "<leader>e", function() Snacks.explorer({ cwd = Utils.root() }) end, desc = "File Explorer (root)" },
      { "<leader>E", function() Snacks.explorer() end, desc = "File Explorer (cwd)" },
      {
        "<leader>fe",
        function()
          local pickers = Utils.picker.get({ source = "explorer" })
          if pickers[1] then
            pickers[1]:focus()
          else
            Snacks.explorer({ cwd = Utils.root() })
          end
        end,
        desc = "Focus/Open Explorer",
      },
      -- stylua: ignore end
    },
    config = function(_, opts)
      -- Preserve any vim.notify overrides set before snacks loads.
      local notify = vim.notify
      require("snacks").setup(opts)
      vim.notify = notify

      register_sources()
    end,
  },

  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>f", group = "file/find" },
      },
    },
  },

  {
    "folke/trouble.nvim",
    optional = true,
    specs = {
      "folke/snacks.nvim",
      opts = function(_, opts)
        return vim.tbl_deep_extend("force", opts or {}, {
          picker = {
            actions = require("trouble.sources.snacks").actions,
            win = {
              input = {
                keys = {
                  ["<c-t>"] = { "trouble_open", mode = { "n", "i" } },
                },
              },
            },
          },
        })
      end,
    },
  },
}
