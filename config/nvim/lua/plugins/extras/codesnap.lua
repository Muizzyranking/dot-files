return {
  "mistricky/codesnap.nvim",
  build = "make",
  cmd = { "CodeSnap" },
  init = function()
    if vim.fn.readable("~/Pictures/nvim") == 0 then
      vim.fn.mkdir("~/Pictures/nvim")
    end
  end,
  keys = {
    -- { "<leader>cc", "<cmd>CodeSnap<cr>", mode = "x", desc = "Save selected code snapshot into clipboard" },
    { "<leader>cp", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot in ~/Pictures" },
  },
  opts = {
    save_path = "~/Pictures/nvim",
    has_breadcrumbs = false,
    bg_theme = "peach",
    watermark = "Muizzyranking",
  },
}
