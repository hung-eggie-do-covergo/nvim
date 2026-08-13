local function apply_scheme()
  local target = vim.o.background == "light" and "dayfox" or "carbonfox"
  -- Loop terminator: applying a nightfox scheme sets &background, and the
  -- terminal's own background re-detection can re-fire OptionSet background.
  -- Once we're already on the right scheme, do nothing — this stops the
  -- OptionSet -> apply -> OptionSet recursion that otherwise freezes nvim.
  if vim.g.colors_name == target then
    return
  end
  -- Apply twice in the same tick: on the first pass bufferline's ColorScheme
  -- handler computes its fill before nightfox's base highlights settle, so the
  -- bar lags one switch. The second application re-fires ColorScheme against the
  -- settled base, letting bufferline (and lualine) recompute correctly. The
  -- second call doesn't recurse here because it's a direct command, not a
  -- re-entrant apply_scheme.
  vim.cmd.colorscheme(target)
  vim.cmd.colorscheme(target)
end

return {
  {
    "EdenEast/nightfox.nvim",
    name = "nightfox",
    lazy = false,
    priority = 1000,
    config = function(_, opts)
      require("nightfox").setup(opts)
      -- re-apply matching colorscheme whenever the terminal flips background
      -- (ghostty emits an OSC 11 change on macOS dark/light switch; nvim 0.10+
      -- auto-detects it and sets vim.o.background, but the LazyVim colorscheme
      -- callback only runs once at startup)
      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "background",
        -- defer: run after nvim finishes settling the background change, so the
        -- colorscheme command fires ColorScheme against final highlights and
        -- bufferline/lualine recompute correctly (else the bar lags one switch)
        callback = function()
          vim.schedule(apply_scheme)
        end,
      })

      -- herdr (0.7.5) answers the OSC 11 background query, so startup detection
      -- is right, but it never relays the terminal's colour-scheme change
      -- notification (CSI ? 997 ; 1|2 n) to its panes — verified by subscribing
      -- to DEC mode 2031 inside a pane and toggling appearance: zero bytes
      -- arrive. So &background never flips and the autocmd above never fires.
      -- So ask instead of waiting to be told: re-send the OSC 11 query on a
      -- timer. herdr answers with its own current theme background, nvim's
      -- existing reply handler sets &background from it, and the autocmd above
      -- does the rest. Cheaper than shelling out to `defaults` (8 bytes, no
      -- process) and it tracks herdr's theme rather than second-guessing it.
      -- Only inside herdr — every other terminal pushes the change already.
      if vim.env.HERDR_PANE_ID then
        local timer = vim.uv.new_timer()
        timer:start(
          2000,
          2000,
          vim.schedule_wrap(function()
            io.stdout:write("\27]11;?\27\\")
            io.stdout:flush()
          end)
        )
      end
    end,
    opts = {
      options = {
        transparent = false,
        terminal_colors = true,
        styles = {
          comments = "italic",
          keywords = "italic",
          functions = "NONE",
          variables = "NONE",
        },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = apply_scheme,
    },
  },
}
