local M = {}

M.new_file = function()
  -- Ask for the file path and name
  local path_and_filename = vim.fn.input("Enter file name: ")

  -- Check if the prompt was canceled
  if path_and_filename == "" then
    return
  end

  -- Split the input into path and filename
  local path, filename = vim.fn.fnamemodify(path_and_filename, ":p:h"), vim.fn.fnamemodify(path_and_filename, ":t")

  -- Create the necessary directories if they don't exist
  vim.fn.mkdir(path, "p")

  -- Combine the path and filename
  local full_path = path .. "/" .. filename

  -- Create the file
  local success, error_msg = pcall(vim.fn.writefile, { "" }, full_path)
  if not success then
    vim.api.nvim_err_writeln("Error creating file: " .. error_msg)
    return
  end

  -- Open the new file in a new buffer
  vim.cmd("e " .. full_path)
end

return M
