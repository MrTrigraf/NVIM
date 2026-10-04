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
                  -- action живёт в самом item'е: snacks пересоздаёт кнопки при каждой
                  -- перерисовке (ресайз), поэтому отдельный keymap терялся.
                  action = function(self)
                    -- pcall: в float-режиме snacks закрывает окно до action,
                    -- и буфер уже может быть удалён.
                    if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
                      pcall(vim.cmd, "bdelete " .. self.buf)
                    end
                    vim.cmd("cd " .. vim.fn.fnameescape(entry.path))
                    vim.notify("Открыт проект: " .. entry.name, vim.log.levels.INFO)
                  end,
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

      input = {
        enabled = true,
        win = {
          relative = "cursor",   -- позиционирование относительно курсора
          row      = -3,         -- на 3 строки выше курсора
          col      = 0,          -- по горизонтали — на месте курсора
        },
      },
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

      -- snacks не проверяет окно дашборда в WinResized -> "Invalid window id".
      -- Если окна нет, отдаём прошлый размер: deep_equal решит "не менялось".
      local dashboard_class = Snacks.dashboard.Dashboard
      local orig_size = dashboard_class.size
      function dashboard_class:size()
        if not (self.win and vim.api.nvim_win_is_valid(self.win)) then
          return self._size or { width = vim.o.columns, height = vim.o.lines }
        end
        return orig_size(self)
      end

      local function cursor_blend(value)
        local hl = vim.api.nvim_get_hl(0, { name = "Cursor", create = true })
        hl.blend = value
        vim.api.nvim_set_hl(0, "Cursor", hl)
        vim.cmd("set guicursor+=a:Cursor/lCursor")
      end

      -- Флаг, чтобы не включать анимацию повторно
      local smear_enabled = true

      -- Вход в дашборд – выключаем анимацию (один раз)
      vim.api.nvim_create_autocmd("User", {
        pattern = "SnacksDashboardOpened",
        callback = function()
          if smear_enabled then
            require("smear_cursor").toggle(false)
            smear_enabled = false
          end
          cursor_blend(100)
        end,
      })

      -- Выход из дашборда – включаем анимацию (один раз, и только если вышли именно из него)
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
          if not smear_enabled and vim.bo.filetype ~= "snacks_dashboard" then
            require("smear_cursor").toggle(true)
            smear_enabled = true
            cursor_blend(0)
          end
        end,
      })
    end,
  },
}
