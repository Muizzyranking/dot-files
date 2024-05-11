local comment = "<leader>/"

return {
  "echasnovski/mini.comment",
  opts = {
    options = {
      custom_commentstring = function()
        local filetype = vim.bo.filetype -- Get the current filetype

        --use custom comment for c files
        if filetype == "c" then
          return "/*%s*/"
        end

        -- for some reason sql comment doesnt work
        -- after setting custom comment for c
        if filetype == "sql" then
          return "--%s"
        end
      end,
    },
    mappings = {

      -- Toggle comment on current line
      comment_line = comment,

      -- Toggle comment on visual selection
      comment_visual = comment,
    },
  },
}
