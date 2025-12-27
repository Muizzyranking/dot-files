return {
  cmd = { "basedpyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = {
    "pyrightconfig.json",
    "pyproject.toml",
    "setup.py",
    "setup.cfg",
    "requirements.txt",
    "Pipfile",
    ".git",
  },
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
        typeCheckingMode = "standard",
        autoImportCompletions = true,
        diagnosticSeverityOverrides = {
          reportUnusedImport = "information",
          reportUnusedVariable = "information",
        },
      },
      disableOrganizeImports = true,
    },
  },
  on_attach = function(client, bufnr)
    local root = Utils.root(bufnr)
    local venv = Utils.lang.py.detect_and_activate_venv(root)
    if venv and venv.python_path then
      local new_settings = vim.tbl_deep_extend("force", client.config.settings or {}, {
        python = { pythonPath = venv.python_path },
      })

      client.config.settings = new_settings
      client.notify("workspace/didChangeConfiguration", { settings = new_settings })
    end
    local augroup = vim.api.nvim_create_augroup("basedpyright_config_" .. bufnr, { clear = true })
    vim.api.nvim_create_autocmd("BufWritePost", {
      group = augroup,
      pattern = "pyrightconfig.json",
      callback = function()
        Utils.lsp.restart("basedpyright")
        vim.cmd("stopinsert")
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
      end,
    })
  end,
}
