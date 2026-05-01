-- ============================================================================
-- lua/plugins/dashboard.lua
-- snacks.nvim — модули dashboard и notifier.
-- Стартовый экран при запуске nvim без файла + красивые уведомления.
-- ============================================================================

return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      dashboard = {
        enabled = true,
        preset = {
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚╝ ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],
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
            limit = 5,
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
      notifier = {
        enabled = true,
        timeout = 3000,
        style = "compact",
        top_down = true,
        date_format = "%R",
      },
      input     = { enabled = true },
      quickfile = { enabled = true },
      scroll    = { enabled = true },
      bigfile      = { enabled = false },
      indent       = { enabled = false },
      picker       = { enabled = false },
      statuscolumn = { enabled = false },
      words        = { enabled = false },
    },
    keys = {
      { "<leader>fd", function() Snacks.dashboard() end, desc = "Open dashboard" },
      { "<leader>fn", function() Snacks.notifier.show_history() end, desc = "Notification history" },
    },
    config = function(_, opts)
      require("snacks").setup(opts)
    end,
  },
}