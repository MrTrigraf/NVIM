-- ============================================================================
-- lua/plugins/colorscheme.lua
-- Цветовая схема. kanagawa — японская тема, спокойные приглушённые цвета,
-- хорошо читается на тёмном терминале, отлично подходит для Go.
-- Та же схема, что у тебя в kitty — редактор и терминал визуально сливаются.
-- ============================================================================

return {
  {
    "rebelot/kanagawa.nvim",

    -- priority = 1000 заставляет colorscheme загрузиться РАНЬШЕ всех остальных
    -- плагинов. Иначе lualine и прочие могут успеть посчитать цвета по
    -- дефолтной теме и закэшировать их.
    priority = 1000,

    -- lazy = false — colorscheme не ленивая, нужна сразу при старте.
    lazy = false,

    opts = {
      compile = false,
      undercurl = true,
      commentStyle = { italic = true },
      functionStyle = {},
      keywordStyle = { italic = false },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = true,            -- прозрачный основной фон
      dimInactive = false,           -- не затемнять неактивные сплиты
      terminalColors = true,
      theme = "wave",
      background = {
        dark = "wave",
        light = "lotus",
      },

      -- Принудительно делаем gutter (колонку с номерами строк и значками)
      -- прозрачным. Без этого kanagawa оставляет ему свой тёмный фон даже
      -- при transparent=true.
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },

      -- Очищаем фон у остальных UI-групп, которые kanagawa не трогает
      -- при transparent=true: statusline, плавающие окна, sign column,
      -- номера строк, конец буфера.
      overrides = function(_)
        return {
          NormalFloat  = { bg = "none" },
          FloatBorder  = { bg = "none" },
          FloatTitle   = { bg = "none" },
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