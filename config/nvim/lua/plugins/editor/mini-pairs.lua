return {
  "echasnovski/mini.pairs",
  event = "VeryLazy",
  opts = {
    modes = { insert = true, command = true, terminal = false },
    skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
    skip_ts = { "string" },
    skip_unbalanced = true,
    markdown = true,
  },
  config = function(_, opts)
    Utils.map.toggle_map({
      "<leader>up",
      get_state = function()
        return not vim.g.minipairs_disable
      end,
      change_state = function(state)
        vim.g.minipairs_disable = state
      end,
      name = "Mini Pairs",
    })
    local pairs = require("mini.pairs")
    pairs.setup(opts)
    local open = pairs.open
    ---@diagnostic disable-next-line: duplicate-set-field
    pairs.open = function(pair, neigh_pattern)
      if vim.fn.getcmdline() ~= "" then
        return open(pair, neigh_pattern)
      end
      local o, c = pair:sub(1, 1), pair:sub(2, 2)
      local line = vim.api.nvim_get_current_line()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local next = line:sub(cursor[2] + 1, cursor[2] + 1)
      local before = line:sub(1, cursor[2])
      local prev = cursor[2] > 0 and line:sub(cursor[2], cursor[2]) or ""
      local at_end_of_word = prev:match("%w")

      -- Special handling for identical pairs (quotes, backticks) at end of word
      if at_end_of_word and o == c then
        return o -- Only insert the opening character for identical pairs at word end
      end

      -- Special handling for markdown code blocks
      if opts.markdown and o == "`" and vim.bo.filetype == "markdown" and before:match("^%s*``") then
        return "\n```" .. vim.api.nvim_replace_termcodes("<CR>", true, true, true)
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
