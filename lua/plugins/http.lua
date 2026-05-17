-- lua/plugins/http.lua
-- HTTP-клиент kulala.nvim: выполнение HTTP-запросов из .http файлов
-- прямо внутри Neovim. Аналог JetBrains HTTP Client.
-- Запрос пишется обычным текстом, ответ показывается в окне-сплите.

return {
  {
    "mistweaverco/kulala.nvim",
    -- Ленивая загрузка: плагин подгружается только при открытии
    -- файла типа http или rest, а не на старте Neovim.
    ft = { "http", "rest" },

    -- init выполняется на старте Neovim, ещё ДО загрузки самого плагина.
    -- Регистрируем расширения .http и .rest как filetype "http".
    -- Без этого Neovim не знает такой тип файла, и ленивая загрузка
    -- по ft никогда не сработает (нечему триггерить).
    init = function()
      vim.filetype.add({
        extension = {
          http = "http",
          rest = "http",
        },
      })
    end,

    opts = {
      -- Глобальные кейбинды kulala выключены: свою раскладку <leader>r*
      -- вешаем сами как buffer-local (см. config ниже) — так клавиши
      -- работают только в .http файлах и не мешают в Go/Lua.
      global_keymaps = false,
      ui = {
        -- Ответ показывается в отдельном окне-сплите (не плавающем).
        display_mode = "split",
        -- Сплит вертикальный: окно ответа открывается справа от запроса.
        split_direction = "vertical",
        -- По умолчанию в окне ответа показываем тело (body), не заголовки.
        default_view = "body",
      },
    },

    config = function(_, opts)
      require("kulala").setup(opts)

      -- Buffer-local раскладка <leader>r* для .http файлов.
      -- Функция навешивает клавиши на конкретный буфер по его номеру.
      local function set_http_keymaps(bufnr)
        local kulala = require("kulala")
        local map = function(lhs, fn, desc)
          vim.keymap.set("n", lhs, fn, { buffer = bufnr, desc = desc })
        end

        map("<leader>rr", function() kulala.run() end,         "HTTP: запрос под курсором")
        map("<leader>ra", function() kulala.run_all() end,     "HTTP: все запросы файла")
        map("<leader>rl", function() kulala.replay() end,      "HTTP: повторить последний запрос")
        map("<leader>ro", function() kulala.open() end,        "HTTP: открыть окно ответа")
        map("<leader>rt", function() kulala.toggle_view() end, "HTTP: тело / заголовки")
        map("<leader>rc", function() kulala.copy() end,        "HTTP: скопировать как curl")
        map("<leader>re", function() kulala.set_selected_env() end, "HTTP: выбрать окружение")
        map("<leader>rq", function() kulala.close() end,       "HTTP: закрыть окна kulala")
        map("]r",         function() kulala.jump_next() end,   "HTTP: следующий запрос")
        map("[r",         function() kulala.jump_prev() end,   "HTTP: предыдущий запрос")
      end

      -- Автокоманда: на каждый открываемый http/rest буфер вешаем клавиши.
      local group = vim.api.nvim_create_augroup("kulala_http_keymaps", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = group,
        pattern = { "http", "rest" },
        callback = function(ev) set_http_keymaps(ev.buf) end,
      })

      -- Подстраховка: навешиваем клавиши на уже открытые http-буферы.
      -- Нужно на случай, если буфер, запустивший загрузку плагина,
      -- уже прошёл событие FileType до создания автокоманды выше.
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          local ft = vim.bo[buf].filetype
          if ft == "http" or ft == "rest" then
            set_http_keymaps(buf)
          end
        end
      end
    end,
  },
}