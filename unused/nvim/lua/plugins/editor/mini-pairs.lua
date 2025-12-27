return {
  "echasnovski/mini.pairs",
  event = "VeryLazy",
  opts = {
    modes = { insert = true, command = true, terminal = false },
    skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
    skip_ts = { "string" },
    skip_unbalanced = true,
    markdown = true,
    ['"'] = { action = "closeopen", pair = '""', neigh_pattern = "[^%w\\][^%w]", register = { cr = false } },
    ["'"] = { action = "closeopen", pair = "''", neigh_pattern = "[^%w\\][^%w]", register = { cr = false } },
  },
  config = function(_, opts)
    Utils.map.set({
      "<leader>up",
      get = function()
        return not vim.g.minipairs_disable
      end,
      set = function(state)
        vim.g.minipairs_disable = state
      end,
      name = "Mini Pairs",
    })
    local pairs = require("mini.pairs")
    pairs.setup(opts)
    local open = pairs.open
    ---@diagnostic disable-next-line: duplicate-set-field
    pairs.open = function(pair, neigh_pattern)
      if vim.fn.getcmdline() ~= "" then return open(pair, neigh_pattern) end
      local o, c = pair:sub(1, 1), pair:sub(2, 2)
      local line = vim.api.nvim_get_current_line()
      local cursor = vim.api.nvim_win_get_cursor(0)
      local next = line:sub(cursor[2] + 1, cursor[2] + 1)
      local before = line:sub(1, cursor[2])
      local prev = cursor[2] > 0 and line:sub(cursor[2], cursor[2]) or ""
      local at_end_of_word = prev:match("%w")

      if at_end_of_word and o == c then return o end
      if o == c then
        local _, count = before:gsub(vim.pesc(o), "")
        if count % 2 == 1 then return o end
      end

      if opts.markdown and o == "`" and vim.bo.filetype == "markdown" then
        if before:match("^%s*``$") or before:match("%s``$") then return "`\n\n```" end
        if before:match("^%s*```$") or before:match("%s```$") then return "`" end
      end

      if opts.skip_next and next ~= "" and next:match(opts.skip_next) then return o end

      if opts.skip_ts and #opts.skip_ts > 0 then
        local ok, captures = pcall(vim.treesitter.get_captures_atpos, 0, cursor[1] - 1, math.max(cursor[2] - 1, 0))
        for _, capture in ipairs(ok and captures or {}) do
          if vim.tbl_contains(opts.skip_ts, capture.capture) then return o end
        end
      end

      if opts.skip_unbalanced and next == c and c ~= o then
        local _, count_open = line:gsub(vim.pesc(o), "")
        local _, count_close = line:gsub(vim.pesc(c), "")
        if count_close > count_open then return o end
      end

      return open(pair, neigh_pattern)
    end
  end,
}
