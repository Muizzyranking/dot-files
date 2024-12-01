return {
  "muizzyranking/rainbow-delimiters.nvim",
  event = { "BufRead", "BufReadPre" },
  opts = {
    enable_when = function(bufnr)
      local max_filesize = vim.g.big_file or 1.5 * 1024 * 1024 -- 1 MB
      local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
      if ok and stats and stats.size > max_filesize then
        return nil
      end
    end,
  },
  -- config = function()
  --   require("rainbow-delimiters.setup").setup({
  --     enable_when = function(bufnr)
  --       local max_filesize = 1 * 1024 * 1024 -- 1 MB
  --       local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
  --       if ok and stats and stats.size > max_filesize then
  --         return nil
  --       end
  --     end,
  --   })
  -- end,
}
