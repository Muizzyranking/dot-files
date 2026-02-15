local keys = {
  {
    "gd",
    function()
      Utils.lsp.goto_definition()
    end,
    desc = "Goto Definition",
    has = "definition",
  },
  {
    "gD",
    function()
      Utils.lsp.goto_definition({ direction = "vsplit" })
    end,
    desc = "Goto Definition (Vsplit)",
    has = "definition",
  },
  {
    "gr",
    function()
      Snacks.picker.lsp_references()
    end,
    nowait = true,
    desc = "References",
  },
  {
    "gT",
    function()
      Snacks.picker.lsp_implementations()
    end,
    desc = "Goto Implementation",
  },
  {
    "<leader>cs",
    function()
      Snacks.picker.lsp_symbols({
        layout = { preset = "code", preview = "main" },
        on_show = function()
          vim.cmd("stopinsert")
        end,
      })
    end,
    desc = "Lsp Symbols",
    has = "documentSymbol",
  },
  {
    "<c-k>",
    function()
      return vim.lsp.buf.signature_help()
    end,
    desc = "Signature Help",
    has = "signatureHelp",
    mode = "i",
  },
  {
    "K",
    function()
      vim.lsp.buf.hover()
    end,
    desc = "Hover",
    has = "hover",
  },
  { "]d", Utils.lsp.goto_diagnostics(true), desc = "Next Diagnostic" },
  { "[d", Utils.lsp.goto_diagnostics(false), desc = "Prev Diagnostic" },
  { "]e", Utils.lsp.goto_diagnostics(true, "ERROR"), desc = "Next Error" },
  { "[e", Utils.lsp.goto_diagnostics(false, "ERROR"), desc = "Prev Error" },
  { "]w", Utils.lsp.goto_diagnostics(true, "WARN"), desc = "Next Warning" },
  { "[w", Utils.lsp.goto_diagnostics(false, "WARN"), desc = "Prev Warning" },
  { "]i", Utils.lsp.goto_diagnostics(true, "HINT"), desc = "Next Hint" },
  {
    "gy",
    Utils.lsp.copy_diagnostics,
    desc = "Yank diagnostic message on current line",
    icon = { icon = "󰆏 ", color = "blue" },
    mode = { "n", "x" },
  },
  {
    "<leader>cl",
    function()
      vim.cmd.checkhealth("vim.lsp")
    end,
    desc = "Lsp Info",
    icon = { icon = " ", color = "blue" },
  },
  {
    "<leader>cL",
    function()
      local buf = vim.api.nvim_get_current_buf()
      local clients = vim.lsp.get_clients({ bufnr = buf })
      if #clients == 0 then
        Utils.notify.info("No LSP clients attached", { title = "LSP" })
        return
      end
      vim.ui.select(clients, {
        prompt = "Select LSP client to restart:",
        format_item = function(client)
          return client.name
        end,
      }, function(client)
        if client then
          Utils.lsp.restart(client.name)
          vim.defer_fn(function()
            vim.cmd("edit")
          end, 100)
        end
      end)
    end,
    desc = "Restart LSP",
    icon = { icon = "󰜉 ", color = "orange" },
  },
  {
    "<leader>ca",
    vim.lsp.buf.code_action,
    desc = "Code Action",
    icon = { icon = " ", color = "orange" },
    has = "codeAction",
    mode = { "n", "v" },
  },
  {
    "<leader>cr",
    function()
      local inc_rename = require("inc_rename")
      return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand("<cword>")
    end,
    desc = "Rename",
    icon = { icon = "󰑕 ", color = "orange" },
    expr = true,
    has = "rename",
    silent = false,
  },
  {
    "<leader>ui",
    get = function(buf)
      return vim.lsp.inlay_hint.is_enabled({ bufnr = buf })
    end,
    set = function(state, buf)
      vim.lsp.inlay_hint.enable(not state, { bufnr = buf })
    end,
    name = "Inlay hint",
    has = "inlayHint",
  },
}

local M = {}
function M.setup()
  Utils.map.del({ "gra", "grn", "grr", "gri", "grt" }, { mode = "n", lsp = true })
  Utils.map.set(keys, { lsp = true })
end

return M
