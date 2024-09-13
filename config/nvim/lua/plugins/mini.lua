local utils = require("utils")
local notify = require("utils.notify")
return {
  {
    "echasnovski/mini.icons",
    lazy = true,
    opts = {
      file = {
        [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
        [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
        [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
        ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
        ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
      },
      filetype = {
        htmldjango = { glyph = "", hl = "MiniIconsBlue" },
      },
    },
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },
  -- mini pairs (automatically close brackets, quotes, etc.)
  {
    "echasnovski/mini.pairs",
    event = "VeryLazy",
    opts = {
      -- Specify which modes mini.pairs should be active in
      modes = { insert = true, command = true, terminal = false },

      -- Skip autopair when the next character is one of these:
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],

      -- Skip autopair when inside these treesitter nodes (e.g., "string" nodes)
      skip_ts = { "string" },

      -- Skip autopair if there are more closing pairs than opening pairs
      skip_unbalanced = true,

      -- Special handling for markdown code blocks
      markdown = true,
    },

    config = function(_, opts)
      -- Define the pairs setup and a toggle to enable/disable it with <leader>up
      vim.keymap.set("n", "<leader>up", function()
        local state = not vim.g.minipairs_disable
        vim.g.minipairs_disable = state
        if state == true then
          notify.warn("Mini Pairs disabled", { title = "Mini Pairs" })
        else
          notify.info("Mini Pairs enabled", { title = "Mini Pairs" })
        end
      end, {})

      -- Load the mini.pairs plugin with the given options
      local pairs = require("mini.pairs")
      pairs.setup(opts)

      -- Cache the original pairs.open function for later use
      local open = pairs.open

      -- Override the pairs.open function to add custom logic
      ---@diagnostic disable-next-line: duplicate-set-field
      pairs.open = function(pair, neigh_pattern)
        -- If in command-line mode (e.g., typing a command), use default behavior
        if vim.fn.getcmdline() ~= "" then
          return open(pair, neigh_pattern)
        end

        -- Extract the opening and closing characters of the pair
        local o, c = pair:sub(1, 1), pair:sub(2, 2)

        -- Get the current line and cursor position
        local line = vim.api.nvim_get_current_line()
        local cursor = vim.api.nvim_win_get_cursor(0)

        -- Get the next character after the cursor
        local next = line:sub(cursor[2] + 1, cursor[2] + 1)

        -- Get the part of the line before the cursor
        local before = line:sub(1, cursor[2])

        -- Special handling for markdown code blocks
        if opts.markdown and o == "" and vim.bo.filetype == "markdown" and before:match("^%s*``") then
          return "\n```" .. vim.api.nvim_replace_termcodes("<up>", true, true, true)
        end

        -- Skip autopair if the next character matches the skip_next pattern
        if opts.skip_next and next ~= "" and next:match(opts.skip_next) then
          return o -- Only insert the opening character
        end

        -- Skip autopair if inside specific treesitter nodes (like "string")
        if opts.skip_ts and #opts.skip_ts > 0 then
          local ok, captures = pcall(vim.treesitter.get_captures_atpos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
          for _, capture in ipairs(ok and captures or {}) do
            -- If the current position is inside a node specified in skip_ts, skip the pair
            if vim.tbl_contains(opts.skip_ts, capture.capture) then
              return o
            end
          end
        end

        -- Skip autopair if the next character is the closing pair and it's unbalanced
        if opts.skip_unbalanced and next == c and c ~= o then
          -- Count how many opening and closing characters are in the line
          local _, count_open = line:gsub(vim.pesc(o), "")
          local _, count_close = line:gsub(vim.pesc(c), "")
          -- If there are more closing characters than opening, only insert the opening character
          if count_close > count_open then
            return o
          end
        end

        -- Otherwise, use the default behavior of the open function
        return open(pair, neigh_pattern)
      end
    end,
  },
  -- mini ai for better text objects
  {
    "echasnovski/mini.ai",
    event = "VeryLazy",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    opts = function()
      local ai = require("mini.ai")
      return {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = ai.gen_spec.treesitter({
            a = "@function.outer",
            i = "@function.inner",
          }, {}),
          c = ai.gen_spec.treesitter({
            a = "@class.outer",
            i = "@class.inner",
          }, {}),
          t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },
          d = { "%f[%d]%d+" }, -- digits
          e = { -- Word with case
            {
              "%u[%l%d]+%f[^%l%d]",
              "%f[%S][%l%d]+%f[^%l%d]",
              "%f[%P][%l%d]+%f[^%l%d]",
              "^[%l%d]+%f[^%l%d]",
            },
            "^().*()$",
          },
          g = function(ai_type) -- Whole buffer, similar to `gg` and 'G' motion
            local start_line, end_line = 1, vim.fn.line("$")
            if ai_type == "i" then
              -- Skip first and last blank lines for `i` textobject
              local first_nonblank, last_nonblank = vim.fn.nextnonblank(start_line), vim.fn.prevnonblank(end_line)
              -- Do nothing for buffer with all blanks
              if first_nonblank == 0 or last_nonblank == 0 then
                return { from = { line = start_line, col = 1 } }
              end
              start_line, end_line = first_nonblank, last_nonblank
            end

            local to_col = math.max(vim.fn.getline(end_line):len(), 1)
            return { from = { line = start_line, col = 1 }, to = { line = end_line, col = to_col } }
          end,
          u = ai.gen_spec.function_call(), -- u for "Usage"
          U = ai.gen_spec.function_call({ name_pattern = "[%w_]" }), -- without dot in function name
        },
      }
    end,
    config = function(_, opts)
      require("mini.ai").setup(opts)
      utils.on_load("which-key.nvim", function()
        vim.schedule(function()
          local objects = {
            { " ", desc = "whitespace" },
            { '"', desc = '" string' },
            { "'", desc = "' string" },
            { "(", desc = "() block" },
            { ")", desc = "() block with ws" },
            { "<", desc = "<> block" },
            { ">", desc = "<> block with ws" },
            { "?", desc = "user prompt" },
            { "U", desc = "use/call without dot" },
            { "[", desc = "[] block" },
            { "]", desc = "[] block with ws" },
            { "_", desc = "underscore" },
            { "`", desc = "` string" },
            { "a", desc = "argument" },
            { "b", desc = ")]} block" },
            { "c", desc = "class" },
            { "d", desc = "digit(s)" },
            { "e", desc = "CamelCase / snake_case" },
            { "f", desc = "function" },
            { "g", desc = "entire file" },
            { "i", desc = "indent" },
            { "o", desc = "block, conditional, loop" },
            { "q", desc = "quote `\"'" },
            { "t", desc = "tag" },
            { "u", desc = "use/call" },
            { "{", desc = "{} block" },
            { "}", desc = "{} with ws" },
          }

          local ret = { mode = { "o", "x" } }
          ---@type table<string, string>
          local mappings = vim.tbl_extend("force", {}, {
            around = "a",
            inside = "i",
            around_next = "an",
            inside_next = "in",
            around_last = "al",
            inside_last = "il",
          }, opts.mappings or {})
          mappings.goto_left = nil
          mappings.goto_right = nil

          for name, prefix in pairs(mappings) do
            name = name:gsub("^around_", ""):gsub("^inside_", "")
            ret[#ret + 1] = { prefix, group = name }
            for _, obj in ipairs(objects) do
              local desc = obj.desc
              if prefix:sub(1, 1) == "i" then
                desc = desc:gsub(" with ws", "")
              end
              ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
            end
          end
          require("which-key").add(ret, { notify = false })
        end)
      end)
    end,
  },

  {
    "echasnovski/mini.surround",
    event = { "BufRead", "BufNewFile" },
    opts = {
      mappings = {
        add = "gza", -- Add surrounding in Normal and Visual modes
        delete = "gzd", -- Delete surrounding
        find = "gzf", -- Find surrounding (to the right)
        find_left = "gzF", -- Find surrounding (to the left)
        highlight = "gzh", -- Highlight surrounding
        replace = "gzr", -- Replace surrounding
        update_n_lines = "gzn", -- Update `n_lines`
      },
    },
  },

  -- mini indentscope (indent guides)
  {
    "echasnovski/mini.indentscope",
    version = false,
    event = "LazyFile",
    opts = {
      -- symbol = "▏",
      symbol = "│",
      options = { try_as_border = true },
    },
    init = function()
      vim.api.nvim_create_autocmd("FileType", {
        pattern = {
          "help",
          "alpha",
          "dashboard",
          "neo-tree",
          "Trouble",
          "trouble",
          "lazy",
          "mason",
          "notify",
          "toggleterm",
          "lazyterm",
          "toggleterm",
          "lazygit",
        },
        callback = function()
          vim.b.miniindentscope_disable = true
        end,
      })
    end,
  },

  -- mini animate (smooth scrolling)
  -- not neccessary, but i like it
  {
    "echasnovski/mini.animate",
    event = "VeryLazy",
    -- enabled = false,
    opts = function()
      -- don't use animate when scrolling with the mouse
      local mouse_scrolled = false
      for _, scroll in ipairs({ "Up", "Down" }) do
        local key = "<ScrollWheel" .. scroll .. ">"
        vim.keymap.set({ "", "i" }, key, function()
          mouse_scrolled = true
          return key
        end, { expr = true })
      end

      local animate = require("mini.animate")
      return {
        resize = {
          timing = animate.gen_timing.linear({ duration = 100, unit = "total" }),
        },
        scroll = {
          timing = animate.gen_timing.linear({ duration = 150, unit = "total" }),
          subscroll = animate.gen_subscroll.equal({
            predicate = function(total_scroll)
              if mouse_scrolled then
                mouse_scrolled = false
                return false
              end
              return total_scroll > 1
            end,
          }),
        },
      }
    end,
  },
}
