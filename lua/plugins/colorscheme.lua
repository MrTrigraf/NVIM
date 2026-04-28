-- ============================================================================
-- lua/plugins/colorscheme.lua
-- Цветовая схема. kanagawa — японская тема, спокойные приглушённые цвета,
-- хорошо читается на тёмном терминале, отлично подходит для Go.
-- Та же схема, что у тебя в kitty — редактор и терминал визуально сливаются.
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

      -- Принудительно делаем gutter (колонку с номерами строк и значками)
      -- прозрачным.
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },

      -- Прозрачность только для UI-зон редактора, НЕ для floating окон.
      -- Floating окна (Lazy, hover, code actions, completion) должны иметь
      -- непрозрачный фон, иначе текст в них нечитаем.
      overrides = function(_)
        return {
          NormalNC     = { bg = "none" },
          SignColumn   = { bg = "none" },
          LineNr       = { bg = "none" },
          CursorLineNr = { bg = "none" },
          StatusLine   = { bg = "none" },
          StatusLineNC = { bg = "none" },
          EndOfBuffer  = { bg = "none" },
        }
      end,
    },

    config = function(_, opts)
      require("kanagawa").setup(opts)
      vim.cmd.colorscheme("kanagawa")
    end,
  },
}