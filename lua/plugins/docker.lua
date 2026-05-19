-- lazydocker через Snacks.terminal — TUI для управления Docker
-- (контейнеры, образы, тома, сети, логи, статистика) прямо из Neovim.
--
-- TUI = text user interface, полноэкранный интерфейс в терминале
-- (управление стрелками/клавишами, без мыши). В VS Code ближайший
-- аналог — расширение Docker с панелью контейнеров в сайдбаре.
--
-- Раскладка:
--   <leader>D — открыть/показать lazygit-… то есть lazydocker
--               (плавающее окно через snacks.terminal).
--
-- Внутри lazydocker:
--   <C-q> — скрыть окно (процесс lazydocker продолжает жить).
--           Снова показать: <leader>D. Перехватывается Neovim'ом
--           ДО lazydocker, так что сам lazydocker этой клавиши не видит.
--   q     — закрыть lazydocker полностью (нативная клавиша lazydocker).

return {
  {
    "folke/snacks.nvim",
    keys = {
      {
        "<leader>D",
        function()
          require("snacks").terminal("lazydocker", {
            -- стартуем в текущем cwd Neovim; для lazydocker рабочая
            -- директория почти не важна (он показывает весь демон),
            -- но держим единообразие со спекой lazygit.
            cwd = vim.fn.getcwd(),
            -- env-метка: snacks различает терминалы по cmd+cwd+env.
            -- Своя метка гарантирует, что окно lazydocker — отдельное
            -- от окна lazygit, а не переиспользует его буфер.
            env = { NVIM_TERM = "lazydocker" },
            win = {
              position = "float",
              width = 0.9,
              height = 0.9,
              border = "rounded",
              title = " lazydocker ",
              title_pos = "center",
              keys = {
                -- Esc внутри lazydocker — нативная "back/cancel".
                -- Глобальный term_normal (<Esc><Esc> → normal-mode из
                -- Блока 8) тут мешал бы — отключаем для этого окна.
                term_normal = false,

                -- <C-q> — скрыть окно lazydocker, НЕ убивая процесс.
                -- Маппинг buffer-local на уровне Neovim, перехватывается
                -- ДО того как клавиша уйдёт в lazydocker. Снова показать —
                -- <leader>D, состояние сессии сохраняется.
                hide_window = {
                  "<c-q>",
                  function(self) self:hide() end,
                  mode = { "n", "t" },
                  desc = "Docker: hide lazydocker (reopen: <leader>D)",
                },
              },
            },
          })
        end,
        desc = "Docker: lazydocker",
      },
    },
  },
}