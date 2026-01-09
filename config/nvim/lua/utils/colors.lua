---@class utils.colors
local M = {}

---@class ColorPalette
---@field fg string
---@field fg_bright string
---@field fg_dim string
---@field fg_dimmer string
---@field bg_dark string
---@field surface string
---@field surface_light string
---@field red string
---@field red_alt string
---@field orange string
---@field green string
---@field blue string
---@field cyan string
---@field purple string
---@field magenta string
---@field error string
---@field warning string
---@field info string
---@field hint string
---@field diff_add string
---@field diff_change string
---@field diff_delete string
---@field diff_text string
---@field none string

---@type ColorPalette?
M.palette = nil

-- Helper to set highlight group
local function set_hl(group, opts)
  vim.api.nvim_set_hl(0, group, opts)
end

-- Define all highlight groups using the palette
local function apply_highlights(c)
  -- Editor highlights
  set_hl("Normal", { fg = c.fg, bg = c.none })
  set_hl("NormalFloat", { fg = c.fg, bg = c.none })
  set_hl("FloatBorder", { fg = c.blue, bg = c.none })
  set_hl("NormalNC", { fg = c.fg, bg = c.none })
  set_hl("SignColumn", { bg = c.none })
  set_hl("LineNr", { fg = c.fg_dimmer, bg = c.none })
  set_hl("CursorLineNr", { fg = c.blue, bg = c.none, bold = true })
  set_hl("CursorLine", { bg = c.surface })
  set_hl("ColorColumn", { bg = c.surface })
  set_hl("Cursor", { fg = c.surface, bg = c.fg })
  set_hl("CursorColumn", { bg = c.surface })

  -- Visual selection
  set_hl("Visual", { bg = c.surface_light })
  set_hl("VisualNOS", { bg = c.surface_light })

  -- Search
  set_hl("Search", { fg = c.bg_dark, bg = c.orange })
  set_hl("IncSearch", { fg = c.bg_dark, bg = c.red })
  set_hl("CurSearch", { fg = c.bg_dark, bg = c.red })

  -- Statusline
  set_hl("StatusLine", { fg = c.fg, bg = c.none })
  set_hl("StatusLineNC", { fg = c.fg_dim, bg = c.none })

  -- Popup menu
  set_hl("Pmenu", { fg = c.fg, bg = c.none })
  set_hl("PmenuSel", { fg = c.bg_dark, bg = c.blue, bold = true })
  set_hl("PmenuSbar", { bg = c.surface_light })
  set_hl("PmenuThumb", { bg = c.fg_dim })

  -- Splits
  set_hl("VertSplit", { fg = c.surface, bg = c.none })
  set_hl("WinSeparator", { fg = c.surface, bg = c.none })

  -- Diff
  set_hl("DiffAdd", { bg = c.diff_add })
  set_hl("DiffChange", { bg = c.diff_change })
  set_hl("DiffDelete", { bg = c.diff_delete })
  set_hl("DiffText", { bg = c.diff_text })

  set_hl("Folded", { fg = c.fg_dim, bg = c.none })
  set_hl("FoldColumn", { fg = c.fg_dimmer, bg = c.none })

  -- Git signs
  set_hl("GitSignsAdd", { fg = c.green })
  set_hl("GitSignsChange", { fg = c.warning })
  set_hl("GitSignsDelete", { fg = c.red })

  -- Core syntax
  set_hl("Comment", { fg = c.fg_dimmer, italic = true })
  set_hl("Constant", { fg = c.purple })
  set_hl("String", { fg = c.green, italic = true })
  set_hl("Character", { fg = c.green, italic = true })
  set_hl("Number", { fg = c.purple })
  set_hl("Boolean", { fg = c.purple })
  set_hl("Float", { fg = c.purple })
  set_hl("Identifier", { fg = c.fg })
  set_hl("Function", { fg = c.blue, italic = true })
  set_hl("Statement", { fg = c.red, italic = true })
  set_hl("Conditional", { fg = c.red_alt, italic = true })
  set_hl("Repeat", { fg = c.red, italic = true })
  set_hl("Label", { fg = c.red, italic = true })
  set_hl("Operator", { fg = c.blue })
  set_hl("Keyword", { fg = c.red, italic = true })
  set_hl("Exception", { fg = c.red, italic = true })
  set_hl("PreProc", { fg = c.red, italic = true })
  set_hl("Include", { fg = c.red, italic = true })
  set_hl("Define", { fg = c.red, italic = true })
  set_hl("Macro", { fg = c.red, italic = true })
  set_hl("PreCondit", { fg = c.red, italic = true })
  set_hl("Type", { fg = c.red_alt })
  set_hl("StorageClass", { fg = c.red, italic = true })
  set_hl("Structure", { fg = c.red_alt })
  set_hl("Typedef", { fg = c.red_alt })
  set_hl("Special", { fg = c.cyan })
  set_hl("SpecialChar", { fg = c.cyan })
  set_hl("Tag", { fg = c.blue })
  set_hl("Delimiter", { fg = c.fg_dim })
  set_hl("SpecialComment", { fg = c.fg_dimmer, italic = true })
  set_hl("Debug", { fg = c.red })
  set_hl("Underlined", { underline = true })
  set_hl("Ignore", { fg = c.fg_dimmer })
  set_hl("Error", { fg = c.error, bold = true })
  set_hl("Todo", { fg = c.bg_dark, bg = c.warning, bold = true })

  -- Treesitter
  set_hl("@variable", { fg = c.fg })
  set_hl("@variable.builtin", { fg = c.red, italic = true })
  set_hl("@variable.parameter", { fg = c.fg_bright, italic = true })
  set_hl("@variable.member", { fg = c.fg })
  set_hl("@constant", { fg = c.purple })
  set_hl("@constant.builtin", { fg = c.purple })
  set_hl("@constant.macro", { fg = c.purple })
  set_hl("@string", { fg = c.green, italic = true })
  set_hl("@string.documentation", { fg = c.orange, italic = true })
  set_hl("@string.escape", { fg = c.cyan })
  set_hl("@string.regex", { fg = c.cyan })
  set_hl("@character", { fg = c.green, italic = true })
  set_hl("@number", { fg = c.purple })
  set_hl("@boolean", { fg = c.purple })
  set_hl("@float", { fg = c.purple })
  set_hl("@function", { fg = c.blue, italic = true })
  set_hl("@function.builtin", { fg = c.blue, italic = true })
  set_hl("@function.macro", { fg = c.blue, italic = true })
  set_hl("@function.call", { fg = c.blue, italic = true })
  set_hl("@method", { fg = c.blue, italic = true })
  set_hl("@method.call", { fg = c.blue, italic = true })
  set_hl("@constructor", { fg = c.blue, italic = true })
  set_hl("@constructor.lua", { fg = c.blue })
  set_hl("@parameter", { fg = c.fg_bright, italic = true })
  set_hl("@keyword", { fg = c.red, italic = true })
  set_hl("@keyword.function", { fg = c.red, italic = true })
  set_hl("@keyword.operator", { fg = c.red, italic = true })
  set_hl("@keyword.return", { fg = c.red, italic = true })
  set_hl("@keyword.import", { fg = c.red, italic = true })
  set_hl("@keyword.conditional", { fg = c.red_alt, italic = true })
  set_hl("@conditional", { fg = c.red_alt, italic = true })
  set_hl("@repeat", { fg = c.red, italic = true })
  set_hl("@label", { fg = c.cyan })
  set_hl("@operator", { fg = c.blue })
  set_hl("@exception", { fg = c.red, italic = true })
  set_hl("@type", { fg = c.red_alt })
  set_hl("@type.builtin", { fg = c.red_alt })
  set_hl("@type.qualifier", { fg = c.red, italic = true })
  set_hl("@type.definition", { fg = c.red_alt })
  set_hl("@property", { fg = c.fg })
  set_hl("@field", { fg = c.fg })
  set_hl("@punctuation.delimiter", { fg = c.fg_dim })
  set_hl("@punctuation.bracket", { fg = c.fg_dim })
  set_hl("@punctuation.bracket.lua", { fg = c.fg_dim })
  set_hl("@punctuation.special", { fg = c.cyan })
  set_hl("@comment", { fg = c.fg_dimmer, italic = true })
  set_hl("@tag", { fg = c.red, italic = true })
  set_hl("@tag.attribute", { fg = c.purple })
  set_hl("@tag.delimiter", { fg = c.fg_dim })
  set_hl("@namespace", { fg = c.cyan })
  set_hl("@attribute", { fg = c.cyan })

  -- LSP & Diagnostics
  set_hl("DiagnosticError", { fg = c.error })
  set_hl("DiagnosticWarn", { fg = c.warning })
  set_hl("DiagnosticInfo", { fg = c.info })
  set_hl("DiagnosticHint", { fg = c.hint })
  set_hl("DiagnosticUnderlineError", { sp = c.error, undercurl = true })
  set_hl("DiagnosticUnderlineWarn", { sp = c.warning, undercurl = true })
  set_hl("DiagnosticUnderlineInfo", { sp = c.info, undercurl = true })
  set_hl("DiagnosticUnderlineHint", { sp = c.hint, undercurl = true })
  set_hl("LspReferenceText", { bg = c.surface })
  set_hl("LspReferenceRead", { bg = c.surface })
  set_hl("LspReferenceWrite", { bg = c.surface })

  -- Flash.nvim
  set_hl("FlashLabel", { fg = c.bg_dark, bg = c.red, bold = true })
  set_hl("FlashMatch", { fg = c.blue, bold = true })
  set_hl("FlashCurrent", { fg = c.green, bold = true })

  -- Blink.cmp
  set_hl("BlinkCmpMenu", { fg = c.fg, bg = c.surface })
  set_hl("BlinkCmpMenuBorder", { fg = c.blue, bg = c.none })
  set_hl("BlinkCmpMenuSelection", { fg = c.bg_dark, bg = c.blue, bold = true })
  set_hl("BlinkCmpLabel", { fg = c.fg })
  set_hl("BlinkCmpLabelMatch", { fg = c.blue, bold = true })
  set_hl("BlinkCmpKind", { fg = c.purple })
  set_hl("BlinkCmpDoc", { fg = c.fg, bg = c.surface })
  set_hl("BlinkCmpDocBorder", { fg = c.blue, bg = c.none })

  -- Grug-far
  set_hl("GrugFarResultsMatch", { fg = c.green, bold = true })
  set_hl("GrugFarResultsPath", { fg = c.blue })
  set_hl("GrugFarResultsLineNo", { fg = c.fg_dimmer })

  -- Which-key
  set_hl("WhichKey", { fg = c.red })
  set_hl("WhichKeyGroup", { fg = c.blue })
  set_hl("WhichKeyDesc", { fg = c.fg })
  set_hl("WhichKeySeparator", { fg = c.fg_dimmer })
  set_hl("WhichKeyFloat", { bg = c.none })

  -- Noice
  set_hl("NoicePopup", { fg = c.fg, bg = c.none })
  set_hl("NoicePopupBorder", { fg = c.blue, bg = c.none })
  set_hl("NoiceCmdlinePopup", { fg = c.fg, bg = c.none })
  set_hl("NoiceCmdlinePopupBorder", { fg = c.blue, bg = c.none })
  set_hl("NoiceCmdlineIcon", { fg = c.blue })

  -- Snacks
  set_hl("SnacksIndent", { fg = c.surface })
  set_hl("SnacksIndentScope", { fg = c.purple })

  -- Mini plugins
  set_hl("MiniIconsRed", { fg = c.red })
  set_hl("MiniIconsYellow", { fg = c.orange })
  set_hl("MiniIconsGreen", { fg = c.green })
  set_hl("MiniIconsBlue", { fg = c.blue })
  set_hl("MiniIconsPurple", { fg = c.purple })
  set_hl("MiniIconsCyan", { fg = c.cyan })

  -- Rainbow delimiters
  set_hl("RainbowDelimiterRed", { fg = c.red })
  set_hl("RainbowDelimiterYellow", { fg = c.orange })
  set_hl("RainbowDelimiterBlue", { fg = c.blue })
  set_hl("RainbowDelimiterGreen", { fg = c.magenta })
  set_hl("RainbowDelimiterViolet", { fg = c.purple })
  set_hl("RainbowDelimiterCyan", { fg = c.cyan })

  -- Todo comments
  set_hl("TodoBgFIX", { fg = c.bg_dark, bg = c.error, bold = true })
  set_hl("TodoBgHACK", { fg = c.bg_dark, bg = c.warning, bold = true })
  set_hl("TodoBgTODO", { fg = c.bg_dark, bg = c.info, bold = true })
  set_hl("TodoBgNOTE", { fg = c.bg_dark, bg = c.hint, bold = true })
  set_hl("TodoFgFIX", { fg = c.error })
  set_hl("TodoFgHACK", { fg = c.warning })
  set_hl("TodoFgTODO", { fg = c.info })
  set_hl("TodoFgNOTE", { fg = c.hint })

  -- Trouble
  set_hl("TroubleNormal", { fg = c.fg, bg = c.none })
  set_hl("TroubleText", { fg = c.fg })
  set_hl("TroubleCount", { fg = c.purple, bold = true })
  set_hl("TroubleCode", { fg = c.fg_dim })

  -- Dropbar.nvim
  set_hl("DropBarIconKindFile", { fg = c.fg })
  set_hl("DropBarIconKindFolder", { fg = c.blue })
  set_hl("DropBarIconKindModule", { fg = c.purple })
  set_hl("DropBarIconKindFunction", { fg = c.blue })
  set_hl("DropBarIconKindMethod", { fg = c.blue })
  set_hl("DropBarIconKindClass", { fg = c.red_alt })
  set_hl("DropBarIconKindStruct", { fg = c.red_alt })
  set_hl("DropBarMenuNormalFloat", { fg = c.fg, bg = c.surface })
  set_hl("DropBarMenuFloatBorder", { fg = c.blue, bg = c.none })
  set_hl("DropBarMenuCurrentContext", { bg = c.surface_light })

  -- Tiny-inline-diagnostic.nvim
  set_hl("TinyInlineDiagnosticVirtualTextError", { fg = c.error, italic = true })
  set_hl("TinyInlineDiagnosticVirtualTextWarn", { fg = c.warning, italic = true })
  set_hl("TinyInlineDiagnosticVirtualTextInfo", { fg = c.info, italic = true })
  set_hl("TinyInlineDiagnosticVirtualTextHint", { fg = c.hint, italic = true })

  -- Markview.nvim
  set_hl("MarkviewHeading1", { fg = c.red, bold = true })
  set_hl("MarkviewHeading2", { fg = c.orange, bold = true })
  set_hl("MarkviewHeading3", { fg = c.blue, bold = true })
  set_hl("MarkviewHeading4", { fg = c.cyan, bold = true })
  set_hl("MarkviewHeading5", { fg = c.purple, bold = true })
  set_hl("MarkviewHeading6", { fg = c.magenta, bold = true })
  set_hl("MarkviewCode", { bg = c.surface })
  set_hl("MarkviewInlineCode", { fg = c.green, bg = c.surface })
  set_hl("MarkviewListItemMinus", { fg = c.cyan })
  set_hl("MarkviewListItemPlus", { fg = c.green })
  set_hl("MarkviewListItemStar", { fg = c.orange })
  set_hl("MarkviewBlockQuote", { fg = c.fg_dim, italic = true })

  set_hl("IncRename", { fg = c.bg_dark, bg = c.orange })

  set_hl("TSJoinDelimiter", { fg = c.fg_dim })

  set_hl("zshFunction", { link = "Function" })
end

---@param colors ColorPalette
---@param scheme_name string?
function M.setup(colors, scheme_name)
  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end
  vim.o.termguicolors = true
  vim.g.colors_name = scheme_name or "custom"
  M.palette = colors
  apply_highlights(colors)
end

return M
