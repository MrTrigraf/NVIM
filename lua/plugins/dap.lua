-- lua/plugins/dap.lua
-- Отладка Go-кода: движок DAP + мост к delve + графические панели.
-- Завязан на установленный в системе `dlv` (delve).

return {
  "mfussenegger/nvim-dap",
  -- Грузим лениво: плагины подтянутся при первом нажатии debug-клавиши.
  dependencies = {
    "rcarriga/nvim-dap-ui",  -- графические панели: переменные, стек, watch, REPL
    "nvim-neotest/nvim-nio", -- асинхронная библиотека, нужна dap-ui
    "leoluz/nvim-dap-go",    -- мост nvim-dap <-> delve, конфигурация под Go
  },
  keys = {
    {
      "<leader>db",
      function() require("dap").toggle_breakpoint() end,
      desc = "Debug: точка останова вкл/выкл",
    },
    {
      "<leader>dc",
      function() require("dap").continue() end,
      desc = "Debug: старт / продолжить",
    },
    {
      "<leader>do",
      function() require("dap").step_over() end,
      desc = "Debug: шаг через (step over)",
    },
    {
      "<leader>di",
      function() require("dap").step_into() end,
      desc = "Debug: шаг внутрь (step into)",
    },
    {
      "<leader>dO",
      function() require("dap").step_out() end,
      desc = "Debug: шаг наружу (step out)",
    },
    {
      "<leader>dt",
      function() require("dap").terminate() end,
      desc = "Debug: завершить сессию",
    },
    {
      "<leader>dr",
      function() require("dap").repl.toggle() end,
      desc = "Debug: REPL вкл/выкл",
    },
    {
      "<leader>du",
      function() require("dapui").toggle() end,
      desc = "Debug: панели UI вкл/выкл",
    },
    {
      "<leader>de",
      function() require("dapui").eval() end,
      mode = { "n", "v" },
      desc = "Debug: показать значение под курсором",
    },
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    -- ── Иконки в колонке знаков ──────────────────────────────────────
    -- Глифы Nerd Font задаём через \u{...}: "сырые" символы приватной
    -- зоны Unicode портятся при копировании. texthl ссылается на
    -- темо-зависимые группы диагностики — цвета подхватятся из
    -- kanagawa-paper автоматически, без хардкода hex.
    vim.fn.sign_define("DapBreakpoint", {
      text = "\u{f111}", -- сплошной кружок — обычная точка останова
      texthl = "DiagnosticSignError",
      numhl = "",
    })
    vim.fn.sign_define("DapBreakpointCondition", {
      text = "\u{f192}", -- кружок с точкой — условная точка останова
      texthl = "DiagnosticSignWarn",
      numhl = "",
    })
    vim.fn.sign_define("DapLogPoint", {
      text = "\u{f0eb}", -- лампочка — log point (печатает сообщение, не стопает)
      texthl = "DiagnosticSignInfo",
      numhl = "",
    })
    vim.fn.sign_define("DapBreakpointRejected", {
      text = "\u{f00d}", -- крестик — точка останова отклонена отладчиком
      texthl = "DiagnosticSignHint",
      numhl = "",
    })
    vim.fn.sign_define("DapStopped", {
      text = "\u{f061}",   -- стрелка вправо — текущая строка выполнения
      texthl = "DiagnosticSignWarn",
      linehl = "Visual",   -- подсветка всей строки, на которой стоим
      numhl = "DiagnosticSignWarn",
    })

    -- ── Go-адаптер ───────────────────────────────────────────────────
    -- dap-go сам находит `dlv` в PATH и регистрирует Go-конфигурации
    -- запуска (debug файла, debug ближайшего теста и т.д.).
    require("dap-go").setup()

    -- ── Графические панели + раскладка (Вариант 3) ───────────────────
    -- Правая колонка: scopes + breakpoints + stacks.
    -- Нижняя полка: repl + watches.
    -- controls (ряд кликабельных кнопок) выключены — управляем
    -- клавишами <leader>d*. Панели console нет — пустого окна не будет.
    dapui.setup({
      controls = {
        enabled = false,
      },
      layouts = {
        {
          -- Правая колонка, ширина 40 знаков.
          position = "right",
          size = 40,
          elements = {
            { id = "scopes", size = 0.45 },      -- все переменные точки
            { id = "breakpoints", size = 0.20 }, -- список точек останова
            { id = "stacks", size = 0.35 },      -- стек вызовов
          },
        },
        {
          -- Нижняя полка, высота 10 строк.
          position = "bottom",
          size = 10,
          elements = {
            { id = "repl", size = 0.6 },    -- интерактивный ввод
            { id = "watches", size = 0.4 }, -- свои выражения слежения
          },
        },
      },
    })

    -- ── Чистим колонки в служебных окнах dap-ui ──────────────────────
    -- nvim-ufo включает foldcolumn глобально, а statuscol вешает свою
    -- statuscolumn на все окна. В панелях dap-ui это даёт лишние
    -- маркеры поверх родных. Функция пробегает по ВСЕМ окнам и гасит
    -- лишние колонки в окнах dap-ui по их filetype — не завязываясь
    -- на вход курсора в окно. Объявлена ДО слушателей, которые её
    -- вызывают (Lua читает файл сверху вниз).
    local dapui_filetypes = {
      dapui_scopes = true,
      dapui_breakpoints = true,
      dapui_stacks = true,
      dapui_watches = true,
      dapui_console = true,
      ["dap-repl"] = true,
    }
    local function clean_dapui_columns()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
          if dapui_filetypes[ft] then
            vim.api.nvim_set_option_value("foldcolumn", "0", { win = win })
            vim.api.nvim_set_option_value("statuscolumn", "", { win = win })
          end
        end
      end
    end

    -- ── Авто-открытие/закрытие панелей по событиям сессии ────────────
    -- Панели всплывают при старте отладки и прячутся при выходе.
    -- После открытия чистим колонки окон dap-ui с отложкой через
    -- vim.schedule — уже после того, как dap-ui настроил окна.
    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
      vim.schedule(clean_dapui_columns)
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
      vim.schedule(clean_dapui_columns)
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end
  end,
}
