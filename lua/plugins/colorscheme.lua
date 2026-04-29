-- ============================================================================
-- lua/plugins/colorscheme.lua
-- ============================================================================

return {
  {
    "rebelot/kanagawa.nvim",

    priority = 1000,
    lazy = false,

    opts = {
      compile = false,
      undercurl = true,
      commentStyle = { italic = true },
      functionStyle = {},
      keywordStyle = { italic = false },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = true,
      dimInactive = false,
      terminalColors = true,
      theme = "wave",
      background = {
        dark = "wave",
        light = "lotus",
      },

      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },

      overrides = function(colors)
        local theme = colors.theme

        return {
          -- основные UI-зоны редактора — прозрачные
          NormalNC     = { bg = "none" },
          SignColumn   = { bg = "none" },
          LineNr       = { bg = "none" },
          CursorLineNr = { bg = "none" },
          StatusLine   = { bg = "none" },
          StatusLineNC = { bg = "none" },
          EndOfBuffer  = { bg = "none" },

          -- bufferline — сплошная плашка под всю ширину,
          -- чтобы полоса не "протекала" обоями справа.
          BufferLineFill                = { bg = theme.ui.bg_dim },
          BufferLineBackground          = { bg = theme.ui.bg_dim, fg = theme.ui.fg_dim },
          BufferLineBufferVisible       = { bg = theme.ui.bg_dim, fg = theme.ui.fg_dim },
          BufferLineBufferSelected      = { bg = theme.ui.bg_p1, fg = theme.ui.fg, bold = true },
          BufferLineModified            = { bg = theme.ui.bg_dim, fg = theme.diag.warning },
          BufferLineModifiedVisible     = { bg = theme.ui.bg_dim, fg = theme.diag.warning },
          BufferLineModifiedSelected    = { bg = theme.ui.bg_p1, fg = theme.diag.warning },
          BufferLineSeparator           = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
          BufferLineSeparatorVisible    = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
          BufferLineSeparatorSelected   = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
          BufferLineIndicatorSelected   = { bg = theme.ui.bg_p1, fg = theme.syn.fun },
          BufferLineCloseButton         = { bg = theme.ui.bg_dim, fg = theme.ui.fg_dim },
          BufferLineCloseButtonVisible  = { bg = theme.ui.bg_dim, fg = theme.ui.fg_dim },
          BufferLineCloseButtonSelected = { bg = theme.ui.bg_p1, fg = theme.ui.fg },
        }
      end,
    },

    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd.colorscheme("kanagawa")
    end,
  },
}