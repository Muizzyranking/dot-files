local plugins = {}
table.insert(plugins, {
  "epwalsh/obsidian.nvim",
  version = "*",
  ft = "markdown",
  cond = Utils.is_in_notes_dir(),
  cmd = "Obsidian",
  keys = {},
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = function()
    local group = vim.api.nvim_create_augroup("ObsidianKeymaps", { clear = true })
    vim.api.nvim_create_autocmd("BufEnter", {
      group = group,
      pattern = "/home/muizzyranking/Documents/Notes/*",
      callback = function(event)
        local maps = {
          {
            "<leader>on",
            function()
              vim.cmd("ObsidianNew")
            end,
            desc = "Create a new note in zettelkasten",
            icon = { icon = "󰈔 " },
          },
          {
            "<leader>ot",
            function()
              vim.cmd("ObsidianTemplate")
            end,
            desc = "Insert a template",
            icon = { icon = " ", color = "yellow" },
          },
          {
            "<leader>oc",
            function()
              vim.cmd("ObsidianNewFromTemplate")
            end,
            desc = "Create a new note from a template",
            icon = { icon = "󰎞 ", color = "yellow" },
          },
        }
        for _, map in ipairs(maps) do
          map.buffer = event.buf
        end
        Utils.map(maps)
      end,
    })
    return {
      workspaces = {
        {
          name = "personal",
          path = "~/Documents/Notes/",
        },
      },
      notes_subdir = "Zettelkasten",
      templates = {
        folder = "Templates",
        date_format = "%Y-%m-%d",
        time_format = "%H:%M",
        substitutions = {},
      },

      log_level = vim.log.levels.INFO,
      daily_notes = {
        folder = "notes/daily",
        date_format = "%Y-%m-%d",
        -- Optional, if you want to change the date format of the default alias of daily notes.
        alias_format = "%B %-d, %Y",
        default_tags = { "daily-notes" },
        template = nil,
      },
      completion = {
        nvim_cmp = false,
        min_chars = 2,
      },
      mappings = {
        ["gf"] = {
          action = function()
            return require("obsidian").util.gf_passthrough()
          end,
          opts = { noremap = false, expr = true, buffer = true },
        },
        ["<leader>ch"] = {
          action = function()
            return require("obsidian").util.toggle_checkbox()
          end,
          opts = { buffer = true },
        },
      },
      new_notes_location = "notes_subdir",
      preferred_link_style = "wiki",
      disable_frontmatter = true,
      note_id_func = function(title)
        local suffix = ""
        if title ~= nil then
          suffix = title:gsub(" ", "-"):gsub("[^A-Za-z0-9-]", ""):lower()
        else
          for _ = 1, 4 do
            suffix = suffix .. string.char(math.random(65, 90))
          end
        end
        -- return tostring(os.time()) .. "-" .. suffix
        return suffix
      end,

      sort_by = "modified",
      sort_reversed = true,
      search_max_lines = 1000,
      open_notes_in = "current",
      ui = {
        enable = false,
      },
      -- Specify how to handle attachments.
      attachments = {
        img_folder = "assets/imgs",
        img_name_func = function()
          return string.format("%s-", os.time())
        end,
        img_text_func = function(client, path)
          path = client:vault_relative_path(path) or path
          return string.format("![%s](%s)", path.name, path)
        end,
      },
    }
  end,
})

table.insert(plugins, {
  "saghen/blink.cmp",
  dependencies = {
    { "epwalsh/obsidian.nvim", "saghen/blink.compat" },
  },
  opts = {
    sources = {
      compat = { "obsidian", "obsidian_new", "obsidian_tags" },
      providers = {
        obsidian = {
          kind = "Obsidian",
          async = true,
        },
        obsidian_new = {
          kind = "Obsidian",
          async = true,
        },
        obsidian_tags = {
          kind = "Obsidian",
          async = true,
        },
      },
    },
  },
})

if Utils.is_in_notes_dir() then
  table.insert(plugins, {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = {
      sections = {
        lualine_b = {
          {
            function()
              return "󱞁 My Notes"
            end,
            color = function()
              return vim.tbl_extend("force", Utils.lualine.fg("Special"), { gui = "bold" })
            end,
          },
          {
            "diff",
            symbols = {
              added = Utils.icons.git.added,
              modified = Utils.icons.git.modified,
              removed = Utils.icons.git.removed,
            },
            source = function()
              local gitsigns = vim.b.gitsigns_status_dict
              if gitsigns then
                return {
                  added = gitsigns.added,
                  modified = gitsigns.changed,
                  removed = gitsigns.removed,
                }
              end
            end,
          },
          Utils.lualine.file,
        },

        lualine_y = {
          Utils.lualine.lsp,
          {
            function()
              local counts = Utils.count_words_and_characters()
              return string.format("words: %d, chars: %d", counts.words, counts.characters)
            end,
            color = function()
              return vim.tbl_extend("force", Utils.lualine.fg("constant"), { gui = "italic" })
            end,
          },
        },
      },
    },
  })
end

return plugins
