return {
  {
    "ChmaraX/herdr-nvim",
    -- The herdr sidebar loads its own copy and runs setup; a second one warns on every keymap.
    cond = vim.env.HERDR_PLUGIN_ID == nil,
    opts = {},
  },
}
