return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    -- LazyVim strips these; restore upstream defaults.
    opts = {
      heading = {
        sign = true,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
      checkbox = { enabled = true },
    },
  },
  {
    "folke/snacks.nvim",
    opts = { image = { enabled = true } },
  },
}
