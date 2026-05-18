-- ~/.config/nvim/lua/plugins/session.lua
-- persistence.nvim — автоматическое сохранение и восстановление сессий.
-- Сессия — это снимок состояния редактора (открытые файлы, разбивка
-- окон, позиция курсора), привязанный к рабочей директории проекта.

return {
  "folke/persistence.nvim",
  -- Грузим плагин при первом открытии файла. До этого момента
  -- сохранять нечего. На стартовом экране (dashboard) плагин
  -- подтянется сам, когда кнопка Restore Session вызовет require().
  event = "BufReadPre",
  init = function()
    -- sessionoptions определяет, ЧТО именно попадает в сессию:
    -- буферы, текущая директория, свёртки кода, глобальные
    -- переменные, файлы справки, вкладки, размер и позиция окон,
    -- терминалы, локальные опции окон.
    vim.o.sessionoptions =
      "buffers,curdir,folds,globals,help,tabpages,winsize,winpos,terminal,localoptions"
  end,
  -- Пустые opts = поведение по умолчанию. Файлы сессий хранятся в
  -- stdpath("state")/sessions/ — вне репозитория, в git не попадут.
  opts = {},
  keys = {
    {
      "<leader>qs",
      function() require("persistence").load() end,
      desc = "Сессия: восстановить для этого проекта",
    },
    {
      "<leader>qS",
      function() require("persistence").select() end,
      desc = "Сессия: выбрать из списка",
    },
    {
      "<leader>ql",
      function() require("persistence").load({ last = true }) end,
      desc = "Сессия: восстановить последнюю",
    },
    {
      "<leader>qd",
      function() require("persistence").stop() end,
      desc = "Сессия: не сохранять текущую при выходе",
    },
  },
}