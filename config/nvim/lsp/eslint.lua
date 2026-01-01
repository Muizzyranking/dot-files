local lsp = vim.lsp

local biome_config_files = { "biome.json", "biome.jsonc" }
local eslint_config_files = {
  ".eslintrc",
  ".eslintrc.js",
  ".eslintrc.cjs",
  ".eslintrc.yaml",
  ".eslintrc.yml",
  ".eslintrc.json",
  "eslint.config.js",
  "eslint.config.mjs",
  "eslint.config.cjs",
  "eslint.config.ts",
  "eslint.config.mts",
  "eslint.config.cts",
}

return {
  cmd = { "vscode-eslint-language-server", "--stdio" },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
    "vue",
    "svelte",
    "astro",
    "htmlangular",
  },
  workspace_required = true,
  on_attach = function(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, "LspEslintFixAll", function()
      client:request_sync("workspace/executeCommand", {
        command = "eslint.applyAllFixes",
        arguments = {
          {
            uri = vim.uri_from_bufnr(bufnr),
            version = lsp.util.buf_versions[bufnr],
          },
        },
      }, nil, bufnr)
    end, {})
  end,
  root_dir = function(bufnr, on_dir)
    local root_markers = { "package.json", "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", ".git" }
    if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
      return
    end

    local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()
    local biome_root = Utils.root.find_pattern_root(bufnr, biome_config_files, vim.fs.dirname(project_root))
    if biome_root then
      return -- Don't attach ESLint if Biome config exists
    end
    local eslint_root = Utils.root.find_pattern_root(bufnr, eslint_config_files, vim.fs.dirname(project_root))
    if not eslint_root then
      return -- Don't attach if no ESLint config
    end
    on_dir(project_root)
  end,
  settings = {
    validate = "on",
    packageManager = nil,
    useESLintClass = false,
    experimental = {
      useFlatConfig = false,
    },
    workingDirectories = { mode = "auto" },
    codeActionOnSave = {
      enable = false,
      mode = "all",
    },
    format = true,
    quiet = false,
    onIgnoredFiles = "off",
    rulesCustomizations = {},
    run = "onType",
    problems = {
      shortenToSingleLine = false,
    },
    nodePath = "",
    workingDirectory = { mode = "auto" },
    codeAction = {
      disableRuleComment = {
        enable = true,
        location = "separateLine",
      },
      showDocumentation = {
        enable = true,
      },
    },
  },
  before_init = function(_, config)
    local root_dir = config.root_dir
    if root_dir then
      config.settings = config.settings or {}
      config.settings.workspaceFolder = {
        uri = root_dir,
        name = vim.fn.fnamemodify(root_dir, ":t"),
      }
      local flat_config_files = vim.tbl_filter(function(file)
        return file:match("config")
      end, eslint_config_files)

      for _, file in ipairs(flat_config_files) do
        local found_files = vim.fn.globpath(root_dir, file, true, true)
        local filtered_files = {}
        for _, found_file in ipairs(found_files) do
          if string.find(found_file, "[/\\]node_modules[/\\]") == nil then
            table.insert(filtered_files, found_file)
          end
        end

        if #filtered_files > 0 then
          config.settings.experimental = config.settings.experimental or {}
          config.settings.experimental.useFlatConfig = true
          break
        end
      end

      -- Support Yarn2 (PnP) projects
      local pnp_cjs = root_dir .. "/.pnp.cjs"
      local pnp_js = root_dir .. "/.pnp.js"
      if type(config.cmd) == "table" and (vim.uv.fs_stat(pnp_cjs) or vim.uv.fs_stat(pnp_js)) then
        config.cmd = vim.list_extend({ "yarn", "exec" }, config.cmd --[[@as table]])
      end
    end
  end,
  handlers = {
    ["eslint/openDoc"] = function(_, result)
      if result then
        vim.ui.open(result.url)
      end
      return {}
    end,
    ["eslint/confirmESLintExecution"] = function(_, result)
      if not result then
        return
      end
      return 4 -- approved
    end,
    ["eslint/probeFailed"] = function()
      vim.notify("[lspconfig] ESLint probe failed.", vim.log.levels.WARN)
      return {}
    end,
    ["eslint/noLibrary"] = function()
      vim.notify("[lspconfig] Unable to find ESLint library.", vim.log.levels.WARN)
      return {}
    end,
  },
}
