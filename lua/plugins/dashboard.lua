-- ============================================================================
-- lua/plugins/dashboard.lua
-- snacks.nvim — модули dashboard и notifier.
-- Стартовый экран при запуске nvim без файла + красивые уведомления.
-- ============================================================================

return {
  {
    "folke/snacks.nvim",
    priority = 1000,             -- грузить рано, чтобы dashboard успел показаться
    lazy = false,                -- dashboard нужен сразу при старте
    opts = {
      -- ----------------------------------------------------------------------
      -- DASHBOARD
      -- ----------------------------------------------------------------------
      dashboard = {
        enabled = true,
        preset = {
          -- ASCII-логотип. Можно заменить на любой другой,
          -- например через https://patorjk.com/software/taag/
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],

          -- Действия — список пунктов меню. Каждый: иконка + надпись + клавиша + action.
          -- Open File / Open Folder будут добавлены в Блоке 5 после telescope.
          -- Restore Session — заглушка до Блока 14, когда подключим persistence.nvim.
          keys = {
            { icon = " ", key = "n", desc = "New file", action = ":enew" },
            { icon = " ", key = "r", desc = "Recent files", action = function() Snacks.dashboard.pick("oldfiles") end },
            {
              icon = " ", key = "s", desc = "Restore session",
              action = function()
                vim.notify("persistence.nvim ещё не подключён (Блок 14)", vim.log.levels.WARN)
              end,
            },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },

        -- Секции дашборда — сам layout. Из чего состоит экран.
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          {
            pane = 1,
            icon = " ",
            title = "Recent Files",
            section = "recent_files",
            indent = 2,
            padding = 1,
            limit = 5,                  -- ровно 5 последних файлов, как договорились
          },
          { section = "startup" },      -- footer: ⚡ N plugins loaded in Xms
        },
      },

      -- ----------------------------------------------------------------------
      -- NOTIFIER
      -- ----------------------------------------------------------------------
      notifier = {
        enabled = true,
        timeout = 3000,                 -- через сколько мс уведомление само исчезнет
        style = "compact",              -- варианты: "compact" / "fancy" / "minimal"
        top_down = true,                -- новые уведомления сверху вниз
        date_format = "%R",
      },

      -- остальные модули snacks отключены — включим в нужных блоках
      bigfile = { enabled = false },
      indent  = { enabled = false },    -- у нас уже есть indent-blankline
      input   = { enabled = false },
      picker  = { enabled = false },    -- у нас будет telescope в Блоке 5
      quickfile = { enabled = false },
      scroll  = { enabled = false },
      statuscolumn = { enabled = false },
      words   = { enabled = false },
    },

    keys = {
      -- Принудительно открыть дашборд из любого места
      { "<leader>fd", function() Snacks.dashboard() end, desc = "Open dashboard" },
      -- История уведомлений
      { "<leader>fn", function() Snacks.notifier.show_history() end, desc = "Notification history" },
    },
  },
}