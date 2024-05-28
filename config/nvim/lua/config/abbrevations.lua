local function abbrev(lhs, rhs)
  local cmd = "abbrev " .. lhs .. " " .. rhs
  vim.cmd(cmd)
end

abbrev("dont", "don't")
abbrev("Dont", "Don't")
