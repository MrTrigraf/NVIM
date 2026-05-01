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
            { icon = "", key = "n", desc = "New file", action = ":enew" },
            { icon = "", key = "r", desc = "Recent files", action = function() Snacks.dashboard.pick("oldfiles") end },
            {
              icon = "", key = "s", desc = "Restore session",
              action = function()
                vim.notify("persistence.nvim ещё не подключён (Блок 14)", vim.log.levels.WARN)
              end,
            },
            { icon = "", key = "q", desc = "Quit", action = ":qa" },
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
          {
            section = "startup",
            text = function()
              local stats = require("lazy").stats()
              local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
              return {
                { "⚡ ",                                                   hl = "SnacksDashboardSpecial" },
                { "Neovim loaded ",                                        hl = "SnacksDashboardFooter"  },
                { tostring(stats.loaded) .. "/" .. tostring(stats.count), hl = "DashboardFooterCount"   },
                { " plugins in ",                                          hl = "SnacksDashboardFooter"  },
                { tostring(ms) .. "ms",                                    hl = "DashboardFooterTime"    },
              }
            end,
            align = "center",
          },
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

    -- ------------------------------------------------------------------------
    -- Единый цвет дашборда: Fuji (приглушённый светло-серый kanagawa).
    -- Акцент сохраняется только на буквах-клавишах (n, r, s, q, 1-5).
    -- ------------------------------------------------------------------------
    config = function(_, opts)
      require("snacks").setup(opts)

      local function set_dashboard_hl()
        local fuji         = "#DCD7BA"  -- основной текст kanagawa
        local fuji_dim     = "#727169"  -- приглушённый
        local sakura_pink  = "#D27E99"  -- розовый — для клавиш меню
        local crystal_blue = "#7E9CD8"  -- синий — для чисел плагинов
        local wave_aqua    = "#7AA89F"  -- бирюзовый — для времени
        local autumn_gold  = "#FFA066"  -- оранжевый — для иконки молнии

        vim.api.nvim_set_hl(0, "DashboardFooterCount", { fg = crystal_blue, bold = true })
        vim.api.nvim_set_hl(0, "DashboardFooterTime",  { fg = wave_aqua })

        -- Меню (n / r / s / q + описания)
        vim.api.nvim_set_hl(0, "SnacksDashboardHeader", { fg = fuji,        bold = true })
        vim.api.nvim_set_hl(0, "SnacksDashboardIcon",   { fg = fuji })
        vim.api.nvim_set_hl(0, "SnacksDashboardDesc",   { fg = fuji })
        vim.api.nvim_set_hl(0, "SnacksDashboardKey",    { fg = sakura_pink, bold = true })
        vim.api.nvim_set_hl(0, "SnacksDashboardTitle",  { fg = fuji_dim,    bold = true })
        vim.api.nvim_set_hl(0, "SnacksDashboardFile",   { fg = fuji })
        vim.api.nvim_set_hl(0, "SnacksDashboardDir",    { fg = fuji_dim })
        vim.api.nvim_set_hl(0, "SnacksDashboardFooter", { fg = fuji_dim,    italic = true })

        -- Footer-сегменты (используются в кастомном startup-text)
        vim.api.nvim_set_hl(0, "SnacksDashboardSpecial", { fg = autumn_gold })
      end

      set_dashboard_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_dashboard_hl })

      -- Скрыть курсор на дашборде
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "snacks_dashboard",
        callback = function()
          -- Прячем курсор полностью на дашборде
          vim.opt.guicursor:append("a:noCursor")
          vim.opt_local.cursorline = false
        end,
      })

      -- Восстановить курсор при выходе с дашборда
      -- Прячем курсор пока активен буфер дашборда
      vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
        callback = function(args)
          if vim.bo[args.buf].filetype == "snacks_dashboard" then
            vim.opt.guicursor:append("a:noCursor")
          else
            vim.opt.guicursor:remove("a:noCursor")
          end
        end,
      })
    end,
  },
}