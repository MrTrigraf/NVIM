-- ============================================================================
-- lua/plugins/visuals.lua
-- Визуальные QoL-плагины: цвета, скобки, анимации.
-- Собраны в один файл, чтобы их было легко найти и при необходимости
-- временно отключить целиком.
-- ============================================================================

return {
  -- ==========================================================================
  -- nvim-colorizer.lua (форк catgoose) — превью цветов в коде.
  -- ==========================================================================
  {
    "catgoose/nvim-colorizer.lua",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      -- В каких filetype'ах включать. "*" = во всех, плюс особый режим
      -- для html/css (там разрешаем именованные цвета и Tailwind).
      filetypes = {
        "*",
        html = { names = true, tailwind = true },
        css  = { names = true, tailwind = true },
      },
      user_default_options = {
        names           = false,            -- НЕ красить слова "red"/"blue" — слишком много ложных срабатываний в коде
        RGB             = true,             -- #RGB
        RRGGBB          = true,             -- #RRGGBB
        RRGGBBAA        = true,             -- #RRGGBBAA с альфой
        rgb_fn          = true,             -- rgb()/rgba()
        hsl_fn          = true,             -- hsl()/hsla()
        css             = false,            -- НЕ включаем весь css-набор разом
        css_fn          = false,
        mode            = "virtualtext",    -- цветной квадрат рядом с hex-кодом
        tailwind        = false,            -- Tailwind включаем только в html/css выше
        sass            = { enable = false },
        virtualtext     = "\u{25A0}",       -- запасной режим (квадрат), если mode переключить
        virtualtext_inline = "before",      -- квадратик СЛЕВА от hex-кода
        always_update   = false,            -- НЕ обновлять буферы, в которые сейчас не смотрим
      },
    },
  },

   -- ==========================================================================
  -- render-markdown.nvim — рендер Markdown прямо в буфере, "как в Obsidian".
  -- ==========================================================================
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.icons",
    },
    opts = {
      render_modes = { "n", "c", "t" },
      heading = {
        sign     = false,                   -- без значка в gutter
        icons    = {},                      -- БЕЗ префикс-иконки H1/H2/...
        width    = "block",                 -- плашка по ширине текста, не на всю строку
        position = "inline",                -- цвет сразу за #
        left_pad = 0,
        right_pad = 2,                      -- небольшой воздух справа от заголовка
      },
      code = {
        sign      = false,
        width     = "block",
        right_pad = 2,
        border    = "thick",
        language_name = true,               -- метка языка в правом верхнем углу (как в Obsidian)
      },
      bullet = {
        -- буллеты ТОЛЬКО для маркированных списков (- *), цифры
        -- нумерованных списков (1. 2. 3.) НЕ трогаем.
        ordered_icons = {},                 -- пусто = цифры остаются как есть
        icons = { "\u{25CF}", "\u{25CB}", "\u{25C6}", "\u{25C7}" },  -- ● ○ ◆ ◇
      },
      checkbox = {
        unchecked = { icon = "\u{F0130} " },
        checked   = { icon = "\u{F0133} " },
      },
    },
  },

    -- ==========================================================================
    -- rainbow-delimiters.nvim — разноцветные парные скобки по Treesitter.
    -- ==========================================================================
  {
    "HiPhish/rainbow-delimiters.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
  },

  -- ==========================================================================
  -- smear-cursor.nvim — плавный «смаз» курсора при прыжках.
  -- ==========================================================================
  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    main = "smear_cursor",
    opts = {
      stiffness                        = 0.38,
      trailing_stiffness               = 0.36,
      hide_target_hack                 = false,
      legacy_computing_symbols_support = true,
      filetypes_disabled               = { "snacks_dashboard" },
      cursor_color                     = "none",
    },
  },

  -- ==========================================================================
  -- mini.animate — плавная анимация открытия/закрытия/ресайза окон.
  -- Курсор и скролл отключены: курсор анимирует smear-cursor,
  -- скролл — snacks.scroll.
  -- ==========================================================================
  {
    "echasnovski/mini.animate",
    event = "VeryLazy",
    opts = function()
      local animate = require("mini.animate")
      return {
        cursor = { enable = false },
        scroll = { enable = false },
        resize = {
          enable  = true,
          timing  = animate.gen_timing.linear({ duration = 150, unit = "total" }),
        },
        open = {
          enable  = true,
          timing  = animate.gen_timing.linear({ duration = 150, unit = "total" }),
        },
        close = {
          enable  = true,
          timing  = animate.gen_timing.linear({ duration = 150, unit = "total" }),
        },
      }
    end,
  },

  -- ==========================================================================
  -- local-highlight.nvim — подсветка вхождений слова под курсором в пределах
  -- текущей области видимости (функции/блока), а не всего файла.
  -- ==========================================================================
  {
    "tzachar/local-highlight.nvim",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      file_types = { "go", "lua", "yaml", "json", "dockerfile", "sql", "python" },
      hlgroup = "LocalHighlight",
      insert_mode = false,
      min_match_len = 2,         -- не подсвечивать одиночные буквы (`i`, `_`)
    },
  },
}