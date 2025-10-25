---@class utils.hl
local M = {}
M._highlights = {}

------------------------------------------------------------------------------
-- Get the color of a highlight group
---@param name string
---@param ground? "fg"|"bg"
---@return string?
------------------------------------------------------------------------------
function M.get_hl_color(name, ground)
  ground = ground or "fg"
  assert(ground == "fg" or ground == "bg", "ground must be 'fg' or 'bg'")
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  local color = hl and (ground == "fg" and (hl.fg or hl.foreground) or (hl.bg or hl.background))
  return color and ("#%06x"):format(color) or nil
end

-----------------------------------------------
-- add/override highlights
---@param highlights table<string, table>
-----------------------------------------------
function M.add_highlights(highlights)
  for group, opts in pairs(highlights) do
    local hl_name = opts.name or group
    opts.name = nil
    M._highlights[hl_name] = vim.tbl_extend("force", M._highlights[hl_name] or {}, opts)
  end
end

function M.set_hl(hl)
  hl = hl or M._highlights
  for group, opts in pairs(hl) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

-----------------------------------------------
-- apply the highlights
-----------------------------------------------
function M.setup()
  local breadcrumb_hl = {
    BreadcrumbsFile = { link = "Directory" },
    BreadcrumbsModule = { link = "Include" },
    BreadcrumbsNamespace = { link = "Include" },
    BreadcrumbsPackage = { link = "Include" },
    BreadcrumbsClass = { link = "Type" },
    BreadcrumbsMethod = { link = "Function" },
    BreadcrumbsProperty = { link = "Identifier" },
    BreadcrumbsField = { link = "Identifier" },
    BreadcrumbsConstructor = { link = "Special" },
    BreadcrumbsEnum = { link = "Type" },
    BreadcrumbsInterface = { link = "Type" },
    BreadcrumbsFunction = { link = "Function" },
    BreadcrumbsVariable = { link = "Identifier" },
    BreadcrumbsConstant = { link = "Constant" },
    BreadcrumbsString = { link = "String" },
    BreadcrumbsNumber = { link = "Number" },
    BreadcrumbsBoolean = { link = "Boolean" },
    BreadcrumbsArray = { link = "Type" },
    BreadcrumbsObject = { link = "Type" },
    BreadcrumbsKey = { link = "Identifier" },
    BreadcrumbsNull = { link = "Comment" },
    BreadcrumbsEnumMember = { link = "Constant" },
    BreadcrumbsStruct = { link = "Structure" },
    BreadcrumbsEvent = { link = "Special" },
    BreadcrumbsOperator = { link = "Operator" },
    BreadcrumbsTypeParameter = { link = "Type" },
  }

  M.add_highlights(breadcrumb_hl)

  M.add_highlights({
    WInBar = {},
    WinBarNc = {},
  })

  Utils.autocmd.autocmd_augroup("custom_hl", {
    {
      group = "custom_hl",
      callback = function()
        M.set_hl()
      end,
      events = { "ColorScheme", "UiEnter" },
    },
    {
      group = "custom_hl",
      callback = function()
        M.set_hl()
      end,
      events = { "User" },
      pattern = "VeryLazy",
    },
  })
end

return M
