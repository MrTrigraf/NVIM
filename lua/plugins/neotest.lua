-- ~/.config/nvim/lua/plugins/neotest.lua
-- Запуск Go-тестов прямо из Neovim: тест под курсором, файл, проект,
-- запуск в режиме отладки через nvim-dap.

return {
  "nvim-neotest/neotest",
  dependencies = {
    -- библиотеки-основа, на которых держится neotest
    "nvim-lua/plenary.nvim",      -- утилиты (уже стоит как зависимость telescope)
    "nvim-neotest/nvim-nio",      -- асинхронный I/O (уже стоит как зависимость dap-ui)
    "antoinemadec/FixCursorHold.nvim", -- стабилизирует событие CursorHold для neotest
    -- адаптер под Go: учит neotest запускать `go test`
    "fredrikaverpil/neotest-golang",
  },

  -- ленивая загрузка: файл подтянется при первом нажатии <leader>t*
  -- (key = клавиша-триггер, desc = подпись для which-key)
  keys = {
    {
      "<leader>tt",
      function() require("neotest").run.run() end,
      desc = "Тест под курсором",
    },
    {
      "<leader>tf",
      function() require("neotest").run.run(vim.fn.expand("%")) end,
      desc = "Тесты текущего файла",
    },
    {
      "<leader>ta",
      function() require("neotest").run.run(vim.fn.getcwd()) end,
      desc = "Все тесты проекта",
    },
    {
      "<leader>td",
      function() require("neotest").run.run({ strategy = "dap" }) end,
      desc = "Тест под курсором в debug-режиме",
    },
    {
      "<leader>tl",
      function() require("neotest").run.run_last() end,
      desc = "Перезапустить последний тест",
    },
    {
      "<leader>ts",
      function() require("neotest").run.stop() end,
      desc = "Остановить тест",
    },
    {
      "<leader>to",
      function() require("neotest").output.open({ enter = true }) end,
      desc = "Вывод теста (output)",
    },
    {
      "<leader>tp",
      function() require("neotest").summary.toggle() end,
      desc = "Панель со списком тестов (summary)",
    },
    {
      "<leader>tw",
      function() require("neotest").watch.toggle(vim.fn.expand("%")) end,
      desc = "Watch-режим для файла",
    },
  },

  config = function()
    local neotest = require("neotest")

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "neotest-summary", "neotest-output", "neotest-output-panel" },
      callback = function()
        vim.opt_local.foldcolumn = "0"
        vim.opt_local.signcolumn = "yes:1"
        vim.opt_local.statuscolumn = ""
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
      end,
    })

    -- иконки статуса тестов в gutter (sign-колонке).
    -- глифы Nerd Font задаются через \u{} — иначе режутся при копировании.
    local icons = {
      passed = "\u{f00c}",   -- nf-fa-check — галочка
      failed = "\u{ea87}",   -- nf-cod-error — крестик в кружке
      running = "\u{f252}",  -- nf-fa-hourglass — песочные часы «идёт/ожидание»
      skipped = "\u{f04e2}", -- nf-md-debug_step_over — пропущен
      unknown = "\u{f128}",  -- nf-fa-question — статус не определён
      non_collapsible = "\u{2500}", -- горизонтальная линия (узел без детей)
      collapsed = "\u{f0140}",      -- nf-md-chevron_down — узел свёрнут
      expanded = "\u{f0143}",       -- nf-md-chevron_up — узел развёрнут
      child_indent = "\u{2502}",    -- вертикальная линия отступа дерева
      final_child_indent = " ",
      child_prefix = "\u{251c}",    -- ветка дерева
      final_child_prefix = "\u{2514}", -- последняя ветка дерева
      watching = "\u{f06e}",        -- nf-fa-eye — файл под watch
    }

    -- цвета: линкуем highlight-группы neotest на группы темы.
    local hl_links = {
      NeotestPassed = "DiagnosticOk",
      NeotestFailed = "DiagnosticError",
      NeotestRunning = "DiagnosticWarn",
      NeotestSkipped = "DiagnosticHint",
      NeotestUnknown = "DiagnosticInfo",
      NeotestTest = "Normal",
      NeotestNamespace = "Type",       -- имена пакетов/файлов в дереве
      NeotestFile = "Directory",       -- строки-файлы в дереве
      NeotestDir = "Directory",        -- строки-папки в дереве
      NeotestFocused = "CursorLine",   -- подсветка выбранной строки
      NeotestIndent = "Comment",       -- линии отступа дерева
      NeotestExpandMarker = "Comment", -- стрелки-шевроны свернуть/развернуть
      NeotestAdapterName = "Title",    -- заголовок "neotest-golang" сверху панели
      NeotestWinSelect = "Directory",
      NeotestMarked = "DiagnosticWarn",
      NeotestTarget = "DiagnosticWarn",
      NeotestWatching = "DiagnosticWarn",
    }
    for group, target in pairs(hl_links) do
      vim.api.nvim_set_hl(0, group, { link = target })
    end

    neotest.setup({
      adapters = {
        -- подключаем Go-адаптер. opts по умолчанию хватает:
        -- runner = "go" (обычный `go test`), путь к dlv берётся из nvim-dap-go.
        require("neotest-golang")({
          -- запускать тесты в debug-режиме через уже настроенный nvim-dap
          dap_go_enabled = true,
        }),
      },

      -- значки рядом со строками тестов
      icons = icons,

      -- как neotest рисует статус на самой строке теста
      status = {
        virtual_text = false, -- без текста справа от строки, только значок в gutter
        signs = true,
      },

      -- панель summary (дерево тестов сбоку)
      summary = {
        -- открыть справа, ширина 38 колонок (было 50 — уменьшено на ~1/4)
        open = "botright vsplit | vertical resize 38",
        animated = true,
        -- клавиши ВНУТРИ панели summary
        mappings = {
          expand = { "<CR>", "<2-LeftMouse>" }, -- развернуть/свернуть узел
          jumpto = "i",     -- прыгнуть к коду теста
          run = "r",        -- запустить выбранный тест
          debug = "d",      -- запустить выбранный в debug-режиме
          stop = "u",       -- остановить
          output = "o",     -- открыть вывод
          short = "O",      -- краткий вывод во всплывающем окне
        },
      },

      -- окно с выводом упавшего теста
      output = {
        open_on_run = false, -- не открывать автоматически — открываем сами по <leader>to
      },

      -- floating-окно для короткого вывода
      floating = {
        border = "rounded",
        max_height = 0.8,
        max_width = 0.8,
      },
    })
  end,
}