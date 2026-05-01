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
        local palette = colors.palette

        return {
          -- ────────────────────────────────────────────────────────────
          -- Основной редактор — прозрачный фон
          -- ────────────────────────────────────────────────────────────
          Normal       = { bg = "none", fg = theme.ui.fg },
          NormalNC     = { bg = "none" },
          SignColumn   = { bg = "none" },
          LineNr       = { bg = "none" },
          CursorLineNr = { bg = "none" },
          StatusLine   = { bg = "none" },
          StatusLineNC = { bg = "none" },
          EndOfBuffer  = { bg = "none" },

          -- ────────────────────────────────────────────────────────────
          -- Floating-окна (общая стилизация для ВСЕХ плагинов)
          -- LSP hover, code actions, :Lazy, :checkhealth, diagnostic float
          -- ────────────────────────────────────────────────────────────
          NormalFloat  = { bg = theme.ui.bg_dim, fg = theme.ui.fg },
          FloatBorder  = { bg = theme.ui.bg_dim, fg = theme.syn.fun },
          FloatTitle   = { bg = theme.ui.bg_dim, fg = theme.syn.special1, bold = true },
          FloatFooter  = { bg = theme.ui.bg_dim, fg = theme.ui.fg_dim },

          -- ────────────────────────────────────────────────────────────
          -- Neo-tree
          -- ────────────────────────────────────────────────────────────
          NeoTreeDirectoryIcon  = { fg = "#e0af68" },
          NeoTreeDirectoryName  = { fg = "#7dcfff" },
          NeoTreeRootName       = { fg = "#bb9af7", bold = true },
          NeoTreeExpander       = { fg = "#7aa2f7" },
          NeoTreeIndentMarker   = { fg = "#bb9af7" },
          -- ИСПРАВЛЕНИЕ: используем тему вместо жёсткого цвета
          NeoTreeFloatBorder    = { bg = theme.ui.bg_dim, fg = theme.syn.fun },
          NeoTreeFloatTitle     = { bg = theme.ui.bg_dim, fg = theme.syn.special1, bold = true },

          -- ────────────────────────────────────────────────────────────
          -- Telescope — единый стиль с floating-окнами
          -- ────────────────────────────────────────────────────────────
          TelescopeNormal         = { bg = theme.ui.bg_dim },
          TelescopePromptNormal   = { bg = theme.ui.bg_m1 },
          TelescopeResultsNormal  = { bg = theme.ui.bg_dim },
          TelescopePreviewNormal  = { bg = theme.ui.bg_dim },
          TelescopeBorder         = { bg = theme.ui.bg_dim, fg = theme.syn.fun },
          TelescopePromptBorder   = { bg = theme.ui.bg_m1,  fg = theme.ui.bg_m1 },
          TelescopeResultsBorder  = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
          TelescopePreviewBorder  = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },
          TelescopePromptTitle    = { bg = theme.syn.fun,    fg = theme.ui.bg_dim, bold = true },
          TelescopeResultsTitle   = { bg = theme.ui.bg_dim,  fg = theme.ui.bg_dim },
          TelescopePreviewTitle   = { bg = theme.vcs.added,  fg = theme.ui.bg_dim, bold = true },
          TelescopeSelection      = { bg = theme.ui.bg_p1 },
          TelescopeMatching       = { fg = theme.syn.special1, bold = true },

          -- ────────────────────────────────────────────────────────────
          -- Aerial (outline panel)
          -- ────────────────────────────────────────────────────────────
          AerialLine              = { bg = theme.ui.bg_p1 },
          -- ИСПРАВЛЕНИЕ: используем тему вместо жёсткого цвета
          AerialGuide             = { fg = theme.ui.bg_p2 },
          AerialNormal            = { bg = "none", fg = theme.ui.fg },

          -- ────────────────────────────────────────────────────────────
          -- indent-blankline (замена жёсткого цвета)
          -- ДОБАВЛЕНО
          -- ────────────────────────────────────────────────────────────
          IblIndent = { fg = theme.ui.bg_p2 },
          IblScope  = { fg = theme.syn.fun, bold = true },

          -- ────────────────────────────────────────────────────────────
          -- Lazy (менеджер плагинов)
          -- ────────────────────────────────────────────────────────────
          LazyNormal              = { bg = theme.ui.bg_dim, fg = theme.ui.fg },
          LazyButton              = { bg = theme.ui.bg_p1, fg = theme.ui.fg },
          LazyButtonActive        = { bg = theme.syn.fun, fg = theme.ui.bg_dim, bold = true },
          LazyH1                  = { bg = theme.syn.fun, fg = theme.ui.bg_dim, bold = true },

          -- ────────────────────────────────────────────────────────────
          -- Which-key (попап биндингов)
          -- ────────────────────────────────────────────────────────────
          WhichKey                = { fg = theme.syn.fun },
          WhichKeyGroup           = { fg = theme.syn.special1 },
          WhichKeyDesc            = { fg = theme.ui.fg },
          WhichKeySeparator       = { fg = theme.ui.fg_dim },
          WhichKeyFloat           = { bg = theme.ui.bg_dim },
          WhichKeyBorder          = { bg = theme.ui.bg_dim, fg = theme.syn.fun },

          -- ────────────────────────────────────────────────────────────
          -- Bufferline (отключен но highlights могут пригодиться при включении)
          -- ────────────────────────────────────────────────────────────
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