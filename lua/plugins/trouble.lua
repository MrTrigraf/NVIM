-- lua/plugins/trouble.lua
-- Trouble: панель со списком диагностик, references, symbols, quickfix.
-- VS Code-аналог: "Problems" panel (Ctrl+Shift+M).
--
-- Группа биндингов <leader>x* — eXamine:
--   xx — workspace diagnostics (все ошибки проекта)
--   xd — document diagnostics  (только текущий файл)
--   xq — quickfix list (что положил туда :grep, :make и т.п.)
--   xl — location list (per-window quickfix)
--   xt — todo-comments (через TodoTrouble из todo-comments.nvim)
--
-- Внутри окна trouble:
--   <Enter> — открыть в редакторе (под cursor)
--   q       — закрыть панель
--   ?       — помощь по биндингам

return {
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = {
      -- Использовать новые иконки из mini.icons (у нас они стоят).
      use_diagnostic_signs = true,

      -- Маленький UX: фокус сразу переходит в trouble-окно при открытии.
      focus = true,

      -- При первом открытии — раскрытое дерево всех ошибок.
      open_no_results = false,

      -- Закрыть окно автоматически, если список опустел.
      auto_close = false,

      -- Не открывать предпросмотр поверх кода — мы кликаем <Enter>,
      -- когда сами хотим.
      auto_preview = false,
    },
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "Trouble: workspace diagnostics",
      },
      {
        "<leader>xd",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Trouble: document diagnostics",
      },
      {
        "<leader>xq",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "Trouble: quickfix list",
      },
      {
        "<leader>xl",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "Trouble: location list",
      },
      {
        "<leader>xt",
        "<cmd>TodoTrouble<cr>",
        desc = "Trouble: todo-comments",
      },
    },
  },
}