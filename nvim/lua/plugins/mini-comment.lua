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
  },
}
