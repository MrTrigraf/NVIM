-- ============================================================================
-- lua/plugins/terminal.lua
-- snacks.nvim — модуль terminal.
-- Интегрированный терминал внутри Neovim: плавающий + три именованных
-- сплита (shell / run / watch). Shell у пользователя — fish.
--
-- ВАЖНО про слияние спек: snacks.nvim уже описан в dashboard.lua со своей
-- функцией config (которая вызывает require("snacks").setup(opts)).
-- lazy.nvim сольёт opts из этого файла в общий opts, и наш terminal-блок
-- уедет в тот же setup. Поэтому здесь config НЕ указываем — только opts и keys.
--
-- РАЗМЕРЫ ОКОН (поля width / height внутри win):
--   - значение 0..1  — доля экрана (0.3 = треть, 0.5 = половина)
--   - значение > 1   — абсолютное число колонок/строк (80 = 80 колонок)
--   - горизонтальный (нижний) сплит растёт по height
--   - вертикальный (боковой) сплит растёт по width
--   - плавающему окну задаём оба размера (это не сплит)
-- ============================================================================

-- Уникальная env-метка для каждого терминала.
-- snacks различает терминалы по комбинации cmd + cwd + env. Позиция окна
-- (float / split) в "личность" терминала НЕ входит. Поэтому без своей метки
-- два fish в разных позициях считались бы одним терминалом. Метка и разводит
-- их по разным "личностям", и сам fish при желании может её прочитать
-- ($NVIM_TERM) — например, чтобы поменять приглашение.
local function term_env(name)
  return { NVIM_TERM = name }
end

return {
  {
    "folke/snacks.nvim",
    -- priority и lazy=false уже заданы в dashboard.lua — здесь не дублируем.

    opts = {
      terminal = {
        -- Поведение окна терминала.
        win = {
          -- Двойной <Esc> в terminal-режиме -> normal-режим. У snacks это
          -- встроено по умолчанию (term_normal), задаём явно для наглядности.
          keys = {
            term_normal = {
              "<esc>",
              function(self)
                self.esc_timer = self.esc_timer or (vim.uv or vim.loop).new_timer()
                if self.esc_timer:is_active() then
                  self.esc_timer:stop()
                  vim.cmd("stopinsert")
                else
                  self.esc_timer:start(200, 0, function() end)
                  return "<esc>"
                end
              end,
              mode = "t",
              expr = true,
              desc = "Двойной <Esc> -> normal-режим",
            },
          },
        },

        -- start_insert  — войти в insert (terminal-режим) при создании.
        -- auto_insert   — снова войти в terminal-режим при возврате фокуса.
        -- auto_close    — закрыть окно, когда процесс в нём завершился.
        start_insert = true,
        auto_insert = true,
        auto_close = true,
      },
    },

    keys = {
      -- ----------------------------------------------------------------
      -- term-shell — горизонтальный сплит снизу.
      -- Основной рабочий терминал: go get / go build / go test руками / git.
      -- Повешен на <C-/> — самую быструю клавишу, работает в n/t/i
      -- (в т.ч. прямо из режима печати кода).
      -- Toggle: первая <C-/> открывает, вторая — прячет (процесс жив).
      -- ----------------------------------------------------------------
      {
        "<C-/>",
        function()
          Snacks.terminal.toggle("fish", {
            env = term_env("shell"),
            win = {
              position = "bottom",
              height = 0.3, -- треть высоты экрана снизу
            },
          })
        end,
        mode = { "n", "t", "i" },
        desc = "Терминал: term-shell (низ, команды)",
      },
      -- Дубликат на <C-_>: некоторые терминалы (в т.ч. часть конфигураций
      -- kitty) присылают <C-/> как код <C-_>. Вешаем оба, чтобы биндинг
      -- работал независимо от того, что именно прислал терминал.
      {
        "<C-_>",
        function()
          Snacks.terminal.toggle("fish", {
            env = term_env("shell"),
            win = {
              position = "bottom",
              height = 0.3,
            },
          })
        end,
        mode = { "n", "t", "i" },
        desc = "Терминал: term-shell (низ, алиас <C-/>)",
      },

      -- ----------------------------------------------------------------
      -- Именованные терминалы. Префикс <leader>T (Вариант 1):
      -- тесты позже займут <leader>t, терминал — <leader>T.
      -- ----------------------------------------------------------------

      -- term-float — плавающее окно поверх кода.
      -- Для коротких разовых команд: "вызвал — посмотрел — закрыл".
      -- Позже тем же механизмом поедут lazygit/lazydocker (Блоки 9-10),
      -- но это будут отдельные окна со своими клавишами.
      {
        "<leader>Tf",
        function()
          Snacks.terminal.toggle("fish", {
            env = term_env("float"),
            win = {
              position = "float",
              -- border — рамка вокруг плавающего окна. "rounded" = скруглённые
              -- углы. Без неё окно сливается с кодом под ним.
              border = "rounded",
              -- title — подпись в верхней рамке, чтобы было видно, что это
              -- за окно. title_pos — где её разместить.
              title = " term-float ",
              title_pos = "center",
              -- плавающему задаём оба размера: доля ширины и доля высоты экрана
              width = 0.85,
              height = 0.8,
            },
          })
        end,
        mode = { "n", "t" },
        desc = "Терминал: плавающий (toggle)",
      },

      -- term-run — горизонтальный сплит снизу.
      -- Окно запущенного сервера: go run . Отдельная сессия, чтобы логи
      -- сервера не смешивались с командами из term-shell.
      {
        "<leader>Tr",
        function()
          Snacks.terminal.toggle("fish", {
            env = term_env("run"),
            win = {
              position = "bottom",
              height = 0.3, -- треть высоты экрана снизу
            },
          })
        end,
        mode = { "n", "t" },
        desc = "Терминал: term-run (низ, go run сервера)",
      },

      -- term-watch — вертикальный сплит сбоку.
      -- Заведён под air (hot-reload). Пока без air — это просто fish
      -- в боковом сплите; запуск air повешен отдельно на <leader>Ta.
      {
        "<leader>Tw",
        function()
          Snacks.terminal.toggle("fish", {
            env = term_env("watch"),
            win = {
              position = "right",
              width = 0.28, -- треть ширины экрана справа (было 0.5 по дефолту)
            },
          })
        end,
        mode = { "n", "t" },
        desc = "Терминал: term-watch (бок, air/watch)",
      },

      -- term-watch + автозапуск air (hot-reload).
      -- Открывает ТОТ ЖЕ терминал term-watch (та же env-метка "watch" и
      -- та же геометрия, что у <leader>Tw — поэтому это одно окно, а не
      -- новое), затем отправляет в его fish строку "air" + Enter, как
      -- будто пользователь сам её напечатал. air запускается ВНУТРИ fish:
      -- когда air остановится (<C-c>) или упадёт, окно не закроется —
      -- останется живой fish с логами, можно перезапустить.
      {
        "<leader>Ta",
        function()
          local term = Snacks.terminal.toggle("fish", {
            env = term_env("watch"),
            win = {
              position = "right",
              width = 0.30,
            },
          })
          -- toggle мог как открыть окно, так и спрятать его. Запускаем air
          -- только если окно сейчас видимо (term не nil и буфер показан).
          if term and term.buf and vim.api.nvim_buf_is_valid(term.buf) then
            local channel = vim.b[term.buf].terminal_job_id
            if channel then
              vim.api.nvim_chan_send(channel, "air\n")
            end
          end
        end,
        mode = { "n", "t" },
        desc = "Терминал: term-watch + запуск air",
      },
    },
  },
}