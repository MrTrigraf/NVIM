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
      desc = "Debug: toggle breakpoint",
    },
    {
      "<leader>dc",
      function() require("dap").continue() end,
      desc = "Debug: start / continue",
    },
    {
      "<leader>do",
      function() require("dap").step_over() end,
      desc = "Debug: step over",
    },
    {
      "<leader>di",
      function() require("dap").step_into() end,
      desc = "Debug: step into",
    },
    {
      "<leader>dO",
      function() require("dap").step_out() end,
      desc = "Debug: step out",
    },
    {
      "<leader>dt",
      function() require("dap").terminate() end,
      desc = "Debug: terminate session",
    },
    {
      "<leader>dr",
      function() require("dap").repl.toggle() end,
      desc = "Debug: toggle REPL",
    },
    {
      "<leader>du",
      function() require("dapui").toggle() end,
      desc = "Debug: toggle UI panels",
    },
    {
      "<leader>de",
      function() require("dapui").eval() end,
      mode = { "n", "v" },
      desc = "Debug: eval value under cursor",
    },
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    -- ── Размеры панелей dap-ui ───────────────────────────────────────
    -- Одно место правды: эти значения используются и в dapui.setup
    -- (начальная раскладка), и в функции восстановления размеров
    -- после ресайза терминала. Меняешь тут — меняется везде.
    local DAPUI_RIGHT_WIDTH = 40   -- ширина правой колонки, знаков
    local DAPUI_BOTTOM_HEIGHT = 10 -- высота нижней полки, строк

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
          -- Правая колонка.
          position = "right",
          size = DAPUI_RIGHT_WIDTH,
          elements = {
            { id = "scopes", size = 0.45 },      -- все переменные точки
            { id = "breakpoints", size = 0.20 }, -- список точек останова
            { id = "stacks", size = 0.35 },      -- стек вызовов
          },
        },
        {
          -- Нижняя полка.
          position = "bottom",
          size = DAPUI_BOTTOM_HEIGHT,
          elements = {
            { id = "repl", size = 0.6 },    -- интерактивный ввод
            { id = "watches", size = 0.4 }, -- свои выражения слежения
          },
        },
      },
    })

    -- ── Классификация окон dap-ui по расположению ────────────────────
    -- Нужна, чтобы понимать: окну вернуть ШИРИНУ (правая колонка) или
    -- ВЫСОТУ (нижняя полка). Ключи — это filetype соответствующих
    -- буферов dap-ui.
    local dapui_right = {
      dapui_scopes = true,
      dapui_breakpoints = true,
      dapui_stacks = true,
    }
    local dapui_bottom = {
      dapui_watches = true,
      dapui_console = true,
      ["dap-repl"] = true,
    }

    -- ── Приведение окон dap-ui в порядок ─────────────────────────────
    -- Делает три вещи для каждого окна dap-ui:
    --   1. гасит лишние колонки — nvim-ufo включает foldcolumn
    --      глобально, а statuscol вешает свою statuscolumn на все окна;
    --      в панелях dap-ui это даёт лишние маркеры поверх родных;
    --   2. возвращает панели её заданный размер (40 знаков / 10 строк);
    --   3. ставит winfixwidth/winfixheight — это опция окна "держать
    --      размер фиксированным": Neovim перестаёт масштабировать такое
    --      окно при ресайзе терминала, изменения поглощают соседи.
    -- Объявлена ДО слушателей и автокоманды, которые её вызывают
    -- (Lua читает файл сверху вниз).
    local function setup_dapui_windows()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
          local buf = vim.api.nvim_win_get_buf(win)
          local ft = vim.api.nvim_get_option_value("filetype", { buf = buf })
          local is_right = dapui_right[ft]
          local is_bottom = dapui_bottom[ft]
          if is_right or is_bottom then
            -- общая чистка лишних колонок
            vim.api.nvim_set_option_value("foldcolumn", "0", { win = win })
            vim.api.nvim_set_option_value("statuscolumn", "", { win = win })
          end
          if is_right then
            -- pcall — раскладка может на миг не позволять ресайз
            pcall(vim.api.nvim_win_set_width, win, DAPUI_RIGHT_WIDTH)
            vim.wo[win].winfixwidth = true
          elseif is_bottom then
            pcall(vim.api.nvim_win_set_height, win, DAPUI_BOTTOM_HEIGHT)
            vim.wo[win].winfixheight = true
          end
        end
      end
    end

    -- ── Авто-открытие/закрытие панелей по событиям сессии ────────────
    -- Панели всплывают при старте отладки и прячутся при выходе.
    -- После открытия приводим окна dap-ui в порядок с отложкой через
    -- vim.schedule — уже после того, как dap-ui настроил окна.
    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
      vim.schedule(setup_dapui_windows)
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
      vim.schedule(setup_dapui_windows)
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    -- ── Восстановление раскладки dap-ui после ресайза терминала ──────
    -- При изменении размера kitty Neovim масштабирует все окна
    -- пропорционально — и панели dap-ui "уезжают": после цикла
    -- сжать/разжать боковая панель раздувается на пол-экрана.
    -- Глобальная автокоманда VimResized в autocmds.lua во время
    -- отладки специально НЕ трогает окна (чтобы не ломать dap-ui).
    -- Здесь — точечно: пока идёт сессия, возвращаем панелям dap-ui
    -- их заданный размер. winfix* (см. setup_dapui_windows) держит
    -- размер сам, а это — гарантированная страховка-коррекция.
    vim.api.nvim_create_autocmd("VimResized", {
      group = vim.api.nvim_create_augroup("dap_ui_resize", { clear = true }),
      desc = "Restore dap-ui panel sizes on terminal resize",
      callback = function()
        if not dap.session() then
          return
        end
        -- schedule — выполнить уже после того, как Neovim сам
        -- обработал ресайз и пересчитал окна.
        vim.schedule(setup_dapui_windows)
      end,
    })
  end,
}
