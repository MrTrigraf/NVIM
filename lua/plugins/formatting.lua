-- lua/plugins/formatting.lua
-- conform.nvim: форматирование кода.
-- Для Go: goimports (импорты) -> gofumpt (оформление тела).
-- Format-on-save включён. lsp_format = "never": форматируем ТОЛЬКО
-- бинарями conform, не трогаем gopls-форматирование (иначе двойной
-- проход на каждое сохранение).

return {
  "stevearc/conform.nvim",
  -- BufWritePre — чтобы плагин точно был загружен к моменту первого
  -- сохранения. cmd/keys — чтобы можно было дёрнуть руками до сейва.
  event = { "BufWritePre" },
  cmd   = { "ConformInfo", "FormatToggle" },
  keys = {
    {
      "<leader>cf",
      function()
        require("conform").format({ async = true, lsp_format = "never" })
      end,
      mode = { "n", "v" },
      desc = "Code: format buffer/selection",
    },
  },

  ---@module "conform"
  ---@type conform.setupOpts
  opts = {
    -- ──────────────────────────────────────────────────────────────
    -- Какой форматтер для какого языка.
    -- ──────────────────────────────────────────────────────────────
    -- Список = цепочка: форматтеры применяются ПО ПОРЯДКУ, один за
    -- другим. Для Go: сначала goimports (чинит блок import), потом
    -- gofumpt (строже gofmt по оформлению тела кода).
    -- Пока настраиваем только Go — остальные языки (lua/yaml/json)
    -- добавим в Блоке 14, когда поставим stylua/prettier.
    formatters_by_ft = {
      go = { "goimports", "gofumpt" },
    },

    -- ──────────────────────────────────────────────────────────────
    -- Дефолтные опции форматирования.
    -- ──────────────────────────────────────────────────────────────
    -- lsp_format = "never": conform НЕ вызывает форматирование через
    -- LSP (gopls). Всё делают бинари из formatters_by_ft. Причина:
    -- gopls у нас настроен с gofumpt = true, и без этой опции на
    -- каждое сохранение шёл бы двойной проход — сначала gopls, потом
    -- conform. gopls остаётся для диагностики/hover/code actions,
    -- но НЕ для форматирования на :w.
    default_format_opts = {
      lsp_format = "never",
    },

    -- ──────────────────────────────────────────────────────────────
    -- Format-on-save.
    -- ──────────────────────────────────────────────────────────────
    -- Функция, а не таблица — чтобы можно было динамически отключать
    -- формат через глобальный флаг (см. команду FormatToggle ниже).
    -- timeout_ms = 1000: если форматтер не уложился — conform тихо
    -- пропускает сохранение без форматирования, файл всё равно
    -- сохранится.
    format_on_save = function(bufnr)
      -- Глобальный или буфер-локальный выключатель.
      if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
        return
      end
      return {
        timeout_ms = 1000,
        lsp_format = "never",
      }
    end,
  },

  config = function(_, opts)
    require("conform").setup(opts)

    -- ──────────────────────────────────────────────────────────────
    -- :FormatToggle — включить/выключить format-on-save.
    -- ──────────────────────────────────────────────────────────────
    -- :FormatToggle       — глобально (для всех буферов).
    -- :FormatToggle!      — только для текущего буфера.
    -- Полезно, когда открыл большой чужой файл и не хочешь, чтобы
    -- его переформатировало на сохранении.
    vim.api.nvim_create_user_command("FormatToggle", function(args)
      if args.bang then
        -- bang (!) — только текущий буфер.
        vim.b.disable_autoformat = not vim.b.disable_autoformat
        local state = vim.b.disable_autoformat and "ВЫКЛ" or "ВКЛ"
        vim.notify("Format-on-save для буфера: " .. state, vim.log.levels.INFO)
      else
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        local state = vim.g.disable_autoformat and "ВЫКЛ" or "ВКЛ"
        vim.notify("Format-on-save глобально: " .. state, vim.log.levels.INFO)
      end
    end, {
      desc = "Toggle format-on-save (! = только текущий буфер)",
      bang = true,
    })
  end,
}