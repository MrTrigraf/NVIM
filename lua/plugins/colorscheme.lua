-- ============================================================================
-- lua/plugins/colorscheme.lua
-- kanagawa-paper.nvim — приглушённый форк kanagawa с встроенной поддержкой
-- большинства популярных плагинов через систему groups/plugins/.
-- ============================================================================

return {
  {
    "thesimonho/kanagawa-paper.nvim",

    priority = 1000,
    lazy = false,

    opts = {
      auto_plugins = false,

      plugins = {
        aerial            = true,
        bufferline        = true,
        grug_far          = true,
        indent_blankline  = true,
        lazy              = true,
        mini              = true,
        neo_tree          = true,
        snacks            = true,
        telescope         = true,
        which_key         = true,
      },

      transparent = true,

      styles = {
        comment   = { italic = true },
        functions = {},
        keyword   = { italic = false, bold = false },
        statement = { italic = false, bold = true },
        type      = {},
      },

      overrides = function(colors)
        local theme   = colors.theme
        local palette = colors.palette

        return {
          -- Прозрачный фон
          Normal       = { bg = "none", fg = theme.ui.fg },
          NormalNC     = { bg = "none" },
          SignColumn   = { bg = "none" },
          LineNr       = { bg = "none" },
          CursorLineNr = { bg = "none" },
          StatusLine   = { bg = "none" },
          StatusLineNC = { bg = "none" },
          EndOfBuffer  = { bg = "none" },

          -- Floating-окна — сохраняем привычный вид
          NormalFloat  = { bg = theme.ui.bg_dim, fg = theme.ui.fg },
          FloatBorder  = { bg = theme.ui.bg_dim, fg = theme.syn.fun },
          FloatTitle   = { bg = theme.ui.bg_dim, fg = theme.syn.special1, bold = true },
          FloatFooter  = { bg = theme.ui.bg_dim, fg = theme.ui.fg_dim },

          -- Telescope — чуть плотнее фон, чтобы не просвечивало
          TelescopeNormal        = { bg = theme.ui.bg_dim },
          TelescopePromptNormal  = { bg = theme.ui.bg_m1 },
          TelescopeResultsNormal = { bg = theme.ui.bg_dim },
          TelescopePreviewNormal = { bg = theme.ui.bg_dim },
          
          -- Neo-tree: кастомные цвета папок (из палитры, без жёстких hex)
          NeoTreeDirectoryIcon  = { fg = palette.boatYellow2 },
          NeoTreeDirectoryName  = { fg = palette.springBlue },
          NeoTreeRootName       = { fg = palette.oniViolet, bold = true },
          NeoTreeExpander       = { fg = palette.crystalBlue },
          NeoTreeIndentMarker   = { fg = palette.oniViolet },
          NeoTreeFloatBorder    = { bg = theme.ui.bg_dim, fg = theme.syn.fun },
          NeoTreeFloatTitle     = { bg = theme.ui.bg_dim, fg = theme.syn.special1, bold = true },

          -- Aerial (outline)
          AerialLine   = { bg = theme.ui.bg_p1 },
          AerialGuide  = { fg = theme.ui.bg_p2 },
          AerialNormal = { bg = "none", fg = theme.ui.fg },

          -- indent-blankline
          IblIndent = { fg = theme.ui.bg_p2 },
          IblScope  = { fg = theme.syn.fun, bold = true },

          -- Lazy менеджер
          LazyNormal       = { bg = theme.ui.bg_dim, fg = theme.ui.fg },
          LazyButton       = { bg = theme.ui.bg_p1, fg = theme.ui.fg },
          LazyButtonActive = { bg = theme.syn.fun, fg = theme.ui.bg_dim, bold = true },
          LazyH1           = { bg = theme.syn.fun, fg = theme.ui.bg_dim, bold = true },

          -- Which-key
          WhichKey          = { fg = theme.syn.fun },
          WhichKeyGroup     = { fg = theme.syn.special1 },
          WhichKeyDesc      = { fg = theme.ui.fg },
          WhichKeySeparator = { fg = theme.ui.fg_dim },
          WhichKeyFloat     = { bg = theme.ui.bg_dim },
          WhichKeyBorder    = { bg = theme.ui.bg_dim, fg = theme.syn.fun },

          -- Dashboard (snacks) — цвета для футера
          SnacksDashboardSpecial = { fg = palette.surimiOrange },
          DashboardFooterCount   = { fg = palette.crystalBlue, bold = true },
          DashboardFooterTime    = { fg = palette.waveAqua2 },

          -- Bufferline (на будущее)
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
      require("kanagawa-paper").setup(opts)
      vim.cmd.colorscheme("kanagawa-paper")
    end,
  },
}