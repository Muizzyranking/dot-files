return {
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
        Utils.notify.warn("Mini Pairs disabled", { title = "Mini Pairs" })
      else
        Utils.notify.info("Mini Pairs enabled", { title = "Mini Pairs" })
      end
    end, { desc = "Toggle Mini Pairs" })

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
}
