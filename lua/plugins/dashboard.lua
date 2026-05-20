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

        formats = {
          icon = function(item)
            if item.icon and item.icon:match("^%d+$") then
              return { item.icon, width = 2, hl = "SnacksDashboardKey" }
            end
            return { item.icon, width = 2 }
          end,
          -- Формат для отображения клавиш (букв и цифр) без скобок
          key = function(item)
            return { item.key, width = 2, hl = "SnacksDashboardKey" }
          end,
        },

        preset = {
          header = [[
███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗
████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║
██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║
██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚╝  ██║
╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],
          keys = {
            { icon = "", key = "n", desc = "New file", action = ":enew" },
            { icon = "", key = "r", desc = "Recent files", action = function() Snacks.dashboard.pick("oldfiles") end },
            {
              icon = "",
              key = "s",
              desc = "Restore session",
              action = function()
                require("persistence").load({ last = true })
              end,
            },
            { icon = "", key = "p", desc = "Projects", action = "<leader>fP" },
            { icon = "", key = "q", desc = "Quit", action = ":qa" },
          },
        },

        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1, indent = 2 },

                    {
            function()
              local pinned = require("util.pinned_projects").list()

              local items = {
                -- Заголовок "Projects" теперь с группой подсветки SnacksDashboardFooter, что делает его темнее
              { icon = " ", title = { { "Projects", hl = "MyDashboardProjectsHeader" } }, padding = 0, indent = 4 }
              }

              if #pinned == 0 then
                table.insert(items, {
                  desc = "(empty - press <leader>fa to pin current cwd)",
                  align = "center",
                  padding = 1,
                })
                return items
              end

              local LIMIT = 6
              local NAME_WIDTH = 18
              local shown = math.min(LIMIT, #pinned)

              for i = 1, shown do
                local entry = pinned[i]
                local path = entry.path
                local home = vim.fn.expand("~")

                if path == home then
                  path = "~"
                elseif vim.startswith(path, home .. "/") then
                  path = "~" .. path:sub(#home + 1)
                end

                local name = entry.name
                if #name > NAME_WIDTH - 1 then
                  name = name:sub(1, NAME_WIDTH - 2) .. "..."
                end

                local padded_name = name .. string.rep(" ", NAME_WIDTH - vim.str_utfindex(name, "utf-32"))
                table.insert(items, {
                  indent = 5,
                  -- Название проекта теперь красится цветом, который был у пути (SnacksDashboardFooter)
                  title = { padded_name, hl = "MyDashboardProjectName" },
                  -- Путь к проекту теперь красится цветом по умолчанию (можно указать свой, например, "SnacksDashboardDesc")
                  desc = { path, hl = "MyDashboardPath" },
                  -- Цифра остаётся справа, под буквами n r s q
                  key = tostring(i),
                  padding = i == shown and 1 or 0,
                })
              end

              return items
            end,
          },

          {
            section = "startup",
            text = function()
              local stats = require("lazy").stats()
              local ms = math.floor(stats.startuptime * 100 + 0.5) / 100
              return {
                { "⬡ ", hl = "SnacksDashboardSpecial" },
                { "Neovim loaded ", hl = "SnacksDashboardFooter" },
                { tostring(stats.loaded) .. "/" .. tostring(stats.count), hl = "DashboardFooterCount" },
                { " plugins in ", hl = "SnacksDashboardFooter" },
                { tostring(ms) .. "ms", hl = "DashboardFooterTime" },
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

      input = { enabled = true },
      quickfile = { enabled = true },
      scroll = { enabled = true },
      bigfile = { enabled = false },
      indent = { enabled = false },
      picker = { enabled = false },
      statuscolumn = { enabled = false },
      words = { enabled = false },
    },

    keys = {
      { "<leader>fd", function() Snacks.dashboard() end, desc = "Open dashboard" },
      { "<leader>fn", function() Snacks.notifier.show_history() end, desc = "Notification history" },
    },

    config = function(_, opts)
      vim.api.nvim_set_hl(0, "MyDashboardPath", { fg = "#727169", italic = true })
      vim.api.nvim_set_hl(0, "MyDashboardProjectsHeader", { fg = "#9C9CAB" })
      vim.api.nvim_set_hl(0, "MyDashboardProjectName", { fg = "#c4b28a", bold = true })
      require("snacks").setup(opts)

      local function cursor_blend(value)
        local hl = vim.api.nvim_get_hl(0, { name = "Cursor", create = true })
        hl.blend = value
        vim.api.nvim_set_hl(0, "Cursor", hl)
        vim.cmd("set guicursor+=a:Cursor/lCursor")
      end

      vim.api.nvim_create_autocmd("User", {
        pattern = "SnacksDashboardOpened",
        callback = function(event)
          cursor_blend(100)

          local pinned = require("util.pinned_projects").list()
          for i = 1, math.min(9, #pinned) do
            local entry = pinned[i]
            vim.keymap.set("n", tostring(i), function()
              local dash_buf = vim.api.nvim_get_current_buf()
              vim.cmd("bdelete " .. dash_buf)
              vim.cmd("cd " .. vim.fn.fnameescape(entry.path))
              vim.notify("Открыт проект: " .. entry.name, vim.log.levels.INFO)
            end, {
              buffer = event.buf,
              desc = "Open pinned project " .. i,
              nowait = true,
            })
          end
        end,
      })

      vim.api.nvim_create_autocmd("BufLeave", {
        callback = function()
          if vim.bo.filetype == "snacks_dashboard" then
            cursor_blend(0)
          end
        end,
      })
    end,
  },
}
