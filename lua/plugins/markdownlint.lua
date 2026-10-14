return {
  "mfussenegger/nvim-lint",
  opts = function()
    -- nvim-lint feeds the buffer via stdin, so cli2 can't discover a config by path.
    require("lint").linters["markdownlint-cli2"].args =
      { "--config", vim.fn.expand("~/.markdownlint-cli2.jsonc"), "-" }
  end,
}
