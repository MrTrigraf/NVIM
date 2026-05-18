-- ============================================================================
-- lua/plugins/bufferline.lua
-- Плагин bufferline.nvim ОТКЛЮЧЁН.
-- Список буферов отображается через компонент "buffers" в lualine (см. ui.lua),
-- с фильтром по текущей рабочей директории — показываются только буферы
-- открытого проекта. Этот файл хранит keys-маппинги через нативные Vim-команды
-- и Snacks.bufdelete, чтобы привычные <leader>b* и ]b/[b продолжали работать.
-- ============================================================================

return {
  -- Сам плагин bufferline отключён, но запись оставлена на случай возврата.
  {
    "akinsho/bufferline.nvim",
    enabled = false,
  },

  -- Виртуальная "пустышка" (no-op spec), чтобы держать <leader>b* биндинги
  -- независимо от bufferline. lazy.nvim требует чтобы плагин-плейсхолдер
  -- ссылался на реальный репо, поэтому пользуемся plenary (он у нас уже
  -- стоит как зависимость многих других плагинов — никакой нагрузки сверху).
  {
    "nvim-lua/plenary.nvim",
    keys = {
      -- ── Переключение между буферами ──────────────────────────────────
      { "]b", "<cmd>bnext<cr>",     desc = "Next buffer" },
      { "[b", "<cmd>bprevious<cr>", desc = "Prev buffer" },

      -- ── Закрытие буферов ─────────────────────────────────────────────
      -- Snacks.bufdelete умнее чем :bd — при закрытии последнего буфера
      -- НЕ закрывает окно (как делает :bd). Открывается scratch-буфер.
      {
        "<leader>bd",
        function() require("snacks").bufdelete() end,
        desc = "Delete buffer",
      },
      {
        "<leader>bo",
        function() require("snacks").bufdelete.other() end,
        desc = "Delete other buffers",
      },

      -- ── Перейти к alternate-буферу (тот, в котором был перед текущим)
      -- Стандартная Vim-команда, аналог Ctrl+Tab в VS Code.
      { "<leader>bb", "<cmd>buffer #<cr>", desc = "Switch to other buffer" },
    },
  },
}