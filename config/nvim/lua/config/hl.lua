local hl = {}

hl.WinBar = {}
hl.WinBarNc = {}

local diagnostic_types = {
  "Warn",
  "Error",
  "Hint",
  "Info",
}
for _, type in ipairs(diagnostic_types) do
  local highlight_name = "InlineDiagnostic" .. type
  hl[highlight_name] = {
    italic = true,
    -- custom link property to copy all or some attributes from the linked highlight group
    link = { name = "Diagnostic" .. type, attrs = { "fg", "bg" } },
  }
end

return hl
