-- ~/.config/nvim/lsp/lua_ls.lua
-- Reference: https://neovim.io/doc/user/lsp.html
vim.lsp.config['lua_ls'] = {
  cmd = { 'lua-language-server' },
  codeActionProvider = {
    codeActionKinds = { "", "quickfix", "refactor.rewrite", "refactor.extract" },
    resolveProvider = true
  },
  colorProvider = true,
  filetypes = { 'lua' },
  semanticTokensProvider = {
    full = true,
    legend = {
      tokenModifiers = { "declaration", "definition", "readonly", "static", "deprecated", "abstract", "async", "modification", "documentation", "defaultLibrary", "global" },
      tokenTypes = { "namespace", "type", "class", "enum", "interface", "struct", "typeParameter", "parameter", "variable", "property", "enumMember", "event", "function", "method", "macro", "keyword", "modifier", "comment", "string", "number", "regexp", "operator", "decorator" }
    },
    range = true
  },
  	root_markers = { '.luarc.json', '.luarc.jsonc', ".luarc.json5", '.stylua.toml', 'luacheckrc', '.luacheckrc' },
  settings = {
    Lua = {
      format = {
        enable = true,
        defaultConfig = {
          align_continuous_rect_table_field = true,
          align_array_table = true,
          indent_style = "space",
          indent_size = "2",
          quote_style = 'ForceSingle',
          trailing_table_separator = "always",
          align_continuous_assign_statement = true,
        },
      },
      runtime = {
        version = "LuaJIT",
        path = {
          'lua/?.lua',
          'lua/?/init.lua',
        },
      },
      diagnostics = {
        enable = true,
        globals = { "vim", "jit", "use", "require" },
        disable = { "lowercase-global" },
        severity = { ["unused-local"] = "Hint" },
        unusedLocalExclude = { "_*" },
      },
      workspace = {
        checkThirdParty = true,
        library = {
          vim.api.nvim_get_runtime_file('', true),
          vim.env.VIMRUNTIME,
          "${3rd}/lazy.nvim/library",
          vim.fn.expand("$HOME") .. "/.config/nvim/lua/"
        },
        ignoreDir = { "node_modules", "build" },
        maxPreload = 2000,
        preloadFileSize = 50000,
      },
      telemetry = {
        enable = false,
      },
      completion = {
        callSnippet = "Replace",
        keywordSnippet = "Disable",
        displayContext = 4,
      },
      hint = {
        enable = true,
        setType = true,
        paramType = true,
        paramName = "All",
        arrayIndex = "Enable",
        await = true,
      },
    },
  },
  flags = {
    debounce_text_changes = 150,
  },
  single_file_support = true,
}
