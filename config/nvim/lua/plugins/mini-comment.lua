local comment = "<leader>/"
return {
  "echasnovski/mini.comment",
  opts = {
    options = {
      custom_commentstring = function()
        local filetype = vim.bo.filetype -- Get the current filetype

        --use custom comment for c files
        if filetype == "c" then
          return "/*%s*/" -- Return desired comment style for C
        else
          return nil
        end
      end,
    },
    mappings = {
      comment = comment,

      -- Toggle comment on current line
      comment_line = comment,

      -- Toggle comment on visual selection
      comment_visual = comment,

      -- Define 'comment' textobject (like `dgc` - delete whole comment block)
      -- Works also in Visual mode if mapping differs from `comment_visual`
      textobject = comment,
    },
  },
}
