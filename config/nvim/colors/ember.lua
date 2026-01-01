vim.cmd("highlight clear")
if vim.fn.exists("syntax_on") then
  vim.cmd("syntax reset")
end

vim.o.termguicolors = true
vim.g.colors_name = "ember"

local colors = {
  -- Base colors
  fg = "#c0caf5",
  fg_bright = "#d8e0f0",

  -- Dimmed text
  fg_dim = "#9aa5ce",
  fg_dimmer = "#565f89",

  -- Surface colors
  surface = "#24283b",
  surface_light = "#2f3549",

  -- Vibrant accent colors
  red = "#f7768e",
  red_alt = "#db4b4b",
  orange = "#ff9e64",
  green = "#9ece6a",
  blue = "#7aa2f7",
  cyan = "#7dcfff",
  purple = "#bb9af7",
  magenta = "#c678dd",

  -- Status colors
  error = "#db4b4b",
  warning = "#e0af68",
  info = "#0db9d7",
  hint = "#1abc9c",

  -- Special
  none = "NONE",
}

-- Helper function
local function hi(group, opts)
  local cmd = "highlight " .. group
  if opts.fg then
    cmd = cmd .. " guifg=" .. opts.fg
  end
  if opts.bg then
    cmd = cmd .. " guibg=" .. opts.bg
  end
  if opts.sp then
    cmd = cmd .. " guisp=" .. opts.sp
  end
  if opts.style then
    cmd = cmd .. " gui=" .. opts.style
  end
  vim.cmd(cmd)
end

-- Editor highlights
hi("Normal", { fg = colors.fg, bg = colors.none })
hi("NormalFloat", { fg = colors.fg, bg = colors.none })
hi("FloatBorder", { fg = colors.blue, bg = colors.none })
hi("NormalNC", { fg = colors.fg, bg = colors.none })
hi("SignColumn", { bg = colors.none })
hi("LineNr", { fg = colors.fg_dimmer, bg = colors.none })
hi("CursorLineNr", { fg = colors.blue, bg = colors.none, style = "bold" })
hi("CursorLine", { bg = colors.surface })
hi("ColorColumn", { bg = colors.surface })
hi("Cursor", { fg = colors.surface, bg = colors.fg })
hi("CursorColumn", { bg = colors.surface })

-- Visual selection
hi("Visual", { bg = colors.surface_light })
hi("VisualNOS", { bg = colors.surface_light })

-- Search
hi("Search", { fg = "#1a1b26", bg = colors.orange })
hi("IncSearch", { fg = "#1a1b26", bg = colors.red })
hi("CurSearch", { fg = "#1a1b26", bg = colors.red })

-- Statusline
hi("StatusLine", { fg = colors.fg, bg = colors.none })
hi("StatusLineNC", { fg = colors.fg_dim, bg = colors.none })

-- Popup menu
hi("Pmenu", { fg = colors.fg, bg = colors.none })
hi("PmenuSel", { fg = "#1a1b26", bg = colors.blue, style = "bold" })
hi("PmenuSbar", { bg = colors.surface_light })
hi("PmenuThumb", { bg = colors.fg_dim })

-- Splits
hi("VertSplit", { fg = colors.surface, bg = colors.none })
hi("WinSeparator", { fg = colors.surface, bg = colors.none })

-- Diff
vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#2d3f3a", blend = 10 })
vim.api.nvim_set_hl(0, "DiffChange", { bg = "#3f2d2d", blend = 10 })
vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3f2d35", blend = 10 })
vim.api.nvim_set_hl(0, "DiffText", { bg = "#352d3f", blend = 30 })

hi("Folded", { fg = colors.fg_dim, bg = colors.none })
hi("FoldColumn", { fg = colors.fg_dimmer, bg = colors.none })

-- Git signs
hi("GitSignsAdd", { fg = colors.green })
hi("GitSignsChange", { fg = colors.warning })
hi("GitSignsDelete", { fg = colors.red })

-- Core syntax
hi("Comment", { fg = colors.fg_dimmer, style = "italic" })

hi("Constant", { fg = colors.purple })
hi("String", { fg = colors.green, style = "italic" })
hi("Character", { fg = colors.green, style = "italic" })
hi("Number", { fg = colors.purple })
hi("Boolean", { fg = colors.purple })
hi("Float", { fg = colors.purple })

hi("Identifier", { fg = colors.fg })
hi("Function", { fg = colors.blue, style = "italic" })

hi("Statement", { fg = colors.red, style = "italic" })
hi("Conditional", { fg = colors.red_alt, style = "italic" })
hi("Repeat", { fg = colors.red, style = "italic" })
hi("Label", { fg = colors.red, style = "italic" })
hi("Operator", { fg = colors.blue })
hi("Keyword", { fg = colors.red, style = "italic" })
hi("Exception", { fg = colors.red, style = "italic" })

hi("PreProc", { fg = colors.red, style = "italic" })
hi("Include", { fg = colors.red, style = "italic" })
hi("Define", { fg = colors.red, style = "italic" })
hi("Macro", { fg = colors.red, style = "italic" })
hi("PreCondit", { fg = colors.red, style = "italic" })

hi("Type", { fg = colors.red_alt })
hi("StorageClass", { fg = colors.red, style = "italic" })
hi("Structure", { fg = colors.red_alt })
hi("Typedef", { fg = colors.red_alt })

hi("Special", { fg = colors.cyan })
hi("SpecialChar", { fg = colors.cyan })
hi("Tag", { fg = colors.blue })
hi("Delimiter", { fg = colors.fg_dim, style = "NONE" })
hi("SpecialComment", { fg = colors.fg_dimmer, style = "italic" })
hi("Debug", { fg = colors.red })

hi("Underlined", { style = "underline" })
hi("Ignore", { fg = colors.fg_dimmer })
hi("Error", { fg = colors.error, style = "bold" })
hi("Todo", { fg = "#1a1b26", bg = colors.warning, style = "bold" })

-- Treesitter
hi("@variable", { fg = colors.fg })
hi("@variable.builtin", { fg = colors.red, style = "italic" })
hi("@variable.parameter", { fg = colors.fg_bright, style = "italic" })
hi("@variable.member", { fg = colors.fg })

hi("@constant", { fg = colors.purple })
hi("@constant.builtin", { fg = colors.purple })
hi("@constant.macro", { fg = colors.purple })

hi("@string", { fg = colors.green, style = "italic" })
hi("@string.documentation", { fg = colors.orange, style = "italic" })
hi("@string.escape", { fg = colors.cyan })
hi("@string.regex", { fg = colors.cyan })

hi("@character", { fg = colors.green, style = "italic" })
hi("@number", { fg = colors.purple })
hi("@boolean", { fg = colors.purple })
hi("@float", { fg = colors.purple })

hi("@function", { fg = colors.blue, style = "italic" })
hi("@function.builtin", { fg = colors.blue, style = "italic" })
hi("@function.macro", { fg = colors.blue, style = "italic" })
hi("@function.call", { fg = colors.blue, style = "italic" })
hi("@method", { fg = colors.blue, style = "italic" })
hi("@method.call", { fg = colors.blue, style = "italic" })

hi("@constructor", { fg = colors.blue, style = "italic" })
hi("@constructor.lua", { fg = colors.blue })
hi("@parameter", { fg = colors.fg_bright, style = "italic" })

hi("@keyword", { fg = colors.red, style = "italic" })
hi("@keyword.function", { fg = colors.red, style = "italic" })
hi("@keyword.operator", { fg = colors.red, style = "italic" })
hi("@keyword.return", { fg = colors.red, style = "italic" })
hi("@keyword.import", { fg = colors.red, style = "italic" })
hi("@keyword.conditional", { fg = colors.red_alt, style = "italic" })

hi("@conditional", { fg = colors.red_alt, style = "italic" })
hi("@repeat", { fg = colors.red, style = "italic" })
hi("@label", { fg = colors.cyan })
hi("@operator", { fg = colors.blue })
hi("@exception", { fg = colors.red, style = "italic" })

hi("@type", { fg = colors.red_alt })
hi("@type.builtin", { fg = colors.red_alt })
hi("@type.qualifier", { fg = colors.red, style = "italic" })
hi("@type.definition", { fg = colors.red_alt })

hi("@property", { fg = colors.fg })
hi("@field", { fg = colors.fg })

hi("@punctuation.delimiter", { fg = colors.fg_dim })
hi("@punctuation.bracket", { fg = colors.fg_dim })
hi("@punctuation.bracket.lua", { fg = colors.fg_dim })
hi("@punctuation.special", { fg = colors.cyan })

hi("@comment", { fg = colors.fg_dimmer, style = "italic" })
hi("@tag", { fg = colors.red, style = "italic" })
hi("@tag.attribute", { fg = colors.purple })
hi("@tag.delimiter", { fg = colors.fg_dim, style = "NONE" })

-- Additional language-specific
hi("@namespace", { fg = colors.cyan })
hi("@attribute", { fg = colors.cyan })

-- LSP & Diagnostics
hi("DiagnosticError", { fg = colors.error })
hi("DiagnosticWarn", { fg = colors.warning })
hi("DiagnosticInfo", { fg = colors.info })
hi("DiagnosticHint", { fg = colors.hint })

hi("DiagnosticUnderlineError", { sp = colors.error, style = "undercurl" })
hi("DiagnosticUnderlineWarn", { sp = colors.warning, style = "undercurl" })
hi("DiagnosticUnderlineInfo", { sp = colors.info, style = "undercurl" })
hi("DiagnosticUnderlineHint", { sp = colors.hint, style = "undercurl" })

hi("LspReferenceText", { bg = colors.surface })
hi("LspReferenceRead", { bg = colors.surface })
hi("LspReferenceWrite", { bg = colors.surface })

-- Flash.nvim
hi("FlashLabel", { fg = "#1a1b26", bg = colors.red, style = "bold" })
hi("FlashMatch", { fg = colors.blue, style = "bold" })
hi("FlashCurrent", { fg = colors.green, style = "bold" })

-- Blink.cmp
hi("BlinkCmpMenu", { fg = colors.fg, bg = colors.surface })
hi("BlinkCmpMenuBorder", { fg = colors.blue, bg = colors.none })
hi("BlinkCmpMenuSelection", { fg = "#1a1b26", bg = colors.blue, style = "bold" })
hi("BlinkCmpLabel", { fg = colors.fg })
hi("BlinkCmpLabelMatch", { fg = colors.blue, style = "bold" })
hi("BlinkCmpKind", { fg = colors.purple })
hi("BlinkCmpDoc", { fg = colors.fg, bg = colors.surface })
hi("BlinkCmpDocBorder", { fg = colors.blue, bg = colors.none })

-- Grug-far
hi("GrugFarResultsMatch", { fg = colors.green, style = "bold" })
hi("GrugFarResultsPath", { fg = colors.blue })
hi("GrugFarResultsLineNo", { fg = colors.fg_dimmer })

-- Which-key
hi("WhichKey", { fg = colors.red })
hi("WhichKeyGroup", { fg = colors.blue })
hi("WhichKeyDesc", { fg = colors.fg })
hi("WhichKeySeparator", { fg = colors.fg_dimmer })
hi("WhichKeyFloat", { bg = colors.none })

-- Noice
hi("NoicePopup", { fg = colors.fg, bg = colors.none })
hi("NoicePopupBorder", { fg = colors.blue, bg = colors.none })
hi("NoiceCmdlinePopup", { fg = colors.fg, bg = colors.none })
hi("NoiceCmdlinePopupBorder", { fg = colors.blue, bg = colors.none })
hi("NoiceCmdlineIcon", { fg = colors.blue })

-- Snacks
hi("SnacksIndent", { fg = colors.surface })
hi("SnacksIndentScope", { fg = colors.purple })

-- Mini plugins
hi("MiniIconsRed", { fg = colors.red })
hi("MiniIconsYellow", { fg = colors.orange })
hi("MiniIconsGreen", { fg = colors.green })
hi("MiniIconsBlue", { fg = colors.blue })
hi("MiniIconsPurple", { fg = colors.purple })
hi("MiniIconsCyan", { fg = colors.cyan })

-- Rainbow delimiters
hi("RainbowDelimiterRed", { fg = colors.red })
hi("RainbowDelimiterYellow", { fg = colors.orange })
hi("RainbowDelimiterBlue", { fg = colors.blue })
hi("RainbowDelimiterGreen", { fg = colors.magenta })
hi("RainbowDelimiterViolet", { fg = colors.purple })
hi("RainbowDelimiterCyan", { fg = colors.cyan })
-- Todo comments
hi("TodoBgFIX", { fg = "#1a1b26", bg = colors.error, style = "bold" })
hi("TodoBgHACK", { fg = "#1a1b26", bg = colors.warning, style = "bold" })
hi("TodoBgTODO", { fg = "#1a1b26", bg = colors.info, style = "bold" })
hi("TodoBgNOTE", { fg = "#1a1b26", bg = colors.hint, style = "bold" })
hi("TodoFgFIX", { fg = colors.error })
hi("TodoFgHACK", { fg = colors.warning })
hi("TodoFgTODO", { fg = colors.info })
hi("TodoFgNOTE", { fg = colors.hint })

-- Trouble
hi("TroubleNormal", { fg = colors.fg, bg = colors.none })
hi("TroubleText", { fg = colors.fg })
hi("TroubleCount", { fg = colors.purple, style = "bold" })
hi("TroubleCode", { fg = colors.fg_dim })
