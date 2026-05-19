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
          CursorLine = { bg = palette.sumiInk5 },

          -- Floating-окна — сохраняем привычный вид
          NormalFloat = { bg = "none", fg = theme.ui.fg },
          FloatBorder = { bg = "none", fg = theme.syn.fun },
          FloatTitle   = { bg = theme.ui.bg_dim, fg = theme.syn.special1, bold = true },
          FloatFooter  = { bg = theme.ui.bg_dim, fg = theme.ui.fg_dim },

        
          -- Telescope 
          -- Фон (прозрачный)
          TelescopeNormal         = { bg = "none", fg = theme.ui.fg },
          TelescopePromptNormal   = { bg = "none" },
          TelescopeResultsNormal  = { bg = "none" },
          TelescopePreviewNormal  = { bg = "none" },
          -- Рамки в стиле kanagawa-paper
          TelescopeBorder         = { bg = "none", fg = theme.ui.bg_p1 },
          TelescopePromptBorder   = { bg = "none", fg = theme.syn.fun },        -- бирюза
          TelescopeResultsBorder  = { bg = "none", fg = theme.syn.special1 },   -- оранж
          TelescopePreviewBorder  = { bg = "none", fg = palette.oniViolet },    -- фиолет
          -- Заголовки в стиле kanagawa-paper
          TelescopePromptTitle    = { bg = "none", fg = theme.syn.fun, bold = true },        -- бирюза
          TelescopeResultsTitle   = { bg = "none", fg = theme.syn.special1, bold = true },   -- оранж
          TelescopePreviewTitle   = { bg = "none", fg = palette.oniViolet, bold = true },    -- фиолет
          TelescopeTitle          = { bg = "none", fg = theme.syn.special1, bold = true },
          
          -- Neo-tree: кастомные цвета папок (из палитры, без жёстких hex)
          NeoTreeDirectoryIcon  = { fg = palette.boatYellow2 },
          NeoTreeDirectoryName  = { fg = theme.ui.fg },
          NeoTreeRootName       = { fg = palette.oniViolet, bold = true },
          NeoTreeExpander       = { fg = palette.crystalBlue },
          NeoTreeIndentMarker   = { fg = palette.oniViolet },
          NeoTreeFloatBorder    = { bg = theme.ui.bg_dim, fg = theme.syn.fun },
          NeoTreeFloatTitle     = { bg = theme.ui.bg_dim, fg = theme.syn.special1, bold = true },
          -- Neo-tree: прозрачный фон сайдбара, чтобы не дрался с прозрачностью редактора.
          -- kanagawa-paper.plugins.neo_tree = true задаёт сайдбару плотный bg, поэтому
          -- мы тут перебиваем его на none.
          NeoTreeNormal       = { bg = "none" },
          NeoTreeNormalNC     = { bg = "none" },
          NeoTreeEndOfBuffer  = { bg = "none" },
          --NeoTreeWinSeparator = { bg = "none", fg = theme.ui.bg_p1 },
          -- Neo-tree source_selector (вкладки File/Bufs/Git над деревом).
          -- Делаем плашку прозрачной, активной даём акцентный цвет, неактивным —
          -- приглушённый, чтобы было читаемо но не перетягивало внимание.
          NeoTreeTabActive            = { bg = "none", fg = theme.syn.fun, bold = true },
          NeoTreeTabInactive          = { bg = "none", fg = theme.ui.fg_dim },
          NeoTreeTabSeparatorActive   = { bg = "none", fg = theme.syn.fun },
          NeoTreeTabSeparatorInactive = { bg = "none", fg = theme.ui.bg_p1 },

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

          -- Which-key (полная прозрачность + стиль как Telescope/Neo-tree)
          WhichKey          = { fg = theme.syn.fun },
          WhichKeyGroup     = { fg = theme.syn.special1 },
          WhichKeyDesc      = { fg = theme.ui.fg },
          WhichKeySeparator = { fg = theme.ui.fg_dim },
          WhichKeyFloat     = { bg = "none" },  -- прозрачный фон попапа
          WhichKeyNormal    = { bg = "none", fg = theme.syn.special1 },  -- основной текст
          WhichKeyBorder    = { bg = "none", fg = palette.oniViolet },  -- бирюзовая рамка
          WhichKeyTitle     = { bg = "none", fg = theme.syn.special1, bold = true },  -- title без фона
          WhichKeyValue     = { fg = theme.ui.fg_dim },
          WhichKeyIcon      = { fg = theme.syn.fun },

          -- Dashboard (snacks) — цвета для футера
          SnacksDashboardSpecial = { fg = palette.surimiOrange },
          DashboardFooterCount   = { fg = palette.crystalBlue, bold = true },
          DashboardFooterTime    = { fg = palette.waveAqua2 },

          -- ── lualine "buffers" компонент ────────────────────────────
          LualineBufferActive   = { bg = "none", fg = palette.crystalBlue, bold = true },
          LualineBufferInactive = { bg = "none", fg = theme.ui.fg_dim },

          -- ── Mason LSP компонент ────────────────────────────
          -- Ключевое: используем theme.ui.bg_dim / theme.ui.fg_dim (с подчёркиванием)
          MasonNormal           = { bg = "none", fg = theme.ui.fg },
          MasonBorder           = { bg = "none", fg = theme.syn.fun },
          MasonHeader           = { bg = "none", fg = theme.syn.special1, bold = true },
          MasonHeaderSecondary  = { bg = "none", fg = theme.syn.fun, bold = true },
          MasonMuted            = { fg = theme.ui.fg_dim },
          MasonHighlight        = { fg = theme.syn.fun },
          MasonHighlightBlock   = { fg = theme.syn.special1 },
          MasonHighlightBlockBold = { fg = theme.syn.special1, bold = true },
          MasonHighlightSecondary = { fg = theme.syn.fun },
          MasonLink             = { fg = palette.crystalBlue },
          MasonError            = { fg = palette.surimiOrange },
          MasonWarning          = { fg = palette.waveRed },
        }
      end,
    },

    config = function(_, opts)
      require("kanagawa-paper").setup(opts)
      vim.cmd.colorscheme("kanagawa-paper")
    end,
  },
}