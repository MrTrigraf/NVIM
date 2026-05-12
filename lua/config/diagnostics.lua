-- ============================================================================
-- lua/config/diagnostics.lua
-- Глобальная настройка отображения диагностик от LSP, линтеров и
-- других источников. Это часть встроенного API Neovim (vim.diagnostic),
-- а не плагин — поэтому живёт в config/, не в plugins/.
--
-- Применяется ко всем будущим LSP-серверам (gopls, yamlls и т.п.):
-- настраиваем один раз, работает везде.
--
-- ── Стратегия отображения (как в VS Code, не как в Error Lens) ──
-- В строке кода НЕ висит текст ошибки (virtual_text = false). Видна
-- только иконка слева, подчёркивание и красный номер строки. Полный
-- текст ошибки появляется во всплывающем окне:
--   - автоматически на CursorHold (через ~250 мс простоя на строке);
--   - вручную по <leader>ld.
-- Курсор сошёл со строки — окно исчезло само. Это поведение базового
-- VS Code: "ошибка как будто всплывает при наведении".
-- ============================================================================

-- ──────────────────────────────────────────────────────────────────────
-- Иконки уровней (signs в gutter — узкая колонка слева от номера строки).
-- Глифы записаны через "\u{XXXX}" (Lua escape для Unicode code-point),
-- а не как сами символы в исходнике. Так файл остаётся чистым ASCII и
-- никакая инфраструктура (мессенджеры, буфер обмена, IME) не может
-- "съесть" символ из приватной зоны Nerd Font.
--   "\u{ea87}"  = "" (Nerd Font: cod-error)
--   "\u{ea6c}"  = "" (Nerd Font: cod-warning)
--   "\u{ea74}"  = "" (Nerd Font: cod-info)
--   "\u{f0166}" = "󰅦" (Nerd Font: md-lightbulb)
-- ──────────────────────────────────────────────────────────────────────
local signs = {
  [vim.diagnostic.severity.ERROR] = "\u{ea87}",
  [vim.diagnostic.severity.WARN]  = "\u{ea6c}",
  [vim.diagnostic.severity.INFO]  = "\u{ea74}",
  [vim.diagnostic.severity.HINT]  = "\u{f0166}",
}

-- ──────────────────────────────────────────────────────────────────────
-- Основная конфигурация. vim.diagnostic.config принимает таблицу с
-- ключами по способам отображения. Любой из них можно отключить,
-- передав false вместо таблицы настроек.
-- ──────────────────────────────────────────────────────────────────────
vim.diagnostic.config({
  -- Иконка в gutter слева от строки + numhl (подкраска номера строки).
  signs = {
    text = signs,
    numhl = {
      [vim.diagnostic.severity.ERROR] = "DiagnosticSignError",
      [vim.diagnostic.severity.WARN]  = "DiagnosticSignWarn",
      [vim.diagnostic.severity.INFO]  = "DiagnosticSignInfo",
      [vim.diagnostic.severity.HINT]  = "DiagnosticSignHint",
    },
  },

  -- Подчёркивание под проблемным куском кода ("волнистая линия").
  underline = true,

  -- Виртуальный текст ВЫКЛЮЧЕН: текст ошибки в строке кода нам не
  -- нужен (короче visible code, меньше "прыжков" верстки). Полный
  -- текст — через автоматический float-popup ниже.
  virtual_text = false,

  -- Floating-окно: единый стиль для авто-popup'а на CursorHold и для
  -- ручного <leader>ld.
  --   border = "rounded"   — единый стиль рамок со всем UI.
  --   source = "if_many"   — добавлять имя источника (например "gopls")
  --                          только если на строке несколько источников.
  --   header = ""          — без заголовка "Diagnostics:".
  --   prefix = ""          — без префикса перед сообщением.
  --   focusable = false    — окно нельзя фокусировать (иначе случайный
  --                          клик мышью переключает фокус, и окно
  --                          остаётся висеть).
  --   scope = "cursor"     — показывать только диагностики ПОД курсором
  --                          (точный символ), а не все на строке.
  --                          Удобно когда на одной строке несколько
  --                          ошибок: подсвечивается именно та, что
  --                          сейчас под курсором.
  float = {
    border    = "rounded",
    source    = "if_many",
    header    = "",
    prefix    = "",
    focusable = false,
    scope     = "cursor",
  },

  -- НЕ обновлять диагностики, пока ты печатаешь в Insert-режиме.
  -- Обновятся, как только выйдешь в Normal.
  update_in_insert = false,

  -- Если на одной строке и ошибка, и warning — показать ошибку
  -- первой (она важнее).
  severity_sort = true,
})

-- ──────────────────────────────────────────────────────────────────────
-- Авто-floating на CursorHold. Срабатывает после updatetime=250 мс
-- простоя курсора на строке. Если на строке (вернее, под курсором —
-- scope="cursor" выше) есть диагностика, открывается popup. Когда
-- курсор движется дальше — popup закрывается сам (стандартное
-- поведение неинтерактивного float).
--
-- Включаем И для нормального, И для insert-режима, чтобы при ошибке
-- внутри активной правки тоже всплывало (без CursorHoldI пришлось бы
-- выходить в Normal, что неудобно).
-- ──────────────────────────────────────────────────────────────────────
local diag_hover_group = vim.api.nvim_create_augroup("user-diagnostic-hover", { clear = true })
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = diag_hover_group,
  callback = function()
    -- Не открывать popup, если уже открыт какой-то floating-window
    -- (например, наш hover от K). Иначе они будут накладываться и
    -- мешать друг другу.
    for _, winid in ipairs(vim.api.nvim_list_wins()) do
      local cfg = vim.api.nvim_win_get_config(winid)
      if cfg.relative ~= "" then
        return
      end
    end
    vim.diagnostic.open_float(nil, { focus = false })
  end,
})

-- ──────────────────────────────────────────────────────────────────────
-- Глобальные биндинги для навигации по диагностикам.
-- LSP-биндинги (K, gd, gr, <leader>la и т.п.) — НЕ здесь.
-- Они вешаются через LspAttach autocmd только когда LSP реально
-- приатачен к буферу. Диагностические биндинги — глобальные.
-- ──────────────────────────────────────────────────────────────────────
local map = vim.keymap.set

-- ]d / [d — следующая / предыдущая диагностика в текущем буфере.
-- В VS Code это F8 / Shift+F8.
map("n", "]d", function() vim.diagnostic.jump({ count =  1 }) end, { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, { desc = "Prev diagnostic" })

-- <leader>ld — открыть floating-окно с полным текстом диагностики
-- под курсором. Дублирует CursorHold-popup, но мгновенно (без
-- ожидания updatetime).
map("n", "<leader>ld", function() vim.diagnostic.open_float() end, { desc = "Line diagnostic (float)" })