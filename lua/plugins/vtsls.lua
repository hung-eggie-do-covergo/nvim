return {
  "neovim/nvim-lspconfig",
  opts = function(_, opts)
    opts.servers = opts.servers or {}
    opts.servers.vtsls = opts.servers.vtsls or {}

    -- mason-lspconfig auto-enables every installed server; angularls was
    -- attaching to all TS buffers (root matched via nx.json) and spinning up
    -- its own project-wide language service in this Vue monorepo
    opts.servers.angularls = { enabled = false }

    -- vtsls has no documentHighlight provider; LazyVim/illuminate fires
    -- textDocument/documentHighlight on CursorHold and it errors every time.
    -- Strip the capability at attach so nothing routes highlight to vtsls
    -- (falls back to treesitter highlight).
    opts.servers.vtsls.on_attach = function(client, _)
      client.server_capabilities.documentHighlightProvider = false
    end

    -- ensure vue filetype handled by vtsls
    opts.servers.vtsls.filetypes = opts.servers.vtsls.filetypes or {}
    if not vim.tbl_contains(opts.servers.vtsls.filetypes, "vue") then
      table.insert(opts.servers.vtsls.filetypes, "vue")
    end

    opts.servers.vtsls.settings = vim.tbl_deep_extend("force", opts.servers.vtsls.settings or {}, {
      vtsls = {
        -- only load the tsserver project for the file being edited, not every
        -- inferred project root in the monorepo
        autoUseWorkspaceTsdk = true,
        tsserver = {
          globalPlugins = {},
        },
        experimental = {
          -- cap completion entries; full enumeration on a huge monorepo is the
          -- main CPU/RAM sink
          maxInlayHintLength = 30,
          completion = {
            enableServerSideFuzzyMatch = true,
          },
        },
      },
      typescript = {
        tsserver = {
          -- the CoverHealth-Admin program alone needs ~3.4GB heap (measured
          -- via tsc --extendedDiagnostics); a 4096 cap made tsserver SIGABRT
          -- (V8 heap OOM) every 1-2 min and re-parse the world on respawn —
          -- one stable 5-6GB server is cheaper than that crash loop
          maxTsServerMemory = 8192,
          -- drop the second (syntax-only) tsserver process; saves a whole
          -- node instance that duplicates every open file's AST
          useSyntaxServer = "never",
          watchOptions = {
            watchFile = "useFsEventsOnParentDirectory",
            watchDirectory = "useFsEvents",
            fallbackPolling = "dynamicPriority",
            excludeDirectories = { "**/node_modules", "**/dist", "**/.git" },
          },
        },
        disableAutomaticTypeAcquisition = true,
        -- stop indexing build output / deps for auto-import suggestions
        preferences = {
          includePackageJsonAutoImports = "off",
        },
      },
      javascript = {
        tsserver = {
          maxTsServerMemory = 8192,
        },
        disableAutomaticTypeAcquisition = true,
        preferences = {
          includePackageJsonAutoImports = "off",
        },
      },
    })
  end,
}
